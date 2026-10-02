#!/bin/bash
 
#####################################################################################
#                                                                                   #
# * Rocky10 APMinstaller v.1.6                                                       #
# * Rocky 10.X   Minimal ISO                                                        #
# * Apache 2.4.X , MariaDB 13.1.X, Multi-PHP setup shell script                     #
# * Created Date    : 2026/10/02                                                    #
# * Created by  : Joo Sung ( webmaster@apachezone.com )                             #
#                                                                                   #
#####################################################################################


##########################################
#                                        #
#           phpMyAdmin install           #
#                                        #
########################################## 

wget https://files.phpmyadmin.net/phpMyAdmin/5.2.3/phpMyAdmin-5.2.3-all-languages.zip
unzip phpMyAdmin-5.2.3-all-languages.zip
mv phpMyAdmin-5.2.3-all-languages /usr/share/phpMyAdmin

mkdir /usr/share/phpMyAdmin/tmp
chown -R apache:apache /usr/share/phpMyAdmin

chmod 777 /usr/share/phpMyAdmin/tmp
chcon -Rv --type=httpd_sys_content_t /usr/share/phpMyAdmin/*

echo "# phpMyAdmin - Web based MySQL browser written in php
# 
# Allows only localhost by default
#
# But allowing phpMyAdmin to anyone other than localhost should be considered
# dangerous unless properly secured by SSL
Alias /phpMyAdmin /usr/share/phpMyAdmin
Alias /phpmyadmin /usr/share/phpMyAdmin
<Directory /usr/share/phpMyAdmin/>
  AddDefaultCharset UTF-8
   <IfModule mod_authz_core.c>
     # Apache 2.4
     <RequireAny>
      Require all granted
     </RequireAny>
   </IfModule>
</Directory>
<Directory /usr/share/phpMyAdmin/setup/>
    <IfModule mod_authz_core.c>
 # Apache 2.4
     <RequireAny>
       Require all granted
     </RequireAny>
   </IfModule>
</Directory>

# These directories do not require access over HTTP - taken from the original
# phpMyAdmin upstream tarball
#
<Directory /usr/share/phpMyAdmin/libraries/>
    Require all denied
</Directory>

<Directory /usr/share/phpMyAdmin/templates/>
    Require all denied
</Directory>

<Directory /usr/share/phpMyAdmin/setup/lib/>
    Require all denied
</Directory>

<Directory /usr/share/phpMyAdmin/setup/frames/>
    Require all denied
</Directory>

# This configuration prevents mod_security at phpMyAdmin directories from
# filtering SQL etc.  This may break your mod_security implementation.
#
#<IfModule mod_security.c>
#    <Directory /usr/share/phpMyAdmin/>
#        SecRuleInheritance Off
#    </Directory>
#</IfModule>" >> /etc/httpd/conf.d/phpMyAdmin.conf

cp -av /usr/share/phpMyAdmin/config.sample.inc.php /usr/share/phpMyAdmin/config.inc.php

cd /usr/share/phpMyAdmin/

# 쿠키 암호화에 사용되는 키 생성
BLOWFISH_SECRET=$(< /dev/urandom tr -dc 'A-Za-z0-9!@#' | head -c 32)
sed -i "s/\$cfg\['blowfish_secret'\] = '[^']*'/\$cfg\['blowfish_secret'\] = '${BLOWFISH_SECRET}'/g" config.inc.php

echo "\$cfg['TempDir'] = '/var/www/html/phpMyAdmin/tmp/';" >> config.inc.php

systemctl restart httpd.service

sh /root/AAI/restart.sh

echo ""
echo ""
echo "축하 드립니다. phpMyAdmin 설치 작업이 끝났습니다."

exit 0
