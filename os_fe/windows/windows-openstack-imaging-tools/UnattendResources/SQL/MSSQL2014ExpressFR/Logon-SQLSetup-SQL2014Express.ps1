


# SQL 2014 Express

# INSTALL .NET Framework 3.5 Windows Feature prior to SQL install !
# COPY all SQLEXPRADV_x64_FRA folder to C:\MSSQLSetup (or download it)
# COPY MSSQL2014Express-ConfigurationFile.ini to C:\MSSQLSetup
# COPY MSSQL2014Express-FinalizeConfig.ini to C:\MSSQLSetup
# COPY cloudbase-postinitscript-SQL2014Express.ps1 to "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts"
# CHECK (if not already) ..\SetupLicenseCmds.cmd within C:\Windows\Setup\Scripts\SetupComplete.cmd 
# COPY  (if not already) ..\Logon-Finalize.ps1 to C:\Windows\Temp

C:\MSSQLSetup\SQLEXPRADV_x64_FRA\Setup.exe /ConfigurationFile="C:\MSSQLSetup\MSSQL2014Express-ConfigurationFile.ini"

# ACTIVATE UPDATES FOR OTHER MICORSOFT PRODUCTS
# CHECK & APPLY UPDATES (Windows, SQL, ...)

# REMOVE MSSQL2014Express-ConfigurationFile.ini from C:\MSSQLSetup
# reactivate IESC

# MAKE A SNAPSHOT OF THE VM!

C:\Windows\Temp\Logon-Finalize.ps1