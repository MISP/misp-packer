#!/usr/bin/env bash

## Source of the vercomp function: https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash
##vercomp () {
##    if [[ $1 == $2 ]]
##    then
##        return 0
##    fi
##    local IFS=.
##    local i ver1=($1) ver2=($2)
##    # fill empty fields in ver1 with zeros
##    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
##    do
##        ver1[i]=0
##    done
##    for ((i=0; i<${#ver1[@]}; i++))
##    do
##        if [[ -z ${ver2[i]} ]]
##        then
##            # fill empty fields in ver2 with zeros
##            ver2[i]=0
##        fi
##        if ((10#${ver1[i]} > 10#${ver2[i]}))
##        then
##            return 1
##        fi
##        if ((10#${ver1[i]} < 10#${ver2[i]}))
##        then
##            return 2
##        fi
##    done
##    return 0
##}

MISP_BRANCH='2.4'

# Grub config (reverts network interface names to ethX)
GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"
DEFAULT_GRUB=/etc/default/grub

# Ubuntu version
UBUNTU_VERSION="$(lsb_release -r -s)"

# Database configuration
DBHOST='localhost'
DBNAME='misp'
DBUSER_ADMIN='root'
DBPASSWORD_ADMIN="$(openssl rand -hex 32)"
DBUSER_MISP='misp'
DBPASSWORD_MISP="$(openssl rand -hex 32)"

# Webserver configuration
PATH_TO_MISP='/var/www/MISP'
MISP_BASEURL=''
MISP_LIVE='1'
FQDN='localhost'

# Timing creation
TIME_START=$(date +%s)

# OpenSSL configuration
OPENSSL_C='LU'
OPENSSL_ST='State'
OPENSSL_L='Location'
OPENSSL_O='Organization'
OPENSSL_OU='Organizational Unit'
OPENSSL_CN='Common Name'
OPENSSL_EMAILADDRESS='info@localhost'

# GPG configuration
GPG_REAL_NAME='Real name'
GPG_EMAIL_ADDRESS='info@localhost'
GPG_KEY_LENGTH='2048'
GPG_PASSPHRASE=''

# php.ini configuration
upload_max_filesize=50M
post_max_size=50M
max_execution_time=300
memory_limit=512M
PHP_INI=/etc/php/7.1/apache2/php.ini
## Starting Ubuntu 18.04 php71 is default
##vercomp 18.04 ${UBUNTU_VERSION}
##case $? in
##    0) op='=';PHP_INI='/etc/php/7.1/apache2/php.ini';;
##    1) op='>';PHP_INI='/etc/php/7.1/apache2/php.ini';;
##    2) op='<';PHP_INI='/etc/php/7.0/apache2/php.ini';;
##esac
PHP_INI='/etc/php/7.1/apache2/php.ini'



echo "--- Installing MISP… ---"

# echo "--- Configuring GRUB ---"
#
# for key in GRUB_CMDLINE_LINUX
# do
#     sudo sed -i "s/^\($key\)=.*/\1=\"$(eval echo \${$key})\"/" $DEFAULT_GRUB
# done
# sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "--- Updating packages list ---"
sudo apt-get -qq update

echo "--- Upgrading and autoremoving packages ---"
sudo apt-get -y upgrade
sudo apt-get -y autoremove

echo "--- Install base packages ---"
sudo apt-get -y install curl net-tools gcc git gnupg-agent make python openssl redis-server sudo tmux vim zip > /dev/null 2>&1


echo "--- Installing and configuring Postfix ---"
# # Postfix Configuration: Satellite system
# # change the relay server later with:
# sudo postconf -e 'relayhost = example.com'
# sudo postfix reload
echo "postfix postfix/mailname string `hostname`.misp.local" | debconf-set-selections
echo "postfix postfix/main_mailer_type string 'Satellite system'" | debconf-set-selections
sudo apt-get install -y postfix > /dev/null 2>&1


echo "--- Installing MariaDB specific packages and settings ---"
sudo apt-get install -y mariadb-client mariadb-server > /dev/null 2>&1
# Secure the MariaDB installation (especially by setting a strong root password)
sleep 10 # give some time to the DB to launch...
sudo systemctl restart mariadb.service
sleep 10
sudo apt-get install -y expect > /dev/null 2>&1
## do we need to spawn mysql_secure_install with sudo in future?
expect -f - <<-EOF
  set timeout 10
  spawn mysql_secure_installation
  expect "Enter current password for root (enter for none):"
  send -- "\r"
  expect "Set root password?"
  send -- "y\r"
  expect "New password:"
  send -- "${DBPASSWORD_ADMIN}\r"
  expect "Re-enter new password:"
  send -- "${DBPASSWORD_ADMIN}\r"
  expect "Remove anonymous users?"
  send -- "y\r"
  expect "Disallow root login remotely?"
  send -- "y\r"
  expect "Remove test database and access to it?"
  send -- "y\r"
  expect "Reload privilege tables now?"
  send -- "y\r"
  expect eof
EOF
sudo apt-get purge -y expect > /dev/null 2>&1


echo "--- Installing Apache2 ---"
sudo apt-get install -y apache2 apache2-doc apache2-utils > /dev/null 2>&1
echo "--- Installing mod-wsgi-py3 for misp-dashboard ---"
sudo apt-get install -y libapache2-mod-wsgi-py3 > /dev/null 2>&1
sudo a2dismod status > /dev/null 2>&1
sudo a2enmod ssl > /dev/null 2>&1
sudo a2enmod rewrite > /dev/null 2>&1
sudo a2dissite 000-default > /dev/null 2>&1
sudo a2ensite default-ssl > /dev/null 2>&1


echo "--- Installing PHP-specific packages ---"
sudo apt-get install -y libapache2-mod-php php php-cli php-crypt-gpg php-dev php-json php-mysql php-opcache php-readline php-redis php-xml > /dev/null 2>&1

echo "--- Configuring PHP ---"
for key in upload_max_filesize post_max_size max_execution_time max_input_time memory_limit
do
 sudo sed -i "s/^\($key\).*/\1 = $(eval echo \${$key})/" $PHP_INI
done

echo "--- Restarting Apache ---"
sudo systemctl restart apache2 > /dev/null 2>&1


echo "--- Retrieving MISP ---"
## Double check perms.
sudo mkdir $PATH_TO_MISP
sudo chown www-data:www-data $PATH_TO_MISP
cd $PATH_TO_MISP
sudo -u www-data git clone -b $MISP_BRANCH https://github.com/MISP/MISP.git $PATH_TO_MISP
#git checkout tags/$(git describe --tags `git rev-list --tags --max-count=1`)
sudo -u www-data git config core.filemode false
# chown -R www-data $PATH_TO_MISP
# chgrp -R www-data $PATH_TO_MISP
# chmod -R 700 $PATH_TO_MISP


echo "--- Installing Mitre's STIX ---"
sudo apt-get install -y python-dev python-pip libxml2-dev libxslt1-dev zlib1g-dev python-setuptools > /dev/null 2>&1
cd $PATH_TO_MISP/app/files/scripts
sudo -u www-data git clone https://github.com/CybOXProject/python-cybox.git
sudo -u www-data git clone https://github.com/STIXProject/python-stix.git
cd $PATH_TO_MISP/app/files/scripts/python-cybox
sudo -u www-data git checkout v2.1.0.12
sudo python setup.py install > /dev/null 2>&1
cd $PATH_TO_MISP/app/files/scripts/python-stix
sudo -u www-data git checkout v1.1.1.4
sudo python setup.py install > /dev/null 2>&1
# install mixbox to accomodate the new STIX dependencies:
cd $PATH_TO_MISP/app/files/scripts/
sudo -u www-data git clone https://github.com/CybOXProject/mixbox.git
cd $PATH_TO_MISP/app/files/scripts/mixbox
sudo -u www-data git checkout v1.0.2
sudo python setup.py install > /dev/null 2>&1

echo "--- Installing misp-dashboard ---"
cd /var/www
sudo mkdir misp-dashboard
sudo chown www-data:www-data misp-dashboard
sudo -u www-data git clone https://github.com/SteveClement/misp-dashboard.git
cd misp-dashboard
sudo /var/www/misp-dashboard/install_dependencies.sh
sudo sed -i "s/^host\ =\ localhost/host\ =\ 0.0.0.0/g" /var/www/misp-dashboard/config/config.cfg

echo "--- Retrieving CakePHP… ---"
# CakePHP is included as a submodule of MISP, execute the following commands to let git fetch it:
cd $PATH_TO_MISP
sudo -u www-data git submodule init
sudo -u www-data git submodule update
# Once done, install CakeResque along with its dependencies if you intend to use the built in background jobs:
cd $PATH_TO_MISP/app
sudo -u www-data php composer.phar require kamisama/cake-resque:4.1.2
sudo -u www-data php composer.phar config vendor-dir Vendor
sudo -u www-data php composer.phar install
# Enable CakeResque with php-redis
sudo phpenmod redis
# To use the scheduler worker for scheduled tasks, do the following:
sudo -u www-data cp -fa $PATH_TO_MISP/INSTALL/setup/config.php $PATH_TO_MISP/app/Plugin/CakeResque/Config/config.php


echo "--- Setting the permissions… ---"
sudo chown -R www-data:www-data $PATH_TO_MISP
sudo chmod -R 750 $PATH_TO_MISP
sudo chmod -R g+ws $PATH_TO_MISP/app/tmp
sudo chmod -R g+ws $PATH_TO_MISP/app/files
sudo chmod -R g+ws $PATH_TO_MISP/app/files/scripts/tmp


echo "--- Creating a database user… ---"
sudo mysql -u $DBUSER_ADMIN -p$DBPASSWORD_ADMIN -e "create database $DBNAME;"
sudo mysql -u $DBUSER_ADMIN -p$DBPASSWORD_ADMIN -e "grant usage on *.* to $DBNAME@localhost identified by '$DBPASSWORD_MISP';"
sudo mysql -u $DBUSER_ADMIN -p$DBPASSWORD_ADMIN -e "grant all privileges on $DBNAME.* to '$DBUSER_MISP'@'localhost';"
sudo mysql -u $DBUSER_ADMIN -p$DBPASSWORD_ADMIN -e "flush privileges;"
# Import the empty MISP database from MYSQL.sql
sudo -u www-data cat /var/www/MISP/INSTALL/MYSQL.sql | mysql -u $DBUSER_MISP -p$DBPASSWORD_MISP $DBNAME


echo "--- Configuring Apache… ---"
# !!! apache.24.misp.ssl seems to be missing
#cp $PATH_TO_MISP/INSTALL/apache.24.misp.ssl /etc/apache2/sites-available/misp-ssl.conf
# If a valid SSL certificate is not already created for the server, create a self-signed certificate:
sudo openssl req -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=$OPENSSL_C/ST=$OPENSSL_ST/L=$OPENSSL_L/O=<$OPENSSL_O/OU=$OPENSSL_OU/CN=$OPENSSL_CN/emailAddress=$OPENSSL_EMAILADDRESS" -keyout /etc/ssl/private/misp.local.key -out /etc/ssl/private/misp.local.crt > /dev/null


echo "--- Adding Listen 8001 for misp-dashboard ---"
sudo sed -i '/Listen 80/a Listen 0.0.0.0:8001' /etc/apache2/ports.conf

echo "--- Add a VirtualHost for MISP and misp-dashboard ---"
## Again double check this perm madness ;)
sudo cat > /etc/apache2/sites-available/misp-ssl.conf <<EOF
<VirtualHost *:80>
    ServerAdmin admin@misp.local
    ServerName misp.local
    DocumentRoot $PATH_TO_MISP/app/webroot

    <Directory $PATH_TO_MISP/app/webroot>
        Options -Indexes
        AllowOverride all
        Require all granted
    </Directory>

    LogLevel warn
    ErrorLog /var/log/apache2/misp.local_error.log
    CustomLog /var/log/apache2/misp.local_access.log combined
    ServerSignature Off
</VirtualHost>
EOF

sudo cat > /etc/apache2/sites-available/misp-dashboard.conf <<EOF
<VirtualHost *:8001>
    ServerAdmin admin@misp.local
    ServerName misp.local

    DocumentRoot /var/www/misp-dashboard
    
    WSGIDaemonProcess misp-dashboard \
       user=misp group=misp \
       python-home=/var/www/misp-dashboard/DASHENV \
       processes=1 \
       threads=15 \
       maximum-requests=5000 \
       listen-backlog=100 \
       queue-timeout=45 \
       socket-timeout=60 \
       connect-timeout=15 \
       request-timeout=60 \
       inactivity-timeout=0 \
       deadlock-timeout=60 \
       graceful-timeout=15 \
       eviction-timeout=0 \
       shutdown-timeout=5 \
       send-buffer-size=0 \
       receive-buffer-size=0 \
       header-buffer-size=0 \
       response-buffer-size=0 \
       server-metrics=Off

    WSGIScriptAlias / /var/www/misp-dashboard/misp-dashboard.wsgi

    <Directory /var/www/misp-dashboard>
        WSGIProcessGroup misp-dashboard
        WSGIApplicationGroup %{GLOBAL}
        Require all granted
    </Directory>

    LogLevel info
    ErrorLog /var/log/apache2/misp-dashboard.local_error.log
    CustomLog /var/log/apache2/misp-dashboard.local_access.log combined
    ServerSignature Off
</VirtualHost>
EOF

# cat > /etc/apache2/sites-available/misp-ssl.conf <<EOF
# <VirtualHost *:80>
#         ServerName misp.local
#
#         Redirect permanent / https://$FQDN
#
#         LogLevel warn
#         ErrorLog /var/log/apache2/misp.local_error.log
#         CustomLog /var/log/apache2/misp.local_access.log combined
#         ServerSignature Off
# </VirtualHost>
#
# <VirtualHost *:443>
#         ServerAdmin me@me.local
#         ServerName misp.local
#         DocumentRoot $PATH_TO_MISP/app/webroot
#
#         <Directory $PATH_TO_MISP/app/webroot>
#             Options -Indexes
#             AllowOverride all
#             Require all granted
#         </Directory>
#
#         SSLEngine On
#         SSLCertificateFile /etc/ssl/private/misp.local.crt
#         SSLCertificateKeyFile /etc/ssl/private/misp.local.key
#         #SSLCertificateChainFile /etc/ssl/private/misp-chain.crt
#
#         LogLevel warn
#         ErrorLog /var/log/apache2/misp.local_error.log
#         CustomLog /var/log/apache2/misp.local_access.log combined
#         ServerSignature Off
# </VirtualHost>
# EOF
# activate new vhost
sudo a2dissite default-ssl
sudo a2ensite misp-ssl
sudo a2ensite misp-dashboard


echo "--- Restarting Apache ---"
sudo systemctl restart apache2 > /dev/null 2>&1


echo "--- Configuring log rotation ---"
sudo cp $PATH_TO_MISP/INSTALL/misp.logrotate /etc/logrotate.d/misp


