#Cmd line, Express


# SQL 2012 Express

# COPY all SQLEXPRADV_x64_FRA folder to C:\MSSQLSetup (or download it)
# COPY MSSQL2012Express-ConfigurationFile.ini to C:\MSSQLSetup
# COPY MSSQL2012Express-FinalizeConfig.ini to C:\MSSQLSetup
# COPY cloudbase-postinitscript-SQL2012Express.ps1 to "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts"
# CHECK (if not already) ..\SetupLicenseCmds.cmd within C:\Windows\Setup\Scripts\SetupComplete.cmd 
# COPY  (if not already) ..\Logon-Finalize.ps1 to C:\Windows\Temp

C:\MSSQLSetup\SQLEXPRADV_x64_FRA\Setup.exe /ConfigurationFile="C:\MSSQLSetup\MSSQL2012Express-ConfigurationFile.ini"
# SSMS missing, not sysprep-able ; TO INSTALL AFTERWARDS
C:\MSSQLSetup\SQLEXPRADV_x64_FRA\Setup.exe /ConfigurationFile="C:\MSSQLSetup\MSSQL2012Express-ConfigSSMS.ini"

# ACTIVATE UPDATES FOR OTHER MICORSOFT PRODUCTS
# CHECK & APPLY UPDATES (Windows, SQL, ...)

# REMOVE MSSQL2012Express-ConfigurationFile.ini from C:\MSSQLSetup
# reactivate IESC

# <<< TEST >>>>

# MAKE A SNAPSHOT OF THE VM!

C:\Windows\Temp\Logon-Finalize.ps1