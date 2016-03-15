#!/bin/bash -eux

apt-get update
apt-get -y upgrade
apt-get -y dist-upgrade
apt-get -y autoclean

# ensure the correct kernel headers are installed
apt-get -y install linux-headers-$(uname -r)

apt-get -y clean

#we have to reboot here, so the re-build of the virtualbox additions links against the new kernel/headers
reboot

#make sure we wait for the reboot, otherwise we will run in ugly race conditions
sleep 999999 
