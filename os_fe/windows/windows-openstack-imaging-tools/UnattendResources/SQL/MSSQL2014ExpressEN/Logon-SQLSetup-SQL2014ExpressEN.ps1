


# SQL 2014 ExpressEN

# INSTALL .NET Framework 3.5 Windows Feature prior to SQL install !
# COPY all SQLEXPRADV_x64_ENU folder to C:\MSSQLSetup (or: download it; then extract it as C:\MSSQLSetup\SQLEXPRADV_x64_ENU)
# COPY MSSQL2014ExpressEN-ConfigurationFile.ini to C:\MSSQLSetup
# COPY MSSQL2014ExpressEN-FinalizeConfig.ini to C:\MSSQLSetup
# COPY cloudbase-postinitscript-SQL2014ExpressEN.ps1 to "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts"
# CHECK (if not already) ..\SetupLicenseCmds.cmd within C:\Windows\Setup\Scripts\SetupComplete.cmd 
# COPY  (if not already) ..\Logon-Finalize.ps1 to C:\Windows\Temp

C:\MSSQLSetup\SQLEXPRADV_x64_ENU\Setup.exe /ConfigurationFile="C:\MSSQLSetup\MSSQL2014ExpressEN-ConfigurationFile.ini"

# ACTIVATE UPDATES FOR OTHER MICORSOFT PRODUCTS
# CHECK & APPLY UPDATES (Windows, SQL, ...)

# REMOVE MSSQL2014ExpressEN-ConfigurationFile.ini from C:\MSSQLSetup
# reactivate IESC

# MAKE A SNAPSHOT OF THE VM!

C:\Windows\Temp\Logon-Finalize.ps1