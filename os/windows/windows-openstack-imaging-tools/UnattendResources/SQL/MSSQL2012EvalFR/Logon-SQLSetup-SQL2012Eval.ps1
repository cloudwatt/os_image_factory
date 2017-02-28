#Cmd line


# SQL 2012 Evaluation

# INSTALL .NET Framework 3.5 Windows Feature prior to SQL install 
# COPY SQLFULL_FRA.iso to C:\MSSQLSetup (or download it)
# COPY MSSQL2012Eval-ConfigurationFile.ini to C:\MSSQLSetup
# COPY MSSQL2012Eval-FinalizeConfig.ini to C:\MSSQLSetup
# COPY cloudbase-postinitscript-SQL2012Eval.ps1 to "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts"
# CHECK (if not already) ..\SetupLicenseCmds.cmd within C:\Windows\Setup\Scripts\SetupComplete.cmd 
# COPY  (if not already) ..\Logon-Finalize.ps1 to C:\Windows\Temp

Mount-DiskImage -ImagePath C:\MSSQLSetup\SQLFULL_FRA.iso
D:\Setup.exe /ConfigurationFile="C:\MSSQLSetup\MSSQL2012Eval-ConfigurationFile.ini"
# SSMS missing, not sysprep-able ; TO INSTALL AFTERWARDS
D:\Setup.exe /ConfigurationFile="C:\MSSQLSetup\MSSQL2012Eval-ConfigSSMS.ini"

# ACTIVATE UPDATES FOR OTHER MICORSOFT PRODUCTS
# CHECK & APPLY UPDATES (Windows, SQL, ...)

# REMOVE MSSQL2012Eval-ConfigurationFile.ini from C:\MSSQLSetup
# reactivate IESC

# MAKE A SNAPSHOT OF THE VM!

C:\Windows\Temp\Logon-Finalize.ps1