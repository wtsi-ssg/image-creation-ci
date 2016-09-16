#!/bin/bash

if [ "${SUDO_USER}" = "ubuntu" ] ; then
  apt-get install -y ruby rubygems-integration 
fi
 
if [ "${SUDO_USER}" = "centos" ] ; then
  http_proxy=""; export http_proxy
  https_proxy=""; export https_proxy
  no_proxy=",172.31.0.18"; export no_proxy
  BUSSER_ROOT="/tmp/verifier"; export BUSSER_ROOT
  GEM_HOME="/tmp/verifier/gems"; export GEM_HOME
  GEM_PATH="/tmp/verifier/gems"; export GEM_PATH
  GEM_CACHE="/tmp/verifier/gems/cache"; export GEM_CACHE
  yum install -y rubygems ruby-devel gcc
  gem install rdoc
  gem install rspec-core
  gem install serverspec
  gem install json
  chmod -R 777 $BUSSER_ROOT
fi

