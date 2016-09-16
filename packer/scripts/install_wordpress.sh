#!/bin/bash

##----------------------------------------------------------------------
## web/enable_unattended_updates.sh
##----------------------------------------------------------------------

## Enable automatic updates

echo 'Unattended-Upgrade::Allowed-Origins {'        >  /etc/apt/apt.conf.d/51my-unattended-upgrades
echo '  "${distro_id}:${distro_codename}-updates";' >> /etc/apt/apt.conf.d/51my-unattended-upgrades
echo '];'                                           >> /etc/apt/apt.conf.d/51my-unattended-upgrades
##----------------------------------------------------------------------
## web/make_english.sh
##----------------------------------------------------------------------

## Set timezone to london...
timedatectl set-timezone Europe/London

## Set language to English not American and try and force it
## to each new user!

export LANG='en_GB.UTF-8'
echo 'LANG="en_GB.UTF-8"' > /etc/default/locale
locale-gen --purge en_GB.utf8 en_US.utf8
dpkg-reconfigure locales
##----------------------------------------------------------------------
## web/setup_apache.sh
##----------------------------------------------------------------------
#!/bin/bash -eux

## Install Apache2 and mod_php5 (and it's MySQL plugin)

DEBIAN_FRONTEND=noninteractive apt-get -q -y install apache2 php5 libapache2-mod-php5 php5-mysql

## Enable mod_rwrite

a2enmod rewrite

##----------------------------------------------------------------------
## web/setup_database.sh
##----------------------------------------------------------------------

## Create a password - make up of number/lower/upper!

## Install MySQL (does not prompt for password)

DEBIAN_FRONTEND=noninteractive apt-get -q -y install mysql-server-5.6 mysql-client-5.6 pwgen

export PASSWORD=`pwgen -1cns`

## Now we set the generated password..

mysqladmin password $PASSWORD

## Store password in /home/ubuntu/.my.cnf so:
## (a) User can log in as root with no password
## (b) Know what password is to set/reset it....

echo '[client]'                              >  /home/ubuntu/.my.cnf
echo 'user = root'                           >> /home/ubuntu/.my.cnf
echo 'password = ' $PASSWORD                 >> /home/ubuntu/.my.cnf
echo ''                                      >> /home/ubuntu/.my.cnf
echo '; To change your password you can run' >> /home/ubuntu/.my.cnf
echo ';'                                     >> /home/ubuntu/.my.cnf
echo ';    mysqladmin password'              >> /home/ubuntu/.my.cnf
echo ';'                                     >> /home/ubuntu/.my.cnf
echo ''                                      >> /home/ubuntu/.my.cnf
echo '; It is not good policy to leave the root password in this file' >> /home/ubuntu/.my.cnf
echo ''                                      >> /home/ubuntu/.my.cnf

## Make it read write by user only so that it can't be read by others!

chmod 600 /home/ubuntu/.my.cnf
chown ubuntu: /home/ubuntu/.my.cnf

##----------------------------------------------------------------------
## web/setup_postfix.sh
##----------------------------------------------------------------------

## Set up postfix so we can send emails from wordpress...
## Note more work needs to be done to correctly set the
## hostname of the box - this will need to be done by the
## user or in some cloud-forms based post-launch config.

debconf-set-selections <<< "postfix postfix/mailname string my_testserver"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install -y postfix
##----------------------------------------------------------------------
## web/setup_wordpress.sh
##----------------------------------------------------------------------

## * Change to the /tmp folder and download wordpress
## * install it into the default apache htdocs directory
## * chown it www-data so it can update itself
## * and finally tidy up tmp!

