#!/bin/bash

if [ "${SUDO_USER}" = "ubuntu" ] ; then
  apt-get install -y ruby rubygems-integration 
fi
