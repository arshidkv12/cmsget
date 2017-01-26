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

echo $PASSWORD

