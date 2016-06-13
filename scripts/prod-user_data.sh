#!/bin/bash#

exec 1>/root/userdata.log 2>&1
set -x

/bin/date

export ENV=prod


export FILE_NAME=/opt/ovc/Platform-Dynamic-Objects/config/unifiedConfig.properties
cp $FILE_NAME $FILE_NAME.ORIG
sudo mv $FILE_NAME.$ENV $FILE_NAME

export FILE_NAME=/opt/ovc/Platform-Dynamic-Objects/config/tools.properties
cp $FILE_NAME $FILE_NAME.ORIG
sudo mv $FILE_NAME.$ENV $FILE_NAME

export FILE_NAME=/var/www/html/ovcdashboard/app/Config/database.php
cp $FILE_NAME $FILE_NAME.ORIG
sudo mv $FILE_NAME.$ENV $FILE_NAME

export FILE_NAME=/var/www/html/ovcdashboard/app/Config/setting_var.php
cp $FILE_NAME $FILE_NAME.ORIG
sudo mv $FILE_NAME.$ENV $FILE_NAME

export FILE_NAME=/opt/ovc/posWebapp/WEB-INF/web.xml
sudo /usr/bin/patch $FILE_NAME $FILE_NAME.patch.$ENV


sudo /sbin/service jetty restart
sudo /sbin/service httpd restart
