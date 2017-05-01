#!/bin/bash
java -Dovc.config.dir="/opt/ovc/Platform-Dynamic-Objects/config" -cp "/opt/ovc/lib/*":"/opt/ovc/lib/POSMClient-Tools-DT.jar":"/opt/ovc/lib/ext/*" com.oneview.tools.posmclient.UnifiedImporterAndSyncUpdater "/opt/ovc/Platform-Dynamic-Objects/config/tools.properties" "/opt/ovc/Base-Location-Import-Files" "/opt/ovc/Application-Dynamic-Objects" eComInit