echo "--- MISP configuration ---"
# There are 4 sample configuration files in /var/www/MISP/app/Config that need to be copied
sudo -u www-data cp -a $PATH_TO_MISP/app/Config/bootstrap.default.php /var/www/MISP/app/Config/bootstrap.php
sudo -u www-data cp -a $PATH_TO_MISP/app/Config/database.default.php /var/www/MISP/app/Config/database.php
sudo -u www-data cp -a $PATH_TO_MISP/app/Config/core.default.php /var/www/MISP/app/Config/core.php
sudo -u www-data cp -a $PATH_TO_MISP/app/Config/config.default.php /var/www/MISP/app/Config/config.php
sudo -u www-data cat > $PATH_TO_MISP/app/Config/database.php <<EOF
<?php
class DATABASE_CONFIG {
        public \$default = array(
                'datasource' => 'Database/Mysql',
                //'datasource' => 'Database/Postgres',
                'persistent' => false,
                'host' => '$DBHOST',
                'login' => '$DBUSER_MISP',
                'port' => 3306, // MySQL & MariaDB
                //'port' => 5432, // PostgreSQL
                'password' => '$DBPASSWORD_MISP',
                'database' => '$DBNAME',
                'prefix' => '',
                'encoding' => 'utf8',
        );
}
EOF
# and make sure the file permissions are still OK
sudo chown -R www-data:www-data $PATH_TO_MISP/app/Config
sudo chmod -R 750 $PATH_TO_MISP/app/Config
# Set some MISP directives with the command line tool
sudo $PATH_TO_MISP/app/Console/cake Live $MISP_LIVE

sudo $PATH_TO_MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_enable" true
sudo $PATH_TO_MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_event_notifications_enable" true
sudo $PATH_TO_MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_object_notifications_enable" true
sudo $PATH_TO_MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_object_reference_notifications_enable" true
sudo $PATH_TO_MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_attribute_notifications_enable" true
sudo $PATH_TO_MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_sighting_notifications_enable" true
sudo $PATH_TO_MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_user_notifications_enable" true
sudo $PATH_TO_MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_organisation_notifications_enable" true

echo "--- Generating a GPG encryption key… ---"
sudo apt-get install -y rng-tools haveged
sudo -u www-data mkdir $PATH_TO_MISP/.gnupg
sudo chmod 700 $PATH_TO_MISP/.gnupg
cat >gen-key-script <<EOF
    %echo Generating a default key
    Key-Type: default
    Key-Length: $GPG_KEY_LENGTH
    Subkey-Type: default
    Name-Real: $GPG_REAL_NAME
    Name-Comment: no comment
    Name-Email: $GPG_EMAIL_ADDRESS
    Expire-Date: 0
    Passphrase: '$GPG_PASSPHRASE'
    # Do a commit here, so that we can later print "done"
    %commit
    %echo done
EOF
sudo -u www-data gpg --homedir $PATH_TO_MISP/.gnupg --batch --gen-key gen-key-script
rm gen-key-script
# And export the public key to the webroot
sudo -u www-data gpg --homedir $PATH_TO_MISP/.gnupg --batch --gen-key gen-key-scriptgpg --homedir $PATH_TO_MISP/.gnupg --export --armor $EMAIL_ADDRESS > $PATH_TO_MISP/app/webroot/gpg.asc


echo "--- Making the background workers start on boot… ---"
sudo chmod 755 $PATH_TO_MISP/app/Console/worker/start.sh
# With systemd:
# sudo cat > /etc/systemd/system/workers.service  <<EOF
# [Unit]
# Description=Start the background workers at boot
#
# [Service]
# Type=forking
# User=www-data
# ExecStart=$PATH_TO_MISP/app/Console/worker/start.sh
#
# [Install]
# WantedBy=multi-user.target
# EOF
# sudo systemctl enable workers.service > /dev/null
# sudo systemctl restart workers.service > /dev/null

# With initd:
if [ ! -e /etc/rc.local ]
then
    echo '#!/bin/sh -e' | sudo tee -a /etc/rc.local
    echo 'exit 0' | sudo tee -a /etc/rc.local
    sudo chmod u+x /etc/rc.local
fi


# redis-server requires the following /sys/kernel tweak
sudo sed -i -e '$i \echo never > /sys/kernel/mm/transparent_hugepage/enabled\n' /etc/rc.local
sudo sed -i -e '$i \echo 1024 > /proc/sys/net/core/somaxconn\n' /etc/rc.local
sudo sed -i -e '$i \sysctl vm.overcommit_memory=1\n' /etc/rc.local
sudo sed -i -e '$i \sudo -u www-data bash /var/www/MISP/app/Console/worker/start.sh\n' /etc/rc.local
sudo sed -i -e '$i \sudo -u www-data misp-modules -l 0.0.0.0 -s &\n' /etc/rc.local
sudo sed -i -e '$i \sudo -u www-data bash /var/www/misp-dashboard/start_all.sh\n' /etc/rc.local

