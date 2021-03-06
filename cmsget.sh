
#!/bin/bash

#package function 


# Return values:
#  0 - package is installed
#  1 - package is not installed, 
package_exists(){
  if dpkg-query -s "$1" 1>/dev/null 2>&1; then
    return 0   # package is installed
  else
      return 1 # package is not installed, it is available in package repository
  fi
}

if [  -f /var/www/html/index.php ]; then
    echo "Already exist /var/www/html/index.php"
    exit
fi
#repository 
apt-get install software-properties-common python-software-properties -y
add-apt-repository -y ppa:ondrej/php

apt-get update -y

apt-get install apache2 -y 

apt-get install php libapache2-mod-php php-gd php-mysql php-cli php-common -y --allow-unauthenticated
apt-get install php-curl  php-xmlrpc php-fpm  php-pear php-imap -y --allow-unauthenticated
apt-get install php-pspell php-dev php-zip -y  --allow-unauthenticated


a2enmod php
systemctl restart apache2


DATE=$(date +%s)
PASSWORD=$(echo $RANDOM$DATE|sha256sum|base64|head -c 12)
sleep 1
USERNAME=`date +%s|sha256sum|base64|head -c 7`
  
#mysql
export DEBIAN_FRONTEND=noninteractive
if ! package_exists mysql-server ; then
    DEBIAN_FRONTEND=noninteractive apt-get -q -y install mysql-server-5.7
    mysql_secure_installation 
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

  apt-get install -y phpmyadmin --allow-unauthenticated
 fi

#mail
apt-get install php-pear -y
pear install mail 
pear install Net_SMTP 
pear install Auth_SASL 
pear install mail_mime

if ! package_exists postfix ; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y postfix
fi

#Change postfix in php.ini
send_path=/etc/postfix
sed -i 's@;sendmail_path =@send_path = '${send_path}'@' /etc/php/apache2/php.ini


phpmemory_limit=256M  
sed -i 's/memory_limit = .*/memory_limit = '${phpmemory_limit}'/' /etc/php/apache2/php.ini

max_execution_time=300   
sed -i 's/max_execution_time = .*/max_execution_time = '${max_execution_time}'/' /etc/php/apache2/php.ini

upload_max_filesize=456 
sed -i 's/upload_max_filesize = .*/upload_max_filesize = '${upload_max_filesize}'/' /etc/php/apache2/php.ini

post_max_size=456 
sed -i 's/post_max_size = .*/post_max_size = '${post_max_size}'/' /etc/php/apache2/php.ini


service postfix restart

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