cd /tmp
wget https://wordpress.org/latest.tar.gz
tar zxf latest.tar.gz
mv wordpress/* /var/www/html
rmdir wordpress
rm /var/www/html/index.html
chown -R www-data: /var/www/html
rm latest.tar.gz

## Now we write the wordress apache configuration file to apache
## sites-available directory - and 

cd /etc/apache2/sites-available

echo '<VirtualHost *:80>'                                >  wordpress.conf
echo '  ServerAdmin webmaster@localhost'                 >> wordpress.conf
echo '  DocumentRoot /var/www/html'                      >> wordpress.conf
echo '  ErrorLog ${APACHE_LOG_DIR}/error.log'            >> wordpress.conf
echo '  CustomLog ${APACHE_LOG_DIR}/access.log combined' >> wordpress.conf
echo '  <Directory /var/www/html>'                       >> wordpress.conf
echo '    AllowOverride  None'                           >> wordpress.conf
echo '    RewriteEngine On'                              >> wordpress.conf
echo '    RewriteBase /'                                 >> wordpress.conf
echo '    RewriteRule ^index\.php$ - [L]'                >> wordpress.conf
echo '    RewriteCond %{REQUEST_FILENAME} !-f'           >> wordpress.conf
echo '    RewriteCond %{REQUEST_FILENAME} !-d'           >> wordpress.conf
echo '    RewriteRule . /index.php [L]'                  >> wordpress.conf
echo '  </Directory>'                                    >> wordpress.conf
echo '</VirtualHost>'                                    >> wordpress.conf

## An enable the site (as the default site) and remove the ubuntu
## default configuration

a2ensite wordpress
a2dissite 000-default

## Restart apache...
/etc/init.d/apache2 restart 

export PASSWORD=`pwgen -1cns`

## Create the database with a random password!

echo 'create database wordpress' | mysql
echo 'grant select,update,delete,create temporary tables,insert,alter,drop,create view,show view,create,index,lock tables,trigger on wordpress.* to "wordpress_admin"@"%" identified by "'$PASSWORD'";' | mysql

## Now we write out the wp-config file and include in it the MySQL
## username and password set up above

echo '<?php'                                                      >  /var/www/html/wp-config.php
echo ''                                                           >> /var/www/html/wp-config.php
echo '/* Below are the details for the database configuration */' >> /var/www/html/wp-config.php
echo ''                                                           >> /var/www/html/wp-config.php
echo 'define('"'"'DB_NAME'"'"',     '"'"'wordpress'"'"');'        >> /var/www/html/wp-config.php
echo 'define('"'"'DB_USER'"'"',     '"'"'wordpress_admin'"'"');'  >> /var/www/html/wp-config.php
echo 'define('"'"'DB_PASSWORD'"'"', '"'"$PASSWORD"'"');'          >> /var/www/html/wp-config.php
echo 'define('"'"'DB_HOST'"'"',     '"'"'localhost'"'"');'        >> /var/www/html/wp-config.php
echo 'define('"'"'DB_CHARSET'"'"',  '"'"'utf8'"'"');'             >> /var/www/html/wp-config.php
echo 'define('"'"'DB_COLLATE'"'"',  '"''"');'                     >> /var/www/html/wp-config.php
echo ''                                                           >> /var/www/html/wp-config.php
echo '/* Table prefix (to allow multiple wp sites in one db */'   >> /var/www/html/wp-config.php
echo ''                                                           >> /var/www/html/wp-config.php
echo '$table_prefix  = '"'"'wp_'"'"';'                            >> /var/www/html/wp-config.php
echo ''                                                           >> /var/www/html/wp-config.php
echo '/* Now for random encryption strings */'                    >> /var/www/html/wp-config.php
echo ''                                                           >> /var/www/html/wp-config.php
wget -O- https://api.wordpress.org/secret-key/1.1/salt/           >> /var/www/html/wp-config.php
echo ''                                                           >> /var/www/html/wp-config.php
echo '/* Note: to invalidate all sessions you replace this'       >> /var/www/html/wp-config.php
echo '   section of the configuration file with new output from:' >> /var/www/html/wp-config.php
echo '     https://api.worpress.org/secret-key/1.1/salt/'         >> /var/www/html/wp-config.php
echo ''                                                           >> /var/www/html/wp-config.php
echo '/* Turn off debug output... set to true to turn on */'      >> /var/www/html/wp-config.php
echo ''                                                           >> /var/www/html/wp-config.php
echo 'define('"'"'WP_DEBUG'"'"', false);'                         >> /var/www/html/wp-config.php
echo ''                                                           >> /var/www/html/wp-config.php
echo '/* Don'"'"'t touch below this line - include other settings */'  >> /var/www/html/wp-config.php
echo ''                                                           >> /var/www/html/wp-config.php
echo 'if ( !defined('"'"'ABSPATH'"'"') ) {'                       >> /var/www/html/wp-config.php
echo '  define('"'"'ABSPATH'"'"', dirname(__FILE__) . '"'"'/'"'"');' >> /var/www/html/wp-config.php
echo '}'                                                          >> /var/www/html/wp-config.php
echo ''                                                           >> /var/www/html/wp-config.php
echo 'require_once(ABSPATH . '"'"'wp-settings.php'"'"');'         >> /var/www/html/wp-config.php 
echo ''                                                           >> /var/www/html/wp-config.php

## Write out the motd - with information on how to get db details etc
## and let people know what has been set up

echo '###################################################################' >  /etc/motd
echo '##                                                               ##' >> /etc/motd
echo '##  Your wordpress webserver is now set up. To configure it      ##' >> /etc/motd
echo '##  go to the website in your browser and enter the name of      ##' >> /etc/motd
echo '##  the site, and your email address                             ##' >> /etc/motd
echo '##                                                               ##' >> /etc/motd
echo '##  You will find the wordpress source files in:                 ##' >> /etc/motd
echo '##                                                               ##' >> /etc/motd
echo '##    /var/www/html/                                             ##' >> /etc/motd
echo '##                                                               ##' >> /etc/motd
echo '##  The wordpress database is "wordpress" you can find the       ##' >> /etc/motd
echo '##  connection details of the MySQL user for this database in:   ##' >> /etc/motd
echo '##                                                               ##' >> /etc/motd
echo '##    /var/www/html/wp-config.php                                ##' >> /etc/motd
echo '##                                                               ##' >> /etc/motd
echo '##  You can find the general MySQL passwords in                  ##' >> /etc/motd
echo '##                                                               ##' >> /etc/motd
echo '##    /home/ubuntu/.my.cnf                                       ##' >> /etc/motd
echo '##                                                               ##' >> /etc/motd
echo '###################################################################' >> /etc/motd
echo '' >> /etc/motd
echo '' >> /etc/motd
