C:\Windows\System32\tzutil.exe /s "UTC"
net stop w32time
w32tm /unregister
w32tm /register
net start w32time
w32tm /config /manualpeerlist:"time.nist.gov" 
w32tm /resync
C:\Windows\System32\cscript.exe C:\Windows\System32\slmgr.vbs /skms 185.23.94.246
C:\Windows\System32\cscript.exe C:\Windows\System32\slmgr.vbs /ato

C:\MSSQLSetup\SQLEXPRADV_x64_FRA\Setup.exe /ConfigurationFile="C:\MSSQLSetup\MSSQL2014Express-FinalizeConfig.ini"

