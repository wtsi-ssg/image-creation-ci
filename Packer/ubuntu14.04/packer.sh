#!/bin/bash

# Set up the openstack environment - required even if not building the openstack images




export OS_NO_CACHE=True
export COMPUTE_API_VERSION=1.1
export no_proxy=,172.31.4.18
export OS_CLOUDNAME=overcloud
export OS_AUTH_URL=http://172.31.4.18:5000/v2.0/
export NOVA_VERSION=1.1

# Change these

export OS_USERNAME=a_username
export OS_PASSWORD=a_password
export OS_TENANT_NAME=a_tenant

# VMWare environment
export VMWARE_BUILD_HOST=wtgc-vmbd-01.internal.sanger.ac.uk
#

# Packer debug

PACKER_LOG=1
PACKER_LOG_PATH=${PWD}/packer_log.$$

PACKER_BIN="/home/jjn/bin/packer"

function join { local IFS="$1"; shift; echo "$*"; }



echo "Password require to connect to the machine ${VMWARE_BUILD_HOST}"

read -s  -p Password: vm_pwd

echo ""
builders=""

for build in $@ ; do
	case "${build}" in 
		openstack)
			echo "Openstack"
			builders="${builders} openstack"
			openstack=1
		;;
		vmware)
			echo "VMware"
			builders="${builders} vmware-iso"
			vmware=1
		;;
		virtualbox)
			echo "VirtualBox"
			builders="${builders} virtualbox-iso"
			vbox=1
		;;
		all)
			echo "Building all architectures"
			builders="vmware-iso virtualbox-iso openstack"
			vbox=1	
			openstack=1
			vmware=1
			;;
	esac
done

if [ "x${builders}"  == "x" ] ; then
	echo "Need at least one of openstack|vmware|virtualbox|all to be able to build something"
	exit
fi

BUILD=$( join , ${builders} )

$PACKER_BIN build template.json --only=$BUILD

