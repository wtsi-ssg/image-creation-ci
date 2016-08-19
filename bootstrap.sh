#!/bin/bash

if [ "$IMAGE_USERNAME" == "ubuntu" ] ; then
  apt-get install -y ruby rubygems-integration
fi
