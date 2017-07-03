#Cmd line


# SQL 2012 Evaluation

# ??? INSTALL .NET Framework 3.5 Windows Feature prior to SQL install ????
# COPY SQLFULL_FRA.iso to C:\MSSQLSetup (or download it)
# COPY MSSQL2012StandardEN-ConfigurationFile.ini and MSSQL2012StandardEN-SSMS.ini to C:\MSSQLSetup
# COPY MSSQL2012StandardEN-FinalizeConfig.ini to C:\MSSQLSetup
# COPY cloudbase-postinitscript-SQL2012StandardEN.ps1 to "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts"
# CHECK (if not already) ..\..\SetupLicenseCmds.cmd within C:\Windows\Setup\Scripts\SetupComplete.cmd 
# COPY  (if not already) ..\..\Logon-Finalize.ps1 to C:\Windows\Temp

Mount-DiskImage -ImagePath C:\MSSQLSetup\SW_DVD9_SQL_Svr_Standard_Edtn_2012_English_MLF_X17-97001.iso
D:\Setup.exe /ConfigurationFile="C:\MSSQLSetup\MSSQL2012StandardEN-ConfigurationFile.ini"
# SSMS missing, not sysprep-able ; TO INSTALL AFTERWARDS
D:\Setup.exe /ConfigurationFile="C:\MSSQLSetup\MSSQL2012StandardEN-ConfigSSMS.ini"

# ACTIVATE UPDATES FOR OTHER MICORSOFT PRODUCTS
# CHECK & APPLY UPDATES (Windows, SQL, ...)

# REMOVE MSSQL2012Eval-ConfigurationFile.ini from C:\MSSQLSetup
# reactivate IESC

# MAKE A SNAPSHOT OF THE VM!

C:\Windows\Temp\Logon-Finalize.ps1