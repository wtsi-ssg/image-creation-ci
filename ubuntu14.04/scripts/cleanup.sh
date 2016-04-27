#!/bin/bash
#
# Script to clean up anything that is not required in the final image
# Initially created to remove proxy configuration from the vmware images

function cleanup_vmare {
	apt_conf=/etc/apt/apt.conf
	proxy_string="^Aquire::http::Proxy"
	tmp_file=$(mktemp)
	if ( test -f ${apt_conf} && grep -iq $proxy_string ${apt_conf} ) ; then
		grep -iv ${proxy_string} ${apt_conf} >>${tmp_file}
		mv ${tmp_file} ${apt_conf}
	fi

}


case ${PACKER_BUILDER_TYPE} in
	vmware-iso)
		cleanup_vmare
		;;
	default)
		;;
esac
