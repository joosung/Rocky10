#!/bin/bash
 
#####################################################################################
#                                                                                   #
# * Rocky10 APMinstaller v.1.6                                                     #
# * Rocky 10.X   Minimal ISO                                                        #
# * Apache 2.4.X , MariaDB 10.5.X, Multi-PHP(base php7.4) setup shell script        #
# * Created Date    : 2026/09/30                                                    #
# * Created by  : Joo Sung ( webmaster@apachezone.com )                             #
#                                                                                   #
#####################################################################################

##########################################
#                                        #
#           repositories install         #
#                                        #
########################################## 
dnf check-update

dnf -y install wget bind-utils git nc vim-enhanced  ntsysv \
iotop sysstat strace lsof mc lrzsz zip unzip bzip2 net-tools bind gcc \
libxml2-devel libXpm-devel gmp-devel libicu-devel openssl-devel openssl \
bzip2-devel libcurl-devel libjpeg-devel libpng-devel freetype-devel readline-devel \
libxslt-devel curl-devel ncurses-devel autoconf automake zlib-devel libuuid-devel \
gettext-devel net-snmp-devel libevent-devel postgresql-devel bison make pkgconfig yum-utils

dnf install -y dnf-utils http://rpms.remirepo.net/enterprise/remi-release-10.rpm

echo "[mariadb]" > /etc/yum.repos.d/MariaDB.repo
echo "name = MariaDB" >> /etc/yum.repos.d/MariaDB.repo
echo "baseurl = http://yum.mariadb.org/13.1.1/rockylinux10-amd64" >> /etc/yum.repos.d/MariaDB.repo
echo "gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB" >> /etc/yum.repos.d/MariaDB.repo
echo "gpgcheck=1" >> /etc/yum.repos.d/MariaDB.repo 

dnf  -y update

systemctl start firewalld 
systemctl enable firewalld

systemctl start named.service
systemctl enable  named.service

cd /root/AAI/APM

##########################################
#                                        #
#           SELINUX disabled             #
#                                        #
##########################################

sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
/usr/sbin/setenforce 0

##########################################
#                                        #
#           아파치 및 HTTP2 설치            #
#                                        #
########################################## 

# /etc/mime.types 설치 
dnf  -y install mailcap

# httpd 설치
dnf -y install httpd httpd-tools

dnf -y install openldap-devel expat-devel

dnf -y install libdb-devel perl

dnf -y install httpd-devel mod_ssl python-certbot-apache

systemctl start httpd
systemctl enable httpd
#systemctl status httpd

##########################################
#                                        #
#               firewalld                #
#                                        #
##########################################  

firewall-cmd --permanent --zone=public --add-port=22/tcp
firewall-cmd --permanent --zone=public --add-port=25/tcp
firewall-cmd --permanent --zone=public --add-port=80/tcp
firewall-cmd --permanent --zone=public --add-port=443/tcp
firewall-cmd --permanent --zone=public --add-port=3306/tcp
firewall-cmd --permanent --zone=public --add-port=9090/tcp
firewall-cmd --reload
firewall-cmd --permanent --list-all

##########################################
#                                        #
#           httpd.conf   Setup           #
#                                        #
##########################################  

sed -i '/nameserver/i\nameserver 127.0.0.1' /etc/resolv.conf
cp -av /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.original

sed -i 's/DirectoryIndex index.html/ DirectoryIndex index.html index.htm index.php index.php3 index.cgi index.jsp/' /etc/httpd/conf/httpd.conf
sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/' /etc/httpd/conf/httpd.conf

cp /root/AAI/APM/index.html /var/www/html/
cp -f /root/AAI/APM/index.html /usr/share/httpd/noindex/ 

echo "<VirtualHost *:80>
  DocumentRoot /var/www/html
</VirtualHost> " >> /etc/httpd/conf.d/default.conf

systemctl restart httpd
systemctl restart named.service

##########################################
#                                        #
#      Multi PHP 및 라이브러리 install      #
#                                        #
########################################## 
dnf upgrade --refresh
dnf config-manager --set-enabled crb

dnf module list php
dnf  -y module reset php
dnf  -y module enable php:remi-8.5
dnf -y install php php-cli php-fpm php-curl php-mysqlnd php-gd php-opcache php-zip php-intl php-common php-bcmath php-imagick php-xmlrpc php-json php-readline php-redis php-mbstring php-apcu php-xml php-dom php-redis php-memcached php-memcache php-devel
 
 systemctl restart httpd

dnf -y install GeoIP GeoIP-data GeoIP-devel 

echo "#geoip setup
<IfModule mod_geoip.c>
 GeoIPEnable On
 GeoIPDBFile /usr/share/GeoIP/GeoIP.dat MemoryCache
</IfModule>" > /etc/httpd/conf.d/geoip.conf

cp -av /etc/php.ini /etc/php.ini.original
sed -i 's/short_open_tag = Off/short_open_tag = On/' /etc/php.ini
sed -i 's/expose_php = On/expose_php = Off/' /etc/php.ini
sed -i 's/display_errors = Off/display_errors = On/' /etc/php.ini
sed -i 's/;error_log = php_errors.log/error_log = php_errors.log/' /etc/php.ini
sed -i 's/error_reporting = E_ALL \& ~E_DEPRECATED/error_reporting = E_ALL \& ~E_NOTICE \& ~E_DEPRECATED \& ~E_USER_DEPRECATED/' /etc/php.ini
sed -i 's/variables_order = "GPCS"/variables_order = "EGPCS"/' /etc/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 100M/' /etc/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/' /etc/php.ini
sed -i 's/;date.timezone =/date.timezone = "Asia\/Seoul"/' /etc/php.ini
sed -i 's/session.gc_maxlifetime = 1440/session.gc_maxlifetime = 86400/' /etc/php.ini
sed -i 's/disable_functions =/disable_functions = system,exec,passthru,proc_open,popen,curl_multi_exec,parse_ini_file,show_source/' /etc/php.ini 

echo "[xdebug]
xdebug.remote_autostart = 1
xdebug.remote_connect_back = 1
xdebug.remote_enable = 1
xdebug.remote_port = 9009
xdebug.remote_handler = dbgp" >> /etc/php.ini

mkdir /etc/skel/public_html

chmod 707 /etc/skel/public_html

chmod 700 /root/AAI/adduser.sh

chmod 700 /root/AAI/deluser.sh

chmod 700 /root/AAI/restart.sh

chmod 700 /root/AAI/clamav.sh

cp /root/AAI/APM/skel/index.html /etc/skel/public_html/

systemctl restart httpd

curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ && ln -s /usr/local/bin/composer.phar /usr/local/bin/composer

sed -i 's/allow_url_fopen = On/allow_url_fopen = Off/' /etc/php.ini

systemctl restart httpd

echo '<?php
phpinfo();
?>' >> /var/www/html/phpinfo.php

##########################################
#                                        #
#          MARIADB 13.1.X install        #
#                                        #
########################################## 

# MariaDB 13.1.x 설치
dnf -y install MariaDB-server MariaDB-client

# MariaDB my.cnf 복사
#cp -av /usr/share/mysql/my-huge.cnf /etc/my.cnf.d/

systemctl enable mariadb

systemctl start mariadb

# S.M.A.R.T. 디스크 모니터링을 설치
dnf -y install smartmontools

systemctl enable smartd

systemctl start smartd

##########################################
#                                        #
#                mysql 설정               #
#                                        #
##########################################

echo "[mysql]
default-character-set = utf8mb4
 
[mysqld]
character-set-client-handshake=FALSE
init_connect="SET collation_connection = utf8mb4_unicode_ci"
init_connect="SET NAMES utf8mb4"
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
  
[client]
default-character-set = utf8mb4" > /etc/my.cnf.d/mysql-aai.cnf

mariadb-secure-installation

##########################################
#                                        #
#        운영 및 보안 관련 추가 설정           #
#                                        #
##########################################

cd /root/AAI/

#chkrootkit 설치
#wget ftp://ftp.pangeia.com.br/pub/seg/pac/chkrootkit.tar.gz 

tar xvfz chkrootkit.tar.gz

mv chkrootkit-* chkrootkit

cd chkrootkit

make sense

rm -rf /root/AAI/chkrootkit.tar.gz

 mod_security fail2ban.noarch arpwatch 설치
dnf -y install  mod_security fail2ban.noarch arpwatch

sed -i 's/SecRuleEngine On/SecRuleEngine DetectionOnly/' /etc/httpd/conf.d/mod_security.conf

#fail2ban 설치
service fail2ban start
chkconfig --level 2345 fail2ban on
sed -i 's/# enabled = true/enabled = true/' /etc/fail2ban/jail.conf 
service fail2ban restart

service arpwatch start
service arpwatch restart

#clamav 설치
dnf -y install clamav-server clamav-data clamav-update clamav-filesystem clamav clamav-scanner-systemd clamav-devel clamav-lib clamav-server-systemd

cp /usr/share/doc/clamd/clamd.conf /etc/clamd.conf

sed -i '/^Example/d' /etc/clamd.conf
sed -i 's/User <USER>/User clamscan/' /etc/clamd.conf
sed -i 's/#LocalSocket /LocalSocket /' /etc/clamd.conf
sed -i 's/clamd.<SERVICE>/clamd.scan/' /etc/clamd.conf

chmod 755 /var/run/clamd.scan

sed 's/710/755/' /usr/lib/tmpfiles.d/clamd.scan.conf > /etc/tmpfiles.d/clamd.scan.conf
cp /etc/freshclam.conf /etc/freshclam.conf.bak
sed -i '/^Example/d' /etc/freshclam.conf

echo "# Run the freshclam as daemon
[Unit]
Description = freshclam scanner
After = network.target
[Service]
Type = forking
ExecStart = /usr/bin/freshclam -d -c 4
Restart = on-failure
PrivateTmp = true
[Install]
WantedBy=multi-user.target" >> /usr/lib/systemd/system/clam-freshclam.service

