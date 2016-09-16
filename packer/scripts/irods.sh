#!/bin/bash 

apt-get -y install postgresql libjson-perl python-psutil python-requests unixodbc odbc-postgresql super git unzip libaio-dev python-jsonschema pwgen lvm2

#install irods packages
dpkg -i /var/tmp/irods-icat-4.1.8-64bit.deb  /var/tmp/irods-database-plugin-postgres-1.8.deb

#make sure that the init script is executable, WHY DID I MAKE SURE IT WAS WRITABLE AS WELL? 
chmod +wx /var/tmp/init.sh

#add the init script to /etc/rc.local
sed -i '/^exit 0/i \/var/tmp/init.sh' /etc/rc.local


