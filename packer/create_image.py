#!/usr/bin/env python

from __future__ import print_function
import argparse
import random
import string
from os import environ
import os
import subprocess
import sys
import glanceclient.v2.client as glclient
import novaclient.client as nvclient
import keystoneclient.v2_0.client as ksclient

debug_var = "None"
parser = argparse.ArgumentParser(description="This script allows one to build images on vmware, openstack and/or virtualbox")

parser.add_argument(
    'mode', choices=['validate', 'build'],
    help='''\nSet whether to validate the template or whether to build images'''
    )
parser.add_argument(
    '-tf', '--tem_file', default='template.json',
    help='''\nThis is used to set the template file for the image''')
parser.add_argument(
    '-vf', '--var_file', default='variables.json',
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
    '-s', '--store', dest='store', default="/warehouse/isg_warehouse/gitlab-storage/",
    help='''\nThis is used to store the output of the script in a specified area''')
parser.add_argument(
    '-l', '--packer-location', dest='packer',
    help='''\nThis is used to specify the location of packer.''')
parser.add_argument(
    '-d', '--debug', dest='debug', default="None",
    help='''\nThis is used to output debug messages in this wrapper''')



def process_args(args):
    """
    Prepares the environment and runs checks depending upon the platform
    """
    global debug_var
    if 'all' in args.platform:
        args.platform = ['virtualbox', 'openstack', 'vmware-iso']
    if 'openstack' in args.platform:
        #This line must come before packer is called as the packer template relies upon it!
        environ['IMAGE_NAME'] = ''.join(random.choice(string.lowercase) for i in range(20))
        if (args.os_name is None) and ('build' in args.mode):
            print("To use openstack you must specify the output file name")
            sys.exit(1)
    debug_var = args.debug
    debug("Local debug mode on");
    return args

def debug(string):
    """
    Output a debug string to the stdout
    """
    if debug_var == "local" :
        print (string);
        sys.stdout.flush()


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
        print('Sourcing openstack environment variabels failed, please check that the environment variables are set correctly.')
        sys.exit(2)

    glance_endpoint = keystone.service_catalog.url_for(service_type='image')
    glance = glclient.Client(glance_endpoint, token=keystone.auth_token)

    return nova, glance

def openstack_cleanup(file_path, os_name):
    """
    This function is only run if openstack is one of the builders.
    If the image is to be stored then the image will be shrunk and the original image deleted,
    if there were any other images in openstack of the same type they will be removed.
    """
    nova, glance = authenticate()

    large_image = nova.images.find(name=environ.get('IMAGE_NAME'))

    downloaded_file = file_path + ''.join(random.choice(string.lowercase) for i in range(20)) + ".raw"
    local_qcow = file_path + ''.join(random.choice(string.lowercase) for i in range(20)) + ".qcow"


    try:
        subprocess.check_call(['glance', 'image-download', '--progress', '--file', downloaded_file, large_image.id])
    except subprocess.CalledProcessError as e:
        print(e.output)
        sys.stdout.flush()
        try:
            debug(" ".join(['openstack', 'image', 'delete', large_image]))
            subprocess.check_call(['openstack', 'image', 'delete', large_image])
        except subprocess.CalledProcessError as f:
            print(f.output)
            print("Failed to remove the uncompressed image from openstack, you will need to clean this up manually.")
        sys.exit(3)

    if os.stat(downloaded_file).st_size == 0:
        print(f.output)
        print("Downloaded file ({hostname}:{path}) empty".format(path=downloaded_file,hostname=os.uname()[1]))
        sys.exit(4)
    debug("Download file ({hostname}:{path}) size={size}".format(path=downloaded_file,hostname=os.uname()[1],size=os.stat(downloaded_file).st_size))

    try:
        subprocess.check_call(['qemu-img', 'convert', '-f', 'raw', '-O', 'qcow2', downloaded_file, local_qcow])
    except subprocess.CalledProcessError as e:
        print(e.output)
        sys.exit(5)

    os.remove(downloaded_file)
    debug("Converted file ({hostname}:{path}) size={size}".format(path=local_qcow,hostname=os.uname()[1],size=os.stat(local_qcow).st_size))


    try:
        debug(" ".join(['glance', 'image-create', '--file', local_qcow, '--disk-format', 'qcow2', '--container-format', 'bare', '--progress', '--name', os_name]))
        subprocess.check_call(['glance', 'image-create', '--file', local_qcow, '--disk-format', 'qcow2', '--container-format', 'bare', '--progress', '--name', os_name])
        print(os_name)
        sys.stdout.flush()

        final_image = nova.images.find(name=os_name)

        environ['OS_IMAGE_ID'] = final_image.id

        print("Image created and compressed with id: " + final_image.id)
        sys.stdout.flush()

    except subprocess.CalledProcessError as e:
        print(e.output)
        sys.stdout.flush()
        sys.exit(6)

    os.remove(local_qcow)

    try:
        subprocess.check_call(['openstack', 'image', 'delete', large_image.id])
    except subprocess.CalledProcessError as e:
        print(e.output)
        print('The large image could not be destroyed, please run this manually')
        sys.exit(7)

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
        if args.mode == 'build':
            debug(" ".join([packer_bin, args.mode, '-debug', '-only='+platform, '-var-file='+ args.var_file, args.tem_file]))
            subprocess.check_call([packer_bin, args.mode, '-debug', '-only='+platform, '-var-file='+ args.var_file, args.tem_file])
        else:
            debug(" ".join([packer_bin, args.mode, '-only='+platform, '-var-file='+ args.var_file, args.tem_file]))
            subprocess.check_call([packer_bin, args.mode, '-only='+platform, '-var-file='+ args.var_file, args.tem_file])
    except subprocess.CalledProcessError as f:
        print(f.output)
        sys.exit(8)


    if 'validate' not in args.mode and ('openstack' in args.platform):
        openstack_cleanup(args.store, args.os_name)

def main():
    args=parser.parse_args()
    run_packer(process_args(args))

if __name__ == "__main__":
    main()
