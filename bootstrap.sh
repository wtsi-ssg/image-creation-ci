#!/bin/bash

if [ "${SUDO_USER}" = "ubuntu" ] ; then
  apt-get install -y ruby rubygems-integration 
fi
 
if [ "${SUDO_USER}" = "centos" ] ; then
  yum install -y rubygems ruby-devel
fi

