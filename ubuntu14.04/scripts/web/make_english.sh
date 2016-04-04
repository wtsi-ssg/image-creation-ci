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
