#!/bin/bash

exec 1>/root/userdata.log 2>&1
set -x

/bin/date

export ENV=pre-prod


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

export FILE_NAME=/opt/ovc/posWebapp/WEB-INF/web.xml
export LOCAL_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
sudo /usr/bin/patch $FILE_NAME $FILE_NAME.patch.$ENV
#sed -i.bak "s/this_host\:8080/$LOCAL_IP\:8080/" $FILE_NAME
sed -i.bak "s#http://this_host:8080#https://$LOCAL_IP#” $FILE_NAME

sudo /sbin/service jetty restart
sudo /sbin/service httpd restart

# (optional) You might need to set your PATH variable at the top here
# depending on how you run this script
#PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Hosted Zone ID e.g. BJBK35SKMM9OE
ZONEID="Z3A98VA7X0SL0T"

# The CNAME you want to update e.g. hello.example.com
#RECORDSET="enter cname here"

# More advanced options below
# The Time-To-Live of this recordset
TTL=60
# Change this if you want
#COMMENT="Auto updating @ `date`"
# Change to AAAA if using an IPv6 address
TYPE="A"

# Get the external IP address from OpenDNS (more reliable than other providers)
#IP=`dig +short myip.opendns.com @resolver1.opendns.com`
IP=`wget -qO- http://instance-data/latest/meta-data/local-ipv4`

#function valid_ip()
#{
#    local  ip=$1
#    local  stat=1
#
#    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
#        OIFS=$IFS
#        IFS='.'
#        ip=($ip)
#        IFS=$OIFS
#        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
#            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
#        stat=$?
#    fi
#    return $stat
#}

# Get current dir
# (from http://stackoverflow.com/a/246128/920350)
#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOGFILE="/home/bill/update-route53.log"
IPFILE="/home/bill/update-route53.ip"

#if ! valid_ip $IP; then
#    echo "Invalid IP address: $IP" >> "$LOGFILE"
#    exit 1
#fi

# Check if the IP has changed
if [ ! -f "$IPFILE" ]
    then
    touch "$IPFILE"
fi

if grep -Fxq "$IP" "$IPFILE"; then
    # code if found
    echo "IP is still $IP. Exiting" >> "$LOGFILE"
    exit 0
else
    echo "IP has changed to $IP" >> "$LOGFILE"
    # Fill a temp file with valid JSON
    TMPFILE=$(mktemp /tmp/temporary-file.XXXXXXXX)
    cat > ${TMPFILE} << EOF
    {
      "Comment":"$COMMENT",
      "Changes":[
        {
          "Action":"UPSERT",
          "ResourceRecordSet":{
            "ResourceRecords":[
              {
                "Value":"$IP"
              }
            ],
            "Name":"preprod.ovchosting.co.uk.",
            "Type":"$TYPE",
            "TTL":$TTL
          }
        }
      ]
    }
EOF

    # Update the Hosted Zone record
    aws route53 change-resource-record-sets \
        --hosted-zone-id $ZONEID \
        --change-batch file://"$TMPFILE" >> "$LOGFILE"
    echo "" >> "$LOGFILE"

    # Clean up
    rm $TMPFILE
fi

# All Done - cache the IP address for next time
echo "$IP" > "$IPFILE"
