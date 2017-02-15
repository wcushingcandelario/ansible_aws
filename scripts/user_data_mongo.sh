#!/bin/sh

set -e -x

HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
IP_ADDR=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
HOST_LINE="$IP_ADDR       $HOSTNAME"

hostname $HOSTNAME

sudo sed -i "s/HOSTNAME=.*/HOSTNAME=$HOSTNAME/g" /etc/sysconfig/network
sudo -- sh -c -e "echo '$HOST_LINE'"  >> /etc/hosts
