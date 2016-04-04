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
import packer

def argument_parser():
    """
    Parses the command line arguments
    """
    parser = argparse.ArgumentParser(description="MUST FILL IN LATER")
    parser.add_argument(
        'mode', choices=['validate', 'build'],
        help='''Set whether to validate the template or whether to build images'''
        )
    parser.add_argument(
        '-p', '--platform', dest='platform', default=['all'], nargs='*',
        choices=['all', 'virtualbox', 'openstack', 'vmware-iso']
        )
    parser.add_argument(
        '-o', '--openstack-name', dest='os_name',
        help='''This is used to set the final name of the image, if not set the image name will be random.''')
    parser.add_argument(
        '-f', '--var-file', dest='var_file', default='variables.json',
        help='''This is used to set the final name of the image, if not set the image name will be random.''')
    parser.add_argument(
        '-s', '--store', dest='store', action='store_true',
        help='''This is used to store the images after creation. If this is not set then the images will be destroyed after the CI has run.''')

    return parser.parse_args()

def process_args(args):
    """
    Prepares the environment and runs checks depending upon the platform
    """
    if 'all' in args.platform:
        args.platform = ['virtualbox', 'openstack', 'vmware-iso']

    if 'openstack' in args.platform:
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

    os_name_date = os_name + time.strftime("%Y%m%d%H%M%S")

    if store:
        try:
            downloaded_file = ''.join(random.choice(string.lowercase) for i in range(20)) + ".raw"
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
            subprocess.check_call(['glance', 'image-create', '--file', local_qcow, '--disk-format', 'qcow2', '--container-format', 'bare', '--progress', '--name', os_name_date])

            final_image = nova.images.find(name=os_name_date)

            environ['OS_IMAGE_ID'] = final_image.id
            print("Image created and compressed with id: " + final_image.id)
        except subprocess.CalledProcessError as e:
            print(e.output)
            os.remove(local_qcow)

        for image in glance.images.list():
            if 'private' not in image['visibility']:
                continue
            if str(os_name) not in image['name']:
                continue
            if str(os_name_date) not in image['name']:
                try:
                    subprocess.check_call(['openstack', 'image', 'delete', image['id']])
                except subprocess.CalledProcessError as e:
                    print(e.output)
                    print('The original image could not be destroyed, please run this manually')

    try:
        subprocess.check_call(['openstack', 'image', 'delete', large_image.id])
    except subprocess.CalledProcessError as e:
        print(e.output)
        print('The large image could not be destroyed, please run this manually')

def run_packer(args):
    """
    This function creates the string that calls packer that will be passed to subprocess.
    """

    #This line must come before packer is called as the packer template relies upon it
    environ['IMAGE_NAME'] = ''.join(random.choice(string.lowercase) for i in range(20))

    packer_bin = environ.get('PACKER_BIN')
    if packer_bin is None:
        packer_bin = '/software/packer-0.9.0/bin/packer'

    p = packer.Packer('template.json', exc=[], only=args.platform, vars=dict(), var_file=args.var_file, exec_path=packer_bin)

    if 'validate' in args.mode:
        p.validate(syntax_only=False)
        print('Template validated successfully.')
    else:
        p.build(parallel=True, debug=False, force=False)
        if ('openstack' in args.platform):
            openstack_cleanup(args.store, args.os_name)

def main():
    run_packer(process_args(argument_parser()))

if __name__ == "__main__":
    main()