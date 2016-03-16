#!/bin/bash

function usage {
	echo "$0"
	echo ""
	echo "Usage:- "
	echo "        $0 <hostname> <public-key-file> <instance-id>"
	echo ""
	echo "Creates a ISO9660 format disk image for use with cloud-init on vmware or virtualbox"
	echo ""
	echo "  hostname       - name to give to the complete instance" 
	echo "  public-keyfile - filename of an SSH public key"
	echo "                   (if not specified will look for \$HOME/.ssh/id_rsa.pub)"
	echo "  instance-id    - unique identifier for the instance"
}

function check_ssh_key {
	if [ -z "$1" -o ! -f "$1" ] ; then
		return 1
	fi
	if ( ! ssh-keygen -l -f $1 ) ; then
		return 1
	fi
	return 0
}


if [ -z $1 ] ; then
	read -p "Hostname: " hostname
else
	hostname=$1
fi

t_key=$2
key=""
until ( check_ssh_key $key ) ; do 
	if [ ! -z "$t_key" ] ; then
		key=$t_key
		t_key=""
	elif [ -f $HOME/.ssh/id_rsa.pub ] ; then
		key=$HOME/.ssh/id_rsa.pub
	else
		read -p "SSH Key: " key
	fi
done

if [ ! -z "$3" ] ; then
	instance=$3
else
	instance=$( uuid )
fi

echo Got: $hostname $key $instance

mkdir -p /tmp/cloud-init/${instance}

cd /tmp/cloud-init/${instance}

cat >meta-data <<End_of_meta_data
dsmode: local
instance-id: ${instance}
local-hostname: ${hostname}

End_of_meta_data


cat >user-data <<End_of_user_data
#cloud-config

ssh_authorized_keys:
   - $( cat ${key} )
End_of_user_data

genisoimage -output /tmp/${hostname}.iso -input-charset iso8859-1 -volid ${hostname} -joliet -rock user-data meta-data

echo "ISO image created as /tmp/${hostname}.iso"


