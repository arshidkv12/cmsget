#!/bin/bash

#package function 
function package_exists() {
    return dpkg -l "$1" &> /dev/null
}

if [  -f /var/www/html/index.php ]; then
    echo "Already exist index.php"
    exit
fi

apt-get update -y
apt-get install apache2 -y 
apt-get install php5-mysql -y
mysql_install_db -y
mysql_secure_installation -y
apt-get install php5 libapache2-mod-php5 php5-mcrypt php5-gd php5-cli php5-common -y
apt-get install php5-curl php5-dbg  php5-xmlrpc php5-fpm php-apc php-pear php5-imap -y
apt-get install php5-pspell php5-dev -y 

PASSWORD=`date +%s|sha256sum|base64|head -c 12`
sleep 1
USERNAME=`date +%s|sha256sum|base64|head -c 7`
  
#mysql
export DEBIAN_FRONTEND=noninteractive
if ! package_exists mysql-server; then
  apt-get -q -y install mysql-server
  mysqladmin -u root password  $PASSWORD
fi

if ! package_exists phpmyadmin ; then
  APP_PASS=$PASSWORD
  ROOT_PASS=$PASSWORD
  APP_DB_PASS=$PASSWORD

  echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/app-password-confirm password $APP_PASS" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/mysql/admin-pass password $ROOT_PASS" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/mysql/app-pass password $APP_DB_PASS" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections

  apt-get install -y phpmyadmin
 fi

#mail
apt-get install php-pear 
pear install mail 
pear install Net_SMTP 
pear install Auth_SASL 
pear install mail_mime

if ! package_exists postfix ; then
    debconf-set-selections <<< "postfix postfix/mailname string 'localhost'"
    debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
    apt-get install -y postfix
fi


service apache2 restart
#/etc/init.d/mysql restart

mysql -uroot -p$PASSWORD <<MYSQL_SCRIPT
CREATE DATABASE $USERNAME;
CREATE USER '$USERNAME'@'localhost' IDENTIFIED BY '$PASSWORD';
GRANT ALL PRIVILEGES ON $USERNAME.* TO '$USERNAME'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "MySQL user created."
echo "Username:   $USERNAME"
 


echo "============================================"
echo "A robot is now installing WordPress for you."
echo "============================================"
#download wordpress
wget https://wordpress.org/latest.tar.gz
#unzip wordpress
tar -zxvf latest.tar.gz
#change dir to wordpress
cd wordpress
#copy file to parent dir
cp -rf . /var/www/html
#move back to parent dir
cd /var/www/html
#remove files from wordpress folder
#rm -R wordpress
#create wp config
cp wp-config-sample.php wp-config.php
#set database details with perl find and replace
perl -pi -e "s/database_name_here/$USERNAME/g" wp-config.php
perl -pi -e "s/username_here/$USERNAME/g" wp-config.php
perl -pi -e "s/password_here/$PASSWORD/g" wp-config.php

#set WP salts
perl -i -pe'
  BEGIN {
    @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
    push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
    sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
  }
  s/put your unique phrase here/salt()/ge
' wp-config.php

#create uploads folder and set permissions
mkdir wp-content/uploads
chmod 775 wp-content/uploads
echo "Cleaning..."
cd
#remove zip file
rm latest.tar.gz
rm -rf wordpress
rm cmsget.sh
#remove bash script

rm -rf /var/www/html/index.html



ip=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)

echo "========================="
echo        "WordPress"
echo "========================="

echo "URL : http://$ip/"

echo "========================"

echo "Database : http://$ip/phpmyadmin"
echo "Username:   $USERNAME"
echo "Password: $PASSWORD"

echo "========================"




