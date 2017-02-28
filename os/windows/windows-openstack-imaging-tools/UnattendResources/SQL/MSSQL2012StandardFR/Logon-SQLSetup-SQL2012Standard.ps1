#Cmd line


# SQL 2012 Evaluation

# ??? INSTALL .NET Framework 3.5 Windows Feature prior to SQL install ????
# COPY SQLFULL_FRA.iso to C:\MSSQLSetup (or download it)
# COPY MSSQL2012Standard-ConfigurationFile.ini and MSSQL2012Standard-SSMS.ini to C:\MSSQLSetup
# COPY MSSQL2012Standard-FinalizeConfig.ini to C:\MSSQLSetup
# COPY cloudbase-postinitscript-SQL2012Standard.ps1 to "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts"
# CHECK (if not already) ..\..\SetupLicenseCmds.cmd within C:\Windows\Setup\Scripts\SetupComplete.cmd 
# COPY  (if not already) ..\..\Logon-Finalize.ps1 to C:\Windows\Temp

Mount-DiskImage -ImagePath C:\MSSQLSetup\SW_DVD9_SQL_Svr_Standard_Edtn_2012w_SP3_64Bit_French_MLF_X20-66862.iso
D:\Setup.exe /ConfigurationFile="C:\MSSQLSetup\MSSQL2012Standard-ConfigurationFile.ini"
# SSMS missing, not sysprep-able ; TO INSTALL AFTERWARDS
D:\Setup.exe /ConfigurationFile="C:\MSSQLSetup\MSSQL2012Standard-ConfigSSMS.ini"

# ACTIVATE UPDATES FOR OTHER MICORSOFT PRODUCTS
# CHECK & APPLY UPDATES (Windows, SQL, ...)

# REMOVE MSSQL2012Eval-ConfigurationFile.ini from C:\MSSQLSetup
# reactivate IESC

# MAKE A SNAPSHOT OF THE VM!

C:\Windows\Temp\Logon-Finalize.ps1