#!/usr/bin/env python

from __future__ import print_function
import sys
import subprocess
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


def remove():
    nova, glance = authenticate()

    image_name = environ.get('IMAGE_NAME')
    for image in glance.images.list():
        if 'private' not in image['visibility']:
            continue

        if image['name'] == image_name:
            subprocess.check_call(['openstack', 'image', 'delete', image['id']])

def main():
    remove()

main()
