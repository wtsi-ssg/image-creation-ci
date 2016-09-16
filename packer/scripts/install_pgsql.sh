#!/bin/bash

PACKAGES="postgresql-9.3"

## This will be changed by cloud-init

PGSQL_PASSWORD=supersecret


export DEBIAN_FRONTEND=noninteractive

if ( apt-get -y install ${PACKAGES} ) ; then
	sudo -u postgres psql -c  "ALTER USER postgres WITH PASSWORD '${PGSQL_PASSWORD}';"
fi

