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
	bash_history=$home/.bash_history
	rpmdb=$home/.rpmdb

	chown -R ubuntu:ubuntu $home || echo "chown failed in cleanup" && exit 1

	chmod 600 $bash_history && chmod 644 $rpmdb || echo "permissions failed in cleanup" && exit 1
}

function cleanup_hostfile {
	echo "172.0.0.1 localhost" > /etc/hosts
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
