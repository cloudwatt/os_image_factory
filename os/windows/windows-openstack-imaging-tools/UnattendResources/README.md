# UnattendResources : customisation du dossier

## Fichieres rajoutés ou modifiés

Fichiers rajoutés ou modifiés dans le dossier des ressources :

1. Logon.ps1 [Modifié] :Ce fichier est le script principal qui s'exécute sur la VM de préparation de l'image. Il finit avec un sysprep et arréte la VM.
1. Logon-Finalize.ps1 [Nouveau] Script de finalisation/sysprepé faire exécuter sur une VM de préparation qui a exécuté déjà Logon.ps1 mais sans l'étape de sysprep.
1. SetupLicenseCmds.cmd [Nouveau] : Script de config de volume licensing via VL Server de Cloudwatt. Il sera inclus automatiquement dans [WinDir]\Setup\Scripts\SetupComplete.cmd pour être exécuté ensuite sur chaque setup de VM provisionnée à partir de l'image.
1. Dossier SQL [Nouveau] : Contient all the scripts necessaires pour la création des images spécifiques SQL Server (selon les différentes versions) :
- MSSQL2012Eval
- MSSQL2012ExpressEN
- MSSQL2012ExpressFR
- MSSQL2012StandardEN
- MSSQL2012StandardFR
- MSSQL2014Eval
- MSSQL2014ExpressEN
- MSSQL2014ExpressFR
- MSSQL2014StandardEN
- MSSQL2014StandardFR

(attention, toutes les images correspondantes ne sont pas publiées dans le catalogie d'images Cloudwatt)

## Notes spécifiques - images SQL Server

- Pour chaqun de ces dossiers on inclut un set standard de fichiers (comme pattern, SQLXXXXYYYY correspond par ex. à SQL2012Express) :
  1. cloudbase-postinitscript-SQLXXXXYYYY.ps1
  1. Logon-SQLSetup-SQLXXXXYYYY.ps1
  1. MSSQLXXXXYYYY-ConfigurationFile.ini
  1. MSSQLXXXXYYYY-FinalizeConfig.ini
  1. MSSQL2012ExpressEN-ConfigSSMS.ini (pour SQL2012 uniquement)

- Pour chaqun de ces dossiers on retrouve un fichier nommé typiquement Logon-SQLSetup-SQLXXXXYYYY.ps1 (ex. Logon-SQLSetup-SQL2012Eval.ps1). Ce fichier contient le code et la procedure de travail spécifique pour chaque image.