systemctl enable clam-freshclam.service
systemctl start clam-freshclam.service

mv /usr/lib/systemd/system/clamd\@.service /usr/lib/systemd/system/clamd.service
rm -rf /usr/lib/systemd/system/clamd.service

echo "[Unit]
Description = clamd scanner daemon
After = syslog.target nss-lookup.target network.target

[Service]
Type = simple
ExecStart = /usr/sbin/clamd -c /etc/clamd.conf --foreground=yes
Restart = on-failure
PrivateTmp = true

[Install]
WantedBy=multi-user.target" >> /usr/lib/systemd/system/clamd.service

sed -i '/^Example$/d' /etc/clamd.d/scan.conf
sed -i -e 's/#LocalSocket \/var\/run\/clamd.scan\/clamd.sock/LocalSocket \/var\/run\/clamd.scan\/clamd.sock/g' /etc/clamd.d/scan.conf

systemctl enable clamd.service

systemctl start clamd.service

systemctl stop clamd.service

mkdir /virus
mkdir /backup

#memcache 설치
dnf -y install memcached python-memcached php-pecl-memcache

sed -i 's/OPTIONS=""/OPTIONS="-l 127.0.0.1"/' /etc/sysconfig/memcached

systemctl start memcached
systemctl enable memcached
systemctl restart memcached

systemctl restart httpd

echo "#mod_expires configuration" > /tmp/httpd.conf_tempfile
echo "<IfModule mod_expires.c>"   >> /tmp/httpd.conf_tempfile
echo "    ExpiresActive On"    >> /tmp/httpd.conf_tempfile
echo "    ExpiresDefault \"access plus 1 days\""    >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType text/css \"access plus 1 days\""       >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType text/javascript \"access plus 1 days\""      >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType text/x-javascript \"access plus 1 days\""        >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType application/x-javascript \"access plus 1 days\"" >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType application/javascript \"access plus 1 days\""    >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType image/jpeg \"access plus 1 days\""    >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType image/gif \"access plus 1 days\""       >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType image/png \"access plus 1 days\""      >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType image/bmp \"access plus 1 days\""        >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType image/cgm \"access plus 1 days\"" >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType image/tiff \"access plus 1 days\""       >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType audio/basic \"access plus 1 days\""      >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType audio/midi \"access plus 1 days\""        >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType audio/mpeg \"access plus 1 days\""        >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType audio/x-aiff \"access plus 1 days\""  >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType audio/x-mpegurl \"access plus 1 days\"" >> /tmp/httpd.conf_tempfile
echo "	  ExpiresByType audio/x-pn-realaudio \"access plus 1 days\""   >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType audio/x-wav \"access plus 1 days\""   >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType application/x-shockwave-flash \"access plus 1 days\""   >> /tmp/httpd.conf_tempfile
echo "</IfModule>"   >> /tmp/httpd.conf_tempfile
cat /tmp/httpd.conf_tempfile >> /etc/httpd/conf.d/mod_expires.conf
rm -f /tmp/httpd.conf_tempfile

##########################################
#                                        #
#            Local SSL 설정               #
#                                        #
##########################################

mv /root/AAI/APM/etc/cron.daily/backup /etc/cron.daily/
mv /root/AAI/APM/etc/cron.daily/check_chkrootkit /etc/cron.daily/
mv /root/AAI/APM/etc/cron.daily/letsencrypt-renew /etc/cron.daily/

chmod 700 /etc/cron.daily/backup
chmod 700 /etc/cron.daily/check_chkrootkit
chmod 700 /etc/cron.daily/letsencrypt-renew

echo "00 20 * * * /root/cron.daily/check_chkrootkit" >> /etc/crontab
echo "01 02,14 * * * /etc/cron.daily/letsencrypt-renew" >> /etc/crontab
echo "01 01 * * 7 /root/AAI/clamav.sh" >> /etc/crontab

#openssl 로 디피-헬만 파라미터(dhparam) 키 만들기 둘중 하나 선택
#openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

#http2 설정
echo "
<IfModule http2_module>
ProtocolsHonorOrder On
Protocols h2 h2c http/1.1
</IfModule>" >> /etc/httpd/conf.modules.d/10-h2.conf

#중요 폴더 및 파일 링크
ln -s /etc/letsencrypt /root/AAI/letsencrypt
ln -s /etc/httpd/conf.d /root/AAI/conf.d
ln -s /etc/my.cnf.d /root/AAI/my.cnf.d
ln -s /etc/php.ini /root/AAI/php/php.ini

systemctl restart httpd

cd /root/AAI

##########################################
#                                        #
#             Cockpit install            #
#                                        #
########################################## 

dnf install -y cockpit cockpit-storaged

systemctl start cockpit

systemctl enable --now cockpit.socket

sh restart.sh

echo ""
echo ""
echo "축하 드립니다. APMinstaller 모든 작업이 끝났습니다."


exit 0
