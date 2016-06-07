#!/bin/bash

export ENV=pre-prod


export FILE_NAME=/opt/ovc/Platform-Dynamic-Objects/config/unifiedConfig.properties
cp $FILE_NAME $FILE_NAME.ORIG
sudo mv $FILE_NAME.$ENV $FILE_NAME

export FILE_NAME=/opt/ovc/Platform-Dynamic-Objects/config/tools.properties
cp $FILE_NAME $FILE_NAME.ORIG
sudo mv $FILE_NAME.$ENV $FILE_NAME


sudo /etc/init.d/jetty restart
