#!/usr/bin/env python

from __future__ import print_function
import time
import sys
import string
import random
import subprocess
import os
from os import environ
import argparse
import glanceclient.v2.client as glclient
import novaclient.client as nvclient
import keystoneclient.v2_0.client as ksclient

def authenticate():
    """
    This function returns authenticated nova and glance objects
    """
    try:
        keystone = ksclient.Client(auth_url=environ.get('OS_AUTH_URL'),
                                   username=environ.get('OS_USERNAME'),
                                   password=environ.get('OS_PASSWORD'),
                                   tenant_name=environ.get('OS_TENANT_NAME'),
                                   region_name=environ.get('OS_REGION_NAME'))
        nova = nvclient.Client("2",
                               auth_url=environ.get('OS_AUTH_URL'),
                               username=environ.get('OS_USERNAME'),
                               api_key=environ.get('OS_PASSWORD'),
                               project_id=environ.get('OS_TENANT_NAME'),
                               region_name=environ.get('OS_REGION_NAME'))
    except:
        print('Authentication with openstack failed, please check that the environment variables are set correctly.')
        sys.exit(1)

    glance_endpoint = keystone.service_catalog.url_for(service_type='image')
    glance = glclient.Client(glance_endpoint, token=keystone.auth_token)

    return nova, glance


def download(input_name, output_location, date_time):
    '''
    shrinks the image and replaces the standard image
    '''

    nova, glance = authenticate()

    try:
        new = nova.images.find(name=input_name)
    except:
        print("failed to find image " + input_name + "or there are multiple image with that name")
        sys.exit(1)

    if date_time:
        file_name_ending = '_' + time.strftime("%Y%m%d%H%M%S") + ".qcow"
    else:
        file_name_ending = ".qcow"


    downloaded_file = output_location + file_name_ending
    print("downloaded file is called: " + downloaded_file)

    try:
        subprocess.check_call(['glance', 'image-download', '--progress', '--file', downloaded_file, new.id])
    except subprocess.CalledProcessError as e:
        print(e.output)
        sys.exit(1)

    try:
        images = glance.images.list()
    except:
        print("Could not get a list of images")
        sys.exit(1)

    for image in images:
        if 'private' not in image['visibility']:
            continue
        if input_name == image['name']:
            try:
                subprocess.check_call(['openstack', 'image', 'delete', image['id']])
                print("successfully deleted " + str(image['name']))
	    except subprocess.CalledProcessError as e:
                print(e.output)
                print('The original image could not be destroyed, please run this manually')

def parsing():
    parser = argparse.ArgumentParser(description="This script cleans up the openstack images after testing and store them locally")
    parser.add_argument(
        'input', help='The name of the file in openstack')
    parser.add_argument(
        'output', help='The output name')
    parser.add_argument(
        '-f', '--file_path', dest='file_path', default='/warehouse/isg_warehouse/SciaaS_images/openstack/',
        help='The output location')
    parser.add_argument(
        '-dt', '--datetime', dest='date_time', action='store_true', help='Store the date and time in the name of the file')

    return parser.parse_args()


def main():
    args = parsing()
    download(args.input, args.file_path + args.output, args.date_time)

if __name__ == "__main__":
    main()
