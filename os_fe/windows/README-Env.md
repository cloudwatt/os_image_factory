# Environnement de travail Windows pour Cloudwatt


L'environnement de travail Windows pour Cloudwatt est principalement composé de la Workstation Windows - qui est une VM Windows déployée (sur Cloudwatt, si vous le souhaitez) contenant la majorité des artefacts nécessaires pour créer et maintenir :

- des images Windows Server de base
- des images dérivées de Windows Server (comme SQL Server)
- des bundles basées sur Windows (comme RDS)

Une instance de cette machine a été créée et utilisée pendant les travaux Windows sur Cloudwatt de l'année 2016. On pourra soit l'utiliser dans l'état (si disponible), instancier une nouvelle VM à partir de la sauvegarde.

## Structure de la machine de travail
La machine de travail sera une VM standard 1 vCPU minimum / 50 GB HDD :

![La VM Workstation](images/workstation-mza.png)

- Image de base : Windows Server 2012 R2 EN. Une image ultérieure pourra être choisie; mais les versions des composants et logiciels à utiliser seront a revoir.
- Disques :

    - disque OS (venu avec la VM)
    - un disque standard supplémentaire, de taille 1 TO minimum recommandé.

### Structure des dossiers de travail

TODO

## Composants et logiciels

Pour travailler dans l'environnement Windows, les composants et logiciels suivants sont nécessaires :

1. **Git for Windows** : Très utile pour au moins 2 raisons :

- Client Git pour travailler avec le code source depuis Windows 
- Inclut une console Bash qui permet de travailler quasiment comme dans un environnement Linux (y compris avec le client Openstack)

2. **Python / PIP** : Installer directement via la console Git Bash.
3. **Client Openstack** :
Installer via la console Git Bash et PIP. 
Ensuite, après avoir récupéré les paramètres EXPORT Cloudwatt et les avoir exécutés dans la console Git Bash,  vous serez alors connecté à votre tenant Cloudwatt. 

4. **Windows PowerShell et Windows PowerShell ISE** :
Tous les processus de travail spécifiques Windows s'exécutent et sont automatisés via PowerShell. 

   Windows Powershell ISE (Integrated Scripting Environment) est un environnement de développement léger inclus avec PowerShell et qui permet l'édition rapide, ainsi que l'exécution pas à pas (en mode debug) des scripts PowerShell. Toutes les lancements d'exécution de PowerShell pourront se faire soit à partir d'une console PowerShell simple, soit à partir de PowerShell ISE (qui permettra le débuggage en cas de besoin).

   A noter:

    - Powershell et PowerShell ISE sont inclus par défaut dans Windows Server et il n'y a besoin d'aucune installation ou configuration particulière.
    - Pour éviter les risques accès limité au système de fichiers, lancer PowerShell ou PowerShell ISE en mode administrateur.

5. **Notepad++** (ou Visual Studio Code, ou un autre éditeur léger de code) : pour tout autre type de code : scripts Openstack, markdown, txt, ... 



### Références

- [Git for Windows](https://git-for-windows.github.io/)
- [Windows PowerShell](https://technet.microsoft.com/en-us/library/bb978526.aspx)
- [Windows PowerShell ISE](https://msdn.microsoft.com/en-us/powershell/scripting/getting-started/fundamental/windows-powershell-integrated-scripting-environment--ise-)
- Instance VM ou disque Cloudwatt utilisée en 2016 : TODO lien ou ID 


