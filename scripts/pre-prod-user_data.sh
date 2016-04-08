#!/bin/bash

export ENV=pre-prod

mv /opt/ovc/Platform-Dynamic-Objects/config/unifiedConfig.properties /opt/ovc/Platform-Dynamic-Objects/config/unifiedConfig.properties.ORIG

mv /opt/ovc/Platform-Dynamic-Objects/config/unifiedConfig.properties.$ENV /opt/ovc/Platform-Dynamic-Objects/config/unifiedConfig.properties


mv /opt/ovc/Platform-Dynamic-Objects/config/tools.properties /opt/ovc/Platform-Dynamic-Objects/config/tools.properties.ORIG

mv /opt/ovc/Platform-Dynamic-Objects/config/tools.properties.$ENV /opt/ovc/Platform-Dynamic-Objects/config/tools.properties


/etc/init.d/jetty restart
