#Cmd line


# SQL 2014 Evaluation

# INSTALL .NET Framework 3.5 Windows Feature prior to SQL install !
# COPY SQLServer2014SP2-FullSlipstream-x64-FRA.iso to C:\MSSQLSetup (or download it)
# COPY MSSQL2014Eval-ConfigurationFile.ini to C:\MSSQLSetup
# COPY MSSQL2014Eval-FinalizeConfig.ini to C:\MSSQLSetup
# COPY cloudbase-postinitscript-SQL2014Eval.ps1 to "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts"
# CHECK (if not already) ..\SetupLicenseCmds.cmd within C:\Windows\Setup\Scripts\SetupComplete.cmd 
# COPY  (if not already) ..\Logon-Finalize.ps1 to C:\Windows\Temp

Mount-DiskImage -ImagePath C:\MSSQLSetup\SQLServer2014SP2-FullSlipstream-x64-FRA.iso
D:\Setup.exe /ConfigurationFile="C:\MSSQLSetup\MSSQL2014Eval-ConfigurationFile.ini"

# ACTIVATE UPDATES FOR OTHER MICORSOFT PRODUCTS
# CHECK & APPLY UPDATES (Windows, SQL, ...)

# REMOVE MSSQL2014Eval-ConfigurationFile.ini from C:\MSSQLSetup
# reactivate IESC

# MAKE A SNAPSHOT OF THE VM!

C:\Windows\Temp\Logon-Finalize.ps1