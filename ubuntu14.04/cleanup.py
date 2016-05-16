#!/usr/bin/env python

from __future__ import print_function
import time
import sys
import string
import random
import subprocess
import os
from os import environ
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


def shrink():
    '''
    shrinks the image and replaces the standard image
    '''

    nova, glance = authenticate()

    try:
        name = environ.get('IMAGE_NAME')
    except:
        print('IMAGE_NAME environment variable not set')
        sys.exit(1)
    new = nova.images.find(name=name)


    try:
        downloaded_file = "/warehouse/isg_warehouse/gitlab-storage/" + ''.join(random.choice(string.lowercase) for i in range(20)) + ".qcow"
        subprocess.check_call(['glance', 'image-download', '--progress', '--file', downloaded_file, new.id])
    except subprocess.CalledProcessError as e:
        print(e.output)

    try:

        name_date = name + '_' + time.strftime("%Y%m%d%H%M%S")

        subprocess.check_call(['glance', 'image-create', '--file', downloaded_file, '--disk-format', 'qcow2', '--container-format', 'bare', '--progress', '--name', name_date])
        final_image = nova.images.find(name=name_date)

        print("Image created and compressed with id: " + final_image.id)

        for image in glance.images.list():
            if 'private' not in image['visibility']:
                continue
            if str(name) not in image['name']:
                continue
            if str(name_date) not in image['name']:
                try:
                    subprocess.check_call(['openstack', 'image', 'delete', image['id']])
                except subprocess.CalledProcessError as e:
                    print(e.output)
                    print('The original image could not be destroyed, please run this manually')

    except subprocess.CalledProcessError as e:
        print(e.output)

    os.remove(downloaded_file)


def main():
    shrink()

if __name__ == "__main__":
    main()
