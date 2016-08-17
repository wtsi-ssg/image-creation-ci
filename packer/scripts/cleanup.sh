#!/bin/bash
#
# Script to clean up anything that is not required in the final image
# Initially created to remove proxy configuration from the vmware images

function cleanup_apt.conf {
	apt_conf=/etc/apt/apt.conf
	rm -f $apt_conf
}

function cleanup_home {
	home=/home/ubuntu
	
	chown  -R ubuntu:ubuntu  $home 

	if [ "$?" -ne "0" ]; then
		echo "chown failed"
		exit 1
	fi

	chmod -R go-rwx $home

	if [ "$?" -ne "0" ]; then
		echo "chmod failed"
		exit 1
	fi

}

function cleanup_hostfile {
	sed -e  '/.sanger.ac.uk/d' -i /etc/hosts
}

function cleanup_logrotate {
        echo "logrotate needs sorting"
}


case ${PACKER_BUILDER_TYPE} in
	vmware-iso)
		cleanup_apt.conf
		cleanup_home
		cleanup_hostfile
		cleanup_logrotate
		;;
	default)
		;;
esac
