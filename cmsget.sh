apt-get update -y
apt-get install apache2 -y 
apt-get install php5-mysql -y
mysql_install_db -y
mysql_secure_installation -y
apt-get install php5 libapache2-mod-php5 php5-mcrypt php5-gd php5-cli php5-common -y
apt-get install php5-curl php5-dbg  php5-xmlrpc php5-fpm php-apc php-pear php5-imap -y
apt-get install php5-pspell php5-dev -y 

#mysql
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get -q -y install mysql-server

PASSWORD=`date +%s|sha256sum|base64|head -c 12`
USERNAME=`date +%s|sha256sum|base64|head -c 7`
mysqladmin -u root password  $PASSWORD

#mail
apt-get install php-pear 
pear install mail 
pear install Net_SMTP 
pear install Auth_SASL 
pear install mail_mime

debconf-set-selections <<< "postfix postfix/mailname string localhost"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install -y postfix


service apache2 restart
/etc/init.d/mysql restart

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
#remove zip file
rm latest.tar.gz
#remove bash script
echo "========================="
echo "Installation is complete."
echo "========================="

