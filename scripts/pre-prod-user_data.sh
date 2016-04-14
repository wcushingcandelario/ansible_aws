#!/bin/bash

export ENV=pre-prod

cp /opt/ovc/Platform-Dynamic-Objects/config/unifiedConfig.properties /opt/ovc/Platform-Dynamic-Objects/config/unifiedConfig.properties.ORIG

sudo mv /opt/ovc/Platform-Dynamic-Objects/config/unifiedConfig.properties.$ENV /opt/ovc/Platform-Dynamic-Objects/config/unifiedConfig.properties


cp /opt/ovc/Platform-Dynamic-Objects/config/tools.properties /opt/ovc/Platform-Dynamic-Objects/config/tools.properties.ORIG

sudo mv /opt/ovc/Platform-Dynamic-Objects/config/tools.properties.$ENV /opt/ovc/Platform-Dynamic-Objects/config/tools.properties


sudo /etc/init.d/jetty restart
