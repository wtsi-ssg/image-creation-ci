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
