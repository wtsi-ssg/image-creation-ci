#!/bin/bash
#
# install_cloud-init.sh
#  Installs the cloud init package after building
#

function cloud-init {
	CLOUD_FILE=$1; DEVICE=$2

        PLATFORM=$(python -mplatform)

        if [ "$( echo "$PLATFORM" | sed -e 's/.*ubuntu.*/ubuntu/i')" = "ubuntu" ] ; then
          apt-get -y install cloud-init patch
          export cc_disk_setup=/usr/lib/python2.7/dist-packages/cloudinit/config/cc_disk_setup.py
          export cc_disk_setup_md5=08b45fa565f2cf3fdf31760ae93a6962
          cat <<-EOF > /tmp/patch
		--- cc_disk_setup.py    2016-03-14 15:24:37.179403160 +0000
		+++ cc_disk_setup.py.new        2016-03-14 15:24:48.411402930 +0000
		@@ -108,7 +108,6 @@
		 
		                 if origname is None:
		                         continue
		-
		                 (dev, part) = util.expand_dotted_devname(origname)
		 
		                 tformed = tformer(dev)
		@@ -121,7 +120,7 @@
		 
		                 if part and 'partition' in definition:
		                         definition['_partition'] = definition['partition']
		-        definition['partition'] = part
		+            definition['partition'] = part
		 
		 
		 def value_splitter(values, start=None):
		@@ -305,7 +304,7 @@

		         # If the child count is higher 1, then there are child nodes
		         # such as partition or device mapper nodes
		         use_count = [x for x in enumerate_disk(device)]
		-    if len(use_count.splitlines()) > 1:
		+    if len(use_count) > 1:
		                 return True
		 
		         # If we see a file system, then its used

		EOF
        fi

        if [ "$( echo "$PLATFORM" | sed -e 's/.*centos.*/centos/i')" = "centos" ] ; then
          yum install -y cloud-init patch
          export cc_disk_setup=/usr/lib/python2.7/site-packages/cloudinit/config/cc_disk_setup.py
          export cc_disk_setup_md5=03bab30bd86753459af74127a084dd55
          cat <<-EOF > /tmp/patch
		--- /usr/lib/python2.7/site-packages/cloudinit/config/cc_disk_setup.py	2014-04-01 18:26:07.000000000 +0000
		+++ /tmp/cc_disk_setup.py	2016-08-22 16:45:17.215872238 +0000
		@@ -120,7 +120,7 @@
		
		         if part and 'partition' in definition:
		             definition['_partition'] = definition['partition']
		-        definition['partition'] = part
		+        definition['partition'] = part
		
		
		 def value_splitter(values, start=None):
		@@ -304,7 +304,7 @@
		     # If the child count is higher 1, then there are child nodes
		     # such as partition or device mapper nodes
		     use_count = [x for x in enumerate_disk(device)]
		-    if len(use_count.splitlines()) > 1:
		+    if len(use_count) > 1:
		         return True
		 
		     # If we see a file system, then its used
		EOF
	   cat <<-EOF > /tmp/cloud_patch
		--- /etc/cloud/cloud.cfg	2016-08-25 10:23:29.039875922 +0000
		+++ /tmp/cloud.cfg	2016-08-25 10:29:36.125698275 +0000
		@@ -25,6 +25,7 @@
		  - ssh
		 
		 cloud_config_modules:
		+ - disk_setup
		  - mounts
		  - locale
		  - set-passwords
		EOF
          patch -p1 /etc/cloud/cloud.cfg < /tmp/cloud_patch   
        fi

	echo "Patching cc_disk_setup.py"

	chksum=$( md5sum $cc_disk_setup | cut -f1 -d\   )

	echo " >${cc_disk_setup_md5}<  >${chksum}< "

	if [ ${cc_disk_setup_md5} = "${chksum}" ] ; then
		echo "Applying patch"
		patch -p1 $cc_disk_setup < /tmp/patch
	else
		echo "Version of ${cc_disk_setup} doesn't match expected - not patching"
	fi

	echo "Installing disk configuration for cloud.cfg"

	cat >> "${CLOUD_FILE}" <<-EOF
	disk_setup:

		${DEVICE}:
		   table_type: 'mbr'
		   layout: True
		   overwrite: False


	fs_setup:
		- label: Data1
		  filesystem: 'ext4'
		  device: '${DEVICE}'
		  partition: '1'
		  overwrite: false

	mounts:
		- [ ${DEVICE}, /data1, auto, "defaults" ]


	EOF
}


function main {
	echo "Installing cloud-init"
	case ${PACKER_BUILDER_TYPE} in
		null)
			CLOUD_FILE=/tmp/cloud.cfg
			DEVICE=/dev/null
		;;
		openstack)
			CLOUD_FILE=/etc/cloud/cloud.cfg
			DEVICE=/dev/vdb
		;;
		vmware-iso)
			echo "skip cloud-init for vmware"
			exit 0
		;;
		virtualbox-iso)
			CLOUD_FILE=/etc/cloud/cloud.cfg
			DEVICE=/dev/sdb
		;;
		*)
			echo "Unknown builder!"
			exit 1
		;;
	esac

	cloud-init ${CLOUD_FILE} ${DEVICE}
}

main
