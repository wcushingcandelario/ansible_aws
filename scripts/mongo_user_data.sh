#!/bin/bash

exec 1>/root/userdata.log 2>&1
set -x

/bin/date

REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
ENV=$(aws ec2 describe-tags --filters "Name=resource-id,Values=${INSTANCE_ID}" "Name=key,Values=environment" --region=${REGION} --output=text | cut -f5)

export ENV=${ENV}

if [ ${ENV} == 'prod' ]; then

  sed -i "s/25198105b01633367f6f135c235ae476/420d6941679dbfbe4b9dc07d8d0b4fab/" /etc/mongodb-mms/automation-agent.config
  sed -i "s/5783bd0ce4b09cfd9d5c9ee0/57ff68293b34b924734d20c7/" /etc/mongodb-mms/automation-agent.config

fi
