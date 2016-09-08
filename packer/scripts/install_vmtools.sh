#!/bin/bash
cd /tmp
curl ftp://ftp.sanger.ac.uk/pub/users/jb23/VMware-Tools-10.0.9-3917699.tar.gz -o - | tar xzvf -

mount -o ro,loop /tmp/VMware-Tools-10.0.9-3917699/vmtools/linux.iso /mnt
cp -r  /mnt/* /tmp

/tmp/run_upgrader.sh  # -p "--default --force-install"

umount /mnt
