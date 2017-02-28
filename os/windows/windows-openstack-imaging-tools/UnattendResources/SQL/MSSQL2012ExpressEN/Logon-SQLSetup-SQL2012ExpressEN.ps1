#Cmd line, ExpressEN


# SQL 2012 ExpressEN

# COPY all SQLEXPRADV_x64_ENU folder to C:\MSSQLSetup (or: download it; extract it by launching the exe; copy the C:\[GUID] extraction folder into C:\MSSQLSetup; then rename it as C:\MSSQLSetup\SQLEXPRADV_x64_ENU)
# COPY MSSQL2012ExpressEN-ConfigurationFile.ini to C:\MSSQLSetup
# COPY MSSQL2012ExpressEN-ConfigSSMS.ini to C:\MSSQLSetup
# COPY MSSQL2012ExpressEN-FinalizeConfig.ini to C:\MSSQLSetup
# COPY cloudbase-postinitscript-SQL2012ExpressEN.ps1 to "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts"
# CHECK (if not already) ..\SetupLicenseCmds.cmd within C:\Windows\Setup\Scripts\SetupComplete.cmd 
# COPY  (if not already) ..\Logon-Finalize.ps1 to C:\Windows\Temp

C:\MSSQLSetup\SQLEXPRADV_x64_ENU\Setup.exe /ConfigurationFile="C:\MSSQLSetup\MSSQL2012ExpressEN-ConfigurationFile.ini"
# SSMS missing, not sysprep-able ; TO INSTALL AFTERWARDS
C:\MSSQLSetup\SQLEXPRADV_x64_ENU\Setup.exe /ConfigurationFile="C:\MSSQLSetup\MSSQL2012ExpressEN-ConfigSSMS.ini"

# ACTIVATE UPDATES FOR OTHER MICORSOFT PRODUCTS
# CHECK & APPLY UPDATES (Windows, SQL, ...)

# REMOVE MSSQL2012ExpressEN-ConfigurationFile.ini from C:\MSSQLSetup
# reactivate IESC

# <<< TEST >>>>

# MAKE A SNAPSHOT OF THE VM!

C:\Windows\Temp\Logon-Finalize.ps1