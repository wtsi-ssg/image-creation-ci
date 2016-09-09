#!/bin/bash
#
# Script to clean up anything that is not required in the final image
# Initially created to remove proxy configuration from the vmware images

function cleanup_apt.conf {
	apt_conf=/etc/apt/apt.conf
	rm -f $apt_conf
}

function cleanup_yum {
        yum_conf=/etc/yum.conf
        sed -i $yum_conf -e 's/^proxy=.*$//'
}

function cleanup_home_ubuntu {
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

function cleanup_home_centos {
        home=/home/centos

        chown  -R centos:centos  $home

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

PLATFORM=$(python -mplatform| sed -e 's/.*ubuntu.*/ubuntu/i' -e 's/.*centos.*/centos/i')

case ${PACKER_BUILDER_TYPE} in
	vmware-iso)
                cleanup_hostfile
                cleanup_logrotate
                case ${PLATFORM} in 
                     centos) 
                        cleanup_home_centos
                        cleanup_yum
                        ;;
                     ubuntu)
		        cleanup_apt.conf
		        cleanup_home_ubuntu
                        ;;
                esac
		;;
	default)
		;;
esac
