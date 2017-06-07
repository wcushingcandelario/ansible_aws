#!/bin/bash
java -cp "/opt/ovc/lib/*":"/opt/ovc/lib/ext/*" com.oneview.tools.posmclient.UnifiedImporterAndSyncUpdater "/opt/ovc/Platform-Dynamic-Objects/config/tools.properties" "/opt/ovc/Base-Location-Import-Files/ovc-all-OvcStore" "/opt/ovc/Application-Dynamic-Objects" eCommit
