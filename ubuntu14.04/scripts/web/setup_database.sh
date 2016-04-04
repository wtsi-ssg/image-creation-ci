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

