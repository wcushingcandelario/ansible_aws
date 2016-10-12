#!/bin/bash

exec 1>/root/userdata.log 2>&1
set -x

/bin/date

REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
ENV=$(aws ec2 describe-tags --filters "Name=resource-id,Values=${INSTANCE_ID}" "Name=key,Values=environment" --region=${REGION} --output=text | cut -f5)

export ENV=${ENV}

aws s3 cp s3://ovc-travisperkins-whitelist/${ENV}/locationWhiteList.ovccfg /opt/ovc/Application-Dynamic-Objects/Point-Of-Sale/Server-Data/tp-all/config/posMServer/locationWhiteList.ovccfg


export FILE_NAME=/opt/ovc/Platform-Dynamic-Objects/config/unifiedConfig.properties
cp $FILE_NAME $FILE_NAME.ORIG
sudo mv $FILE_NAME.$ENV $FILE_NAME

export FILE_NAME=/opt/ovc/Platform-Dynamic-Objects/config/tools.properties
cp $FILE_NAME $FILE_NAME.ORIG
sudo mv $FILE_NAME.$ENV $FILE_NAME

export FILE_NAME=/var/www/html/ovcdashboard/app/Config/database.php
cp $FILE_NAME $FILE_NAME.ORIG
sudo mv $FILE_NAME.$ENV $FILE_NAME

export FILE_NAME=/opt/jetty/webapps/context.xml
cp $FILE_NAME $FILE_NAME.ORIG
sudo mv $FILE_NAME.$ENV $FILE_NAME

export FILE_NAME=/var/www/html/ovcdashboard/app/Config/setting_var.php
cp $FILE_NAME $FILE_NAME.ORIG
sudo mv $FILE_NAME.$ENV $FILE_NAME

export FILE_NAME=/etc/filebeat/filebeat.yml
cp $FILE_NAME $FILE_NAME.ORIG
sudo mv $FILE_NAME.$ENV $FILE_NAME

export FILE_NAME=/etc/pki/tls/certs/logstash-forwarder.crt
cp $FILE_NAME $FILE_NAME.ORIG
sudo mv $FILE_NAME.$ENV $FILE_NAME

export FILE_NAME=/opt/ovc/posWebapp/WEB-INF/web.xml
export LOCAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
sudo /usr/bin/patch $FILE_NAME $FILE_NAME.patch.$ENV
sed -i.bak "s#http://this_host:8080#https://$LOCAL_IP#" $FILE_NAME

sed -i "s/env\:unknown/env:${ENV}/" /etc/dd-agent/conf.d/http_check.yaml

sed -i.bak '/-Dorg\.quartz\.scheduler\.hostName=.*/c\#This line is removed by the admin.' /opt/jetty/start.ini 

sed -i s#SITE_URL\',\"http:#SITE_URL\',\"https:#g /var/www/html/ovcdashboard/app/Config/bootstrap.php
sed -i "/-Dorg.quartz.scheduler.instanceId=/c\-Dorg.quartz.scheduler.hostName=`hostname -f`" /opt/jetty/start.ini

sudo /sbin/service jetty restart
sudo /sbin/service httpd restart

aws s3 cp s3://ovc-userdata-scripts/${ENV}/auto-userdata.sh auto-userdata.sh
chmod +x auto-userdata.sh
source auto-userdata.sh
