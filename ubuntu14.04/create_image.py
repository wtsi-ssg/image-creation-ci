#!/usr/bin/env python

from __future__ import print_function
import argparse
import getpass
import random
import string
from os import environ
import os
import subprocess
import sys
import shlex
import time
import glanceclient.v2.client as glclient
import novaclient.client as nvclient
import keystoneclient.v2_0.client as ksclient

"""
Parses the command line arguments
"""
parser = argparse.ArgumentParser(description="This script allows one to build images on vmware, openstack and/or virtualbox")
requiredNamed = parser.add_argument_group('required arguments')

requiredNamed.add_argument(
    'mode', choices=['validate', 'build'],
    help='''\nSet whether to validate the template or whether to build images'''
    )
requiredNamed.add_argument(
    'tem_file',
    help='''\nThis is used to set the template file for the image''')
requiredNamed.add_argument(
    'var_file',
    help='''\nThis is used to set the final name of the image, if not set the image name will be random.''')

parser.add_argument(
    '-p', '--platform', dest='platform', default=['all'], nargs='*',
    choices=['all', 'virtualbox', 'openstack', 'vmware-iso'],
    help='''\nSet the platform to build the images on'''
    )
parser.add_argument(
    '-o', '--openstack-name', dest='os_name',
    help='''\nThis is used to set the final name of the image, if not set the image name will be random.''')
parser.add_argument(
    '-vf', '--var-file', dest='var_file', default='variables.json',
    help='''\nThis is used to set the final name of the image, if not set the image name will be random.''')
parser.add_argument(
    '-s', '--store', dest='store', action='store_true',
    help='''\nThis is used to store the images after creation. If this is not set then the images will be destroyed after the CI has run.''')
parser.add_argument(
    '-l', '--packer-location', dest='packer',
    help='''\nThis is used to specify the location of packer.''')

def process_args(args):
    """
    Prepares the environment and runs checks depending upon the platform
    """
    if 'all' in args.platform:
        args.platform = ['virtualbox', 'openstack', 'vmware-iso']

    if 'openstack' in args.platform:
        #This line must come before packer is called as the packer template relies upon it!
        environ['IMAGE_NAME'] = ''.join(random.choice(string.lowercase) for i in range(20))
        if (args.os_name is None) and ('build' in args.mode):
            print("To use openstack you must specify the output file name")
            sys.exit(1)

        nova, glance = authenticate()

        count = 0
        for image in glance.images.list():
            if 'private' not in image['visibility']:
                continue
            if str(args.os_name) in image['name']:
                count += 1
                if count > 1:
                    print("There are multiple versions of this image in the openstack repository, please clean these up before continuing")
                    sys.exit(1)

    return args

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

def openstack_cleanup(store, os_name):
    """
    This function is only run if openstack is one of the builders.
    If the image is to be stored then the image will be shrunk and the original image deleted,
    if there were any other images in openstack of the same type they will be removed.
    """
    nova, glance = authenticate()

    large_image = nova.images.find(name=environ.get('IMAGE_NAME'))
    downloaded_file = ''.join(random.choice(string.lowercase) for i in range(20)) + ".raw"

    try:
        subprocess.check_call(['glance', 'image-download', '--progress', '--file', downloaded_file, large_image.id])
    except subprocess.CalledProcessError as e:
        print(e.output)
        try:
            subprocess.check_call(['openstack', 'image', 'delete', large_image])
        except subprocess.CalledProcessError as f:
            print(f.output)
            print("Failed to remove the uncompressed image from openstack, you will need to clean this up manually.")
            sys.exit(1)

    local_qcow = ''.join(random.choice(string.lowercase) for i in range(20)) + ".qcow"
    subprocess.check_call(['qemu-img', 'convert', '-f', 'raw', '-O', 'qcow2', downloaded_file, local_qcow])

    os.remove(downloaded_file)

    try:
        subprocess.check_call(['glance', 'image-create', '--file', local_qcow, '--disk-format', 'qcow2', '--container-format', 'bare', '--progress', '--name', os_name])
        print(os_name)
        with open('image_name', 'w+') as store_name:
            store_name.write(os_name)

        final_image = nova.images.find(name=os_name)

        environ['OS_IMAGE_ID'] = final_image.id
        print("Image created and compressed with id: " + final_image.id)
    except subprocess.CalledProcessError as e:
        print(e.output)

    os.remove(local_qcow)

    try:
        subprocess.check_call(['openstack', 'image', 'delete', large_image.id])
    except subprocess.CalledProcessError as e:
        print(e.output)
        print('The large image could not be destroyed, please run this manually')

def run_packer(args):
    """
    This function creates the string that calls packer that will be passed to subprocess.
    """

    if args.packer is not None:
        packer_bin = args.packer
    elif environ.get('PACKER_BIN') is not None:
        packer_bin = environ.get('PACKER_BIN')
    else:
        process = subprocess.Popen(['which', 'packer'], stdout=subprocess.PIPE)
        output = process.communicate()[0]
        if len(output.strip()) > 0:
            packer_bin = output.strip()
        else:
            print("packer location was not specified, trying /software")
            packer_bin = '/software/packer-0.9.0/bin/packer'

    platform = str()
    for element in args.platform:
        platform += element +','

    try:
        subprocess.check_call([packer_bin, args.mode, '-only='+platform, '-var-file='+ args.var_file, args.tem_file])
    except subprocess.CalledProcessError as f:
        print(f.output)
        sys.exit(1)


    if 'validate' not in args.mode and ('openstack' in args.platform):
            openstack_cleanup(args.store, args.os_name)

def main():
    run_packer(process_args(parser.parse_args()))

if __name__ == "__main__":
    main()
