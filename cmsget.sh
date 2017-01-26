apt-get update -y
apt-get install apache2 -y 
apt-get install mysql-server php5-mysql -y
mysql_install_db -y
mysql_secure_installation -y
apt-get install php5 libapache2-mod-php5 php5-mcrypt php5-gd php5-cli php5-common -y
apt-get install php5-curl php5-dbg  php5-xmlrpc php5-fpm php-apc php-pear php5-imap -y
apt-get install php5-pspell php5-dev -y 

#mail
apt-get install php-pear 
pear install mail 
pear install Net_SMTP 
pear install Auth_SASL 
pear install mail_mime

debconf-set-selections <<< "postfix postfix/mailname string localhost"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install -y postfix



function set_php_ini {

	#mail 
	sed -e '/^[^;]*sendmail_path/s/=.*$/= \/usr\/bin\/msmtp -t/' /etc/php5/apache2/php.ini

	#max file upload 
	upload_max_filesize=240M
	post_max_size=50M
	max_execution_time=100
	max_input_time=223

	for key in upload_max_filesize post_max_size max_execution_time max_input_time
	do
	 sed -i "s/^\($key\).*/\1 $(eval echo \${$key})/" /etc/php5/apache2/php.ini
	done
}

set_php_ini

service apache2 restart
