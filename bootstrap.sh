#!/bin/bash
apt-get install -y ruby rubygems-integration

export

if [ "$IMAGE_USERNAME" == "ubuntu" ] ; then
  apt-get install -y ruby rubygems-integration
fi
if [ "$IMAGE_USERNAME" == "centos" ] ; then
  yum -y install rubygem-bundler ruby
fi
