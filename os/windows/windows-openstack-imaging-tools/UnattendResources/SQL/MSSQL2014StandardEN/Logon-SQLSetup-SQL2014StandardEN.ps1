#Cmd line


# SQL 2014 StandardEN

# INSTALL .NET Framework 3.5 Windows Feature prior to SQL install !
# COPY SQLServer2014SP2-FullSlipstream-x64-FRA.iso to C:\MSSQLSetup (or download it)
# COPY MSSQL2014StandardEN-ConfigurationFile.ini to C:\MSSQLSetup
# COPY MSSQL2014StandardEN-FinalizeConfig.ini to C:\MSSQLSetup
# COPY cloudbase-postinitscript-SQL2014StandardEN.ps1 to "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts"
# CHECK (if not already) ..\SetupLicenseCmds.cmd within C:\Windows\Setup\Scripts\SetupComplete.cmd 
# COPY  (if not already) ..\Logon-Finalize.ps1 to C:\Windows\Temp

Mount-DiskImage -ImagePath C:\MSSQLSetup\SW_DVD9_SQL_Svr_Standard_Edtn_2014_64Bit_English_MLF_X19-34513.iso
D:\Setup.exe /ConfigurationFile="C:\MSSQLSetup\MSSQL2014StandardEN-ConfigurationFile.ini"

# ACTIVATE UPDATES FOR OTHER MICORSOFT PRODUCTS
# CHECK & APPLY UPDATES (Windows, SQL, ...)

# REMOVE MSSQL2014StandardEN-ConfigurationFile.ini from C:\MSSQLSetup
# reactivate IESC

# MAKE A SNAPSHOT OF THE VM!

C:\Windows\Temp\Logon-Finalize.ps1