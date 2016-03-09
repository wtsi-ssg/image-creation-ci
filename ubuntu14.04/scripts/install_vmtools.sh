#!/bin/bash

CD=/dev/cdrom
MNT=/mnt
VM_INSTALL_SCRIPT=vmware-install.pl
VM_INSTALL_OPTS="--default --force-install"

mount ${CD} ${MNT}

TARBALL=$( ls -1 ${MNT} | grep tar.gz )

cd /tmp


tar xfz ${MNT}/${TARBALL}

cd $( ls -1 | grep vmware-tools )

test -x ${VM_INSTALL_SCRIPT} && ./${VM_INSTALL_SCRIPT} ${VM_INSTALL_OPTS}

