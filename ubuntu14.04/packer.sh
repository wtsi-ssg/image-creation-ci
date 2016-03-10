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

export PACKER_LOG=1
export PACKER_LOG_PATH=/tmp/packer_log.$$

PACKER_BIN="/home/jjn/bin/packer"

function join { local IFS="$1"; shift; echo "$*"; }
function usage {
	echo "usage:-"
	echo ""
	echo "$0 build|validate vmware|virtualbox|openstack|all"
	echo ""
	echo "Build images for various platforms or all"
	echo ""
	echo "Validate will run the validation of the template with the appriate environment"
	echo "configured"
	echo ""
	echo "If a VMWARE build is requested a password for the ESXi server will be prompted"
	echo "for if it is not set in the environment variable VMWARE_PASSWORD"

}

builders=""

ACTION=$1

case ${ACTION} in
	validate)
		echo "** VALIDATING TEMPLATE ONLY"
		;;
	build)
		echo "Building images"
		;;
	*)
		echo "Bad argument ${ACTION}"
		usage
		exit
		;;
	esac
		

shift

vmware=0
vbox=0
openstack=0
null=0

for build in $@ ; do
	case "${build}" in 
		openstack)
			echo "Openstack"
			builders+="openstack "
			openstack=1
		;;
		vmware)
			echo "VMware"
			builders+="vmware-iso "
			vmware=1
		;;
		virtualbox)
			echo "VirtualBox"
			builders+="virtualbox-iso "
			vbox=1
		;;
		null)
			echo "Null Builder - all other builders invalidated but running configuration script"
			builders="null "
			null=1
			vmware=1
			vbox=1
			openstack=1
			break
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

variables=""

if [ ${vmware} -eq 1 ] ; then
	if [ "x${VMWARE_PASSWORD}" == "x" ]; then
		echo "Password require to connect to the machine ${VMWARE_BUILD_HOST}"

		read -s  -p Password: VMWARE_PASSWORD
	fi	
	echo ""
	variables+="-var vm_pass='${VMWARE_PASSWORD}' "
fi

echo "Logging to ${PACKER_LOG_PATH}"

BUILD=$( join , ${builders} )

if [ $ACTION == 'validate' -o $null == 1 ] ; then
#	echo $VMWARE_PASSWORD
	echo $PACKER_BIN $ACTION -only=$BUILD $variables template.json
fi

$PACKER_BIN $ACTION -only=$BUILD $variables template.json

