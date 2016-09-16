#!/bin/bash

PACKAGES="mysql-server-5.6"

## This will be changed by cloud-init

MYSQL_PASSWORD=supersecret


export DEBIAN_FRONTEND=noninteractive

if ( apt-get -y install ${PACKAGES} ) ; then
	mysqladmin password ${MYSQL_PASSWORD}
fi

