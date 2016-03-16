#!/bin/bash

# Import openstack environment
. ./openstack.env


#GLANCE_ID=$( openstack image list -f csv | grep JJN | awk -F, '{print $1}' | tr \" \  )
#
# UUID of the image to launch in from glance
GLANCE_ID=		# ID from glance of the image to launch
KEY=			# Name of Key to use for ssh
SECURITY_GROUP=		# ID of the security group to associate with instance
VOLUME_ID=		# ID of volume to attach to the instance
NAME=			# name to assign to the instance

function launch {
#
# UUID of the volume to attach to the instance
#
	until ( nova volume-list | grep $VOLUME_ID | grep -q available ) ; do
		echo "Waiting for $VOLUME_ID to become available"
		sleep 2
	done

jova boot \
	--flavor m1.small \
	--image ${GLANCE_ID} \
	--key-name ${KEY_NAME} \
	--security-groups ${SECURITY_GROUP} \
	--block-device id=${VOLUME_ID},device=vdb,source=volume,shutdown=preserve,dest=volume \
	${NAME}


openstack ip floating list -f csv | tail -1 | while IFS=, read IPID pool IPA fix inst ; do echo $id $ip ; done

ID=$( openstack server list --format csv | grep jjntest | awk -F, '{print $1}' |tr \" \ )


TMP=$(openstack ip floating list -f csv | tail -1 | tr \" \ ) 

IDIP=$( echo $TMP | cut -d, -f1  )
IPA=$( echo $TMP | cut -d, -f3  )

IPID=$( openstack ip floating list  -f csv | tail -1 | awk -F, '{print $1}' )

openstack ip floating add $IPA $ID

echo $ID >/tmp/launcher_image_id

echo allocated $IPA to instance $ID

echo waiting for instance to become available

until ( ping  -c 1 -q  $IPA >/dev/null 2>&1 ) ; do
	sleep 5
done
echo  launching a shell...

ssh -i ~/jjn-openstack-beta.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l ubuntu ${IPA}
}

function destroy {
	ID=$1
	echo destroying server $1
	openstack server delete $ID
	test -f /tmp/launcher_image_id && rm /tmp/launcher_image_id
}

if [ -f /tmp/launcher_image_id ] ; then
	image_id=$( cat /tmp/launcher_image_id )
	echo read $image_id from /tmp/launcher_image_id
fi

case $1 in
	launch)
		launch
		;;
	destroy)
		if [ -z $image_id ] ; then
			destroy $2
		else
			destroy $image_id
		fi
		;;
	*)
		echo "$0 launch|destroy <id>"
		;;
esac


#	--block-device id=8b8572c5-0524-4177-a684-bdf3e42d648d,source=volume,dest=local,bus=virtio,type=disk,shutdown=preserve \

#	--block-device-mapping vdb=8b8572c5-0524-4177-a684-bdf3e42d648d:::0 \

