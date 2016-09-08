#!/bin/bash
cd /tmp
curl ftp://ftp.sanger.ac.uk/pub/users/jb23/VMware-Tools-10.0.9-3917699.tar.gz -o - | tar xf -

tar xfz /tmp/VMware-Tools-10.0.9-3917699.tar.gz 
mount -o ro,loop /tmp/VMware-Tools-10.0.9-3917699/vmtools/linux.iso //mnt/run_upgrader.sh 

/mnt/run_upgrader.sh  -p "--default --force-install"

umount /mnt
