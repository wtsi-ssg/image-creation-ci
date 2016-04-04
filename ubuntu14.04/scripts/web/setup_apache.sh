##----------------------------------------------------------------------
## web/setup_apache.sh
##----------------------------------------------------------------------
#!/bin/bash -eux

## Install Apache2 and mod_php5 (and it's MySQL plugin)

DEBIAN_FRONTEND=noninteractive apt-get -q -y install apache2 php5 libapache2-mod-php5 php5-mysql

## Enable mod_rwrite

a2enmod rewrite

