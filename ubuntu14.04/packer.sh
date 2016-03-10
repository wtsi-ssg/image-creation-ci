#!/bin/bash

# Set up the openstack environment - required even if not building the openstack images




export OS_NO_CACHE=True
export COMPUTE_API_VERSION=1.1
export no_proxy=,172.31.4.18
export OS_CLOUDNAME=overcloud
export OS_AUTH_URL=http://172.31.4.18:5000/v2.0/
export NOVA_VERSION=1.1

# Change these

. ./openstack.sh

#export OS_USERNAME=a_username
#export OS_PASSWORD=a_password
#export OS_TENANT_NAME=a_tenant

# VMWare environment
export VMWARE_BUILD_HOST=wtgc-vmbd-01.internal.sanger.ac.uk
#

# Image naming conventing

export IMAGE_NAME="ubuntu_14_04_4_WTSI_"

IMAGE_NAME+=$( date +%Y%m%d%H%M%s )

# Packer debug

export PACKER_LOG=1
export PACKER_LOG_PATH=/tmp/packer_log.$$

# Paths to necessary binaries

PACKER_BIN="/home/jjn/bin/packer"
GLANCE=/usr/bin/glance
QEMU_IMG=/usr/bin/qemu-img

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

function openstackpp {
	echo "Openstack post-processing"
	if [ ! -x $GLANCE ] ; then
		echo "Glance not available - cannot continue"
		return
	fi

	if [ ! -x $QEMU_IMG ] ; then
		echo "qemu-img not available - cannot continue"
		return
	fi

	LOG=$0
	if [ ! -f $LOG ] ; then
		echo "No logfile available - cannot continue"
		return
	fi
	IMAGEID=$( grep "openstack,artifact,0,id" $LOG | awk -F, '{print $NF}' )
	if [ -z "${IMAGEID}" ]; then
		echo "IMAGE not generated"
		return
	fi
	echo Downloading raw image
	PACKER_RAW=/tmp/${IMAGEID}.raw
	PACKER_QCOW=/tmp/${IMAGEID}.qcow2
	if ! $GLANCE image-download --progress --file ${PACKER_RAW} ${IMAGEID} ; then
	  echo Error downloading image
	  return
	fi
	echo Converting to QCOW2
	if ! $QEMU_IMG convert -f raw -O qcow2 ${PACKER_RAW} ${PACKER_QCOW} ; then
	  echo Error converting image
	  return
	fi
	if ! $GLANCE image-create --file ${PACKER_QCOW} --disk-format qcow2 --container-format bare  --progress  --name "${IMAGE_NAME}" ; then
	  echo Error uploading image
	  exit 4
	fi
	echo cleaning local file system
	rm ${PACKER_RAW} ${PACKER_QCOW}
	echo cleaning glance
	$GLANCE image-delete ${IMAGEID}
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

$PACKER_BIN -machine-readable $ACTION -only=$BUILD $variables template.json | tee ${PACKER_LOG_PATH}.o

if [ $openstack -eq 1 ] ; then
	openstackpp(${PACKER_LOG}.o)
fi