echo "--- Installing MISP modules… ---"
sudo apt-get install -y python3-dev python3-pip libpq5 libjpeg-dev libfuzzy-dev > /dev/null 2>&1
cd /usr/local/src/
sudo git clone https://github.com/MISP/misp-modules.git
cd misp-modules
sudo pip3 install -I -r REQUIREMENTS > /dev/null 2>&1
sudo pip3 install -I . > /dev/null 2>&1
sudo pip3 install lief 2>&1
sudo pip3 install pymisp python-magic > /dev/null 2>&1
sudo pip3 install git+https://github.com/kbandla/pydeep.git > /dev/null 2>&1
sudo pip2 install pymisp python-magic > /dev/null 2>&1
sudo pip2 install git+https://github.com/kbandla/pydeep.git > /dev/null 2>&1
sudo pip2 install lief 2>&1
# install STIX2.0 library to support STIX 2.0 export:
sudo pip3 install stix2 > /dev/null 2>&1
# With systemd:
# sudo cat > /etc/systemd/system/misp-modules.service  <<EOF
# [Unit]
# Description=Start the misp modules server at boot
#
# [Service]
# Type=forking
# User=www-data
# ExecStart=/bin/sh -c 'misp-modules -l 0.0.0.0 -s &'
#
# [Install]
# WantedBy=multi-user.target
# EOF
# sudo systemctl enable misp-modules.service > /dev/null
# sudo systemctl restart misp-modules.service > /dev/null

# With initd:
# sudo sed -i -e '$i \sudo -u www-data misp-modules -l 0.0.0.0 -s &\n' /etc/rc.local



echo "--- Restarting Apache… ---"
sudo systemctl restart apache2 > /dev/null 2>&1
sleep 5

echo "--- Updating the galaxies… ---"
sudo -E $PATH_TO_MISP/app/Console/cake userInit -q > /dev/null
AUTH_KEY=$(mysql -u $DBUSER_MISP -p$DBPASSWORD_MISP misp -e "SELECT authkey FROM users;" | tail -1)
echo "--- Updating the galaxies… ---"
curl --header "Authorization: $AUTH_KEY" --header "Accept: application/json" --header "Content-Type: application/json" -o /dev/null -s -X POST http://127.0.0.1/galaxies/update

echo "--- Updating the taxonomies… ---"
curl --header "Authorization: $AUTH_KEY" --header "Accept: application/json" --header "Content-Type: application/json" -o /dev/null -s -X POST http://127.0.0.1/taxonomies/update

echo "--- Updating the warning lists… ---"
curl --header "Authorization: $AUTH_KEY" --header "Accept: application/json" --header "Content-Type: application/json" -o /dev/null -s -X POST http://127.0.0.1/warninglists/update

echo "--- Updating the object templates… ---"
curl --header "Authorization: $AUTH_KEY" --header "Accept: application/json" --header "Content-Type: application/json" -o /dev/null -s -X POST http://127.0.0.1/objectTemplates/update

echo "--- Setting Baseurl ---"
sudo $PATH_TO_MISP/app/Console/cake Baseurl ""

echo "--- Enabling MISP new pub/sub feature (ZeroMQ)… ---"
sudo apt-get install -y pkg-config python-redis python-zmq > /dev/null 2>&1

echo "\e[32mMISP is ready\e[0m"
echo "Login and passwords for the MISP image are the following:"
echo "Web interface (default network settings): $MISP_BASEURL"
echo "MISP admin:  admin@admin.test/admin"
echo "Shell/SSH: misp/Password1234"
echo "MySQL:  $DBUSER_ADMIN/$DBPASSWORD_ADMIN - $DBUSER_MISP/$DBPASSWORD_MISP"


TIME_END=$(date +%s)
TIME_DELTA=$(expr ${TIME_END} - ${TIME_START})

echo "The generation took ${TIME_DELTA} seconds"
