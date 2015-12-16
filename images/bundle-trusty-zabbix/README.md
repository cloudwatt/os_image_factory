# 5 Minutes Stacks, épisode 16 : Zabbix #

## Episode 16 : Zabbix-server

![Minimum setup](http://blog.stack.systems/wp-content/uploads/2015/01/5-passos-instalacao-zabbix-2-4-guia-definitivo.png)

Zabbix est un logiciel libre permettant de surveiller l'état de divers services réseau, serveurs et autres matériels réseau; et produisant des graphiques dynamiques de consommation des ressources. Zabbix utilise MySQL, PostgreSQL ou Oracle pour stocker les données. Selon l'importance du nombre de machines et de données à surveiller, le choix du SGBD influe grandement sur les performances. Son interface web est écrite en PHP et fourni un vision temps réel sur les métriques collectées.

Zabbix-server dans un réseau se présente comme suit:

![Architecture réseau zabbix](http://image.slidesharecdn.com/zabbixfeaturesin5pictures-03-150131052309-conversion-gate02/95/zabbix-monitoring-in-5-pictures-2-638.jpg?cb=1440581062)

On remarque dans cette architecture résau que le serveur Zabbix-serveur peut monitorer les hotes sur lesquels sont installés le daemon zabbix-agents ou SNMP ( le daemon zabbix-server peut être installé sur les serveurs, les ordinateurs; et le daemon SNMP peut être installé sur les equipements tel que les routeurs, les imprimantes... ).

### Les versions

* Ubuntu 14.04
* Zabbix 2.2
* Mysql  5.5

### Les pré-requis pour déployer cette stack

* un accès internet
* un shell Linux
* un [compte Cloudwatt](https://www.cloudwatt.com/authentification), avec une [paire de clés existante](https://console.cloudwatt.com/project/access_and_security/?tab=access_security_tabs__keypairs_tab)
* les outils [OpenStack CLI](http://docs.openstack.org/cli-reference/content/install_clients.html)
* un clone local du dépôt git [Cloudwatt applications](https://github.com/cloudwatt/applications)

### Taille de l'instance

Par défaut, le script propose un déploiement sur une instance de type "Small" (s1.cw.small-1) en tarification à l'usage (les prix à l'heure et au mois sont disponibles sur la [page Tarifs](https://www.cloudwatt.com/fr/produits/tarifs.html) du site de Cloudwatt). Bien sûr, vous pouvez ajuster les paramètres
de la stack, et en particulier sa taille par défaut.

### Au fait...

Si vous n’aimez pas les lignes de commande, vous pouvez passer directement à la version « lancement par la console » en cliquant sur [ce lien](#console)

## Tour du propriétaire

Une fois le dépôt git cloné, vous trouvez plusieurs fichiers dans le répertoire `images/bundle-trusty-zabbix/`:

* `bundle-trusty-zabbix.heat.yml` : Template d'orchestration HEAT, qui va servir à déployer l'infrastructure nécessaire.
* `stack-start.sh` : Script de lancement de la stack. C'est un micro-script pour vous économiser quelques copier-coller.
* `stack-get-url.sh` : Script de récupération de l'IP d'entrée de votre stack.


## Démarrage

### Initialiser l'environnement

Munissez-vous de vos identifiants Cloudwatt, et cliquez [ICI](https://console.cloudwatt.com/project/access_and_security/api_access/openrc/). Si vous n'êtes pas connecté, vous passerez par l'écran d'authentification, puis le téléchargement d'un script démarrera. C'est grâce à celui-ci que vous pourrez initialiser les accès shell aux API Cloudwatt.

Sourcez le fichier téléchargé dans votre shell. Votre mot de passe vous sera demandé.

~~~ bash
$ source COMPUTE-[...]-openrc.sh
Please enter your OpenStack Password:

~~~

Une fois ceci fait, les outils ligne de commande OpenStack peuvent interagir avec votre compte Cloudwatt.

### Ajuster les paramètres

Dans le fichier `bundle-trusty-zabbix.heat.yml` vous trouverez en haut une section `parameters`. Le seul paramètre obligatoire à ajuster
est celui nommé `keypair_name` dont la valeur `default` doit contenir le nom d'une paire de clés valide dans votre compte utilisateur.
C'est dans ce même fichier que vous pouvez ajuster la taille de l'instance par le paramètre `flavor`.

~~~ yaml
heat_template_version: 2013-05-23

description: All-in-one Zabbix stack

parameters:
  keypair_name:
    default:                                              <-- Mettez ici le nom de votre paire de clés
    description: Keypair to inject in instance
    label: SSH Keypair
    type: string

  flavor_name:
    default: s1.cw.small-1                                    <-- Mettez ici l'identifiant de votre flavor
    description: Flavor to use for the deployed instance
    type: string
    label: Instance Type (Flavor)
    constraints:
      - allowed_values:
        - t1.cw.tiny
        - s1.cw.small-1
         [...]
~~~

### Démarrer la stack

Dans un shell, placez vous dans votre dossier cloné et lancez le script `stack-start.sh` en passant en paramètre le nom que vous souhaitez lui attribuer :

~~~
./stack-start.sh nom_de_votre_stack
~~~
Exemple :

```
$ ./stack-start.sh EXP_STACK
+--------------------------------------+-----------------+--------------------+----------------------+
| id                                   | stack_name      | stack_status       | creation_time        |
+--------------------------------------+-----------------+--------------------+----------------------+
| ee873a3a-a306-4127-8647-4bc80469cec4 | EXP_STACK       | CREATE_IN_PROGRESS | 2015-11-25T11:03:51Z |
+--------------------------------------+-----------------+--------------------+----------------------+
```

Puis attendez 5 minutes que le déploiement soit complet.


```
$ heat resource-list EXP_STACK
+------------------+-----------------------------------------------------+---------------------------------+-----------------+----------------------+
| resource_name    | physical_resource_id                                | resource_type                   | resource_status | updated_time         |
+------------------+-----------------------------------------------------+---------------------------------+-----------------+----------------------+
| floating_ip      | 44dd841f-8570-4f02-a8cc-f21a125cc8aa                | OS::Neutron::FloatingIP         | CREATE_COMPLETE | 2015-11-25T11:03:51Z |
| security_group   | efead2a2-c91b-470e-a234-58746da6ac22                | OS::Neutron::SecurityGroup      | CREATE_COMPLETE | 2015-11-25T11:03:52Z |
| network          | 7e142d1b-f660-498d-961a-b03d0aee5cff                | OS::Neutron::Net                | CREATE_COMPLETE | 2015-11-25T11:03:56Z |
| subnet           | 442b31bf-0d3e-406b-8d5f-7b1b6181a381                | OS::Neutron::Subnet             | CREATE_COMPLETE | 2015-11-25T11:03:57Z |
| server           | f5b22d22-1cfe-41bb-9e30-4d089285e5e5                | OS::Nova::Server                | CREATE_COMPLETE | 2015-11-25T11:04:00Z |
| floating_ip_link | 44dd841f-8570-4f02-a8cc-f21a125cc8aa-`floatting IP` | OS::Nova::FloatingIPAssociation | CREATE_COMPLETE | 2015-11-25T11:04:30Z |
+------------------+-----------------------------------------------------+---------------------------------+-----------------+----------------------
```

Le script `start-stack.sh` s'occupe de lancer les appels nécessaires sur les API Cloudwatt pour :

* démarrer une instance basée sur Debian Jessie, pré-provisionnée avec la stack Zabbix-serveur, zabbix-agent,lamp,
* l'exposer sur Internet via une IP flottante

### Enjoy

Une fois tout ceci fait, vous pouvez lancez le script `stack-get-url.sh` qui va récupérer l'url d'entrée de votre stack.

Exemple:

```
$ ./stack-get-url.sh EXP_STACK
EXP_STACK `floatting IP `
```

A ce niveau, vous pouvez vous connecter sur votre instance de serveur Zabbix avec un navigateur web en pointant sur votre floatting IP, sur le port 80 (http://xx.xx.xx.xx). Pour s'authentifier sur l'interface web :

* login : admin
* mot de passe : zabbix

![Interface connection zabbix](https://cdn-02.memo-linux.com/wp-content/uploads/2015/03/zabbix-07-300x253.png)

Une fois que l'authentication est faite, vous avez access à l'interface graphique de Zabbix-serveur.

![Bigger production setup](https://cdn-02.memo-linux.com/wp-content/uploads/2015/03/zabbix-08-300x276.png)



### Pour monitorer plus de  machines

Il faut s'assurer que les machines à monitorer :

* sont visible sur le réseau depuis le serveur Zabbix-serveur
* ont un agent zabbix fonctionnel
* ont un daemon SNMP fonctionnel ( pour les hôtes différents des ordinateurs)
* acceptent les communications UDP entrantes sur les ports 161 (port d'échanges d'informations avec le protocole SNMP), 123 (port de synchronisation du server NTP), 1051 ( port d'écoute du serveur Zabbix) et 1051 ( port d'écoute de l'agent Zabbix).


### Exemple de monitoring d'un serveur Ghost

Voyons ensemble un exemple d'intégration d'une instance serveur portant le moteur de blog Ghost.

  * Déployez une stack Ghost [comme nous l'avions vu à l'épisode5](https://dev.cloudwatt.com/fr/blog/5-minutes-stacks-episode-cinq-ghost.html).

  * Depuis la section [Accès et Sécurité de la console Cloudwatt](https://console.cloudwatt.com/project/access_and_security/), ajoutez 2 règles au groupe de sécurité de la stack Ghost :
      * Règle UDP personnalisée, en Entrée, Port 161
      * Règle UDP personnalisée, en Entrée, Port 123
      * Règle UDP personnalisée, en Entrée, Port 1050
      * Règle TCP personnalisée, en Entrée, Port 1050

Cela permettra au serveur Zabbix de se connecter pour récupérer les métriques de la machine. Il faut maintenant créer de la visibilité réseau entre notre stack Zabbix et notre stack Ghost, via la création d'un routeur Neutron :

  1. Récupérez l'identifiant de sous-réseau de la stack Ghost :

  ```
  $ heat resource-list $NOM_DE_STACK_GHOST | grep subnet

  | subnet           | bd69c3f5-ddc8-4fe4-8cbe-19ecea0fdf2c              | OS::Neutron::Subnet             | CREATE_COMPLETE | 2015-11-24T15:18:30Z |
  ```

  2. Récupérez l'identifiant de sous-réseau de la stack Zabbix :

  ```
  $ heat resource-list $NOM_DE_STACK_Zabbix | grep subnet

  | subnet           | babdd078-ddc8-4280-8cbe-0f77951a5933              | OS::Neutron::Subnet             | CREATE_COMPLETE | 2015-11-24T15:18:30Z |
  ```

  3. Créez un router tout neuf :

    ```
    $ neutron router-create Zabbix_GHOST

    Created a new router:
    +-----------------------+--------------------------------------+
    | Field                 | Value                                |
    +-----------------------+--------------------------------------+
    | admin_state_up        | True                                 |
    | external_gateway_info |                                      |
    | id                    | babdd078-c0c6-4280-88f5-0f77951a5933 |
    | name                  | Zabbix_GHOST                        |
    | status                | ACTIVE                               |
    | tenant_id             | 8acb072da1b14c61b9dced19a6be3355     |
    +-----------------------+--------------------------------------+
    ```

  4. Ajoutez au routeur une interface sur le sous-réseau de la stack Ghost et une sur le sous-réseau de la stack Zabbix :

    ```
    $ neutron router-interface-add $Zabbix_GHOST_ROUTER_ID $Zabbix_SUBNET_ID

    $ neutron router-interface-add $Zabbix_GHOST_ROUTER_ID $GHOST_SUBNET_ID

    ```

  Quelques minutes plus tard, le serveur Zabbix et le serveur Ghost pourront se contacter directement. Afin de vous fournir une "documentation exécutable"
  de l'intégration d'un serveur Ubuntu, nous utiliserons Ansible pour la suite.

  5. Assurez vous de pouvoir vous connecter :
      * en SSH
      * en utilisateur `cloud`
      * sur le serveur Ghost
      * depuis le serveur Zabbix

  6. Sur le serveur Zabbix, ajoutez les informations de connexion dans l'inventaire `/etc/ansible/hosts` :

  ```         
  [...]

  [slaves]
  xx.xx.xx.xx ansible_ssh_user=cloud ansible_ssh_private_key_file=/home/cloud/.ssh/id_rsa_ghost_server.pem

  [...]
  ```

  7. En root sur le serveur Zabbix, lancez le playbook `slave-monitoring_zabbix.yml` :
  ```
  # ansible-playbook /root/slave-monitoring_zabbix.yml
  ```

Le playbook en question va faire toutes les opérations d'installations et de configurations sur le serveur Ghost pour l'intégrer au serveur     Zabbix.                                                                                                                                      Pour que votre host (serveur Ghost ici), puisse être pris en compte par le serveur Zabbix, il vous faut faire les operations suivantes :

   * Se connecter à l'interface web de Zabbix-serveur
   * Cliquer sur le menu `configuration`
   * Cliquer sur le sous menu `Hosts`
   * Cliquer sur la fenêtre en haut à droit ` Create Host `

 ![Bigger production ](http://tecadmin.net/wp-content/uploads/2013/10/add-zabbix-host-1.png)

 Depuis l'onglet template, renseigner les champs suivants:

   *  ` Enter Hostname`: Nom d'hôte
   *  `Visible name`: Nom à l'affichage dans zabbix
   *  `Group`: Sélectionnez le groupe désiré pour votre hôte
   *  `Agent interface`: Complétez les informations de l'agent Zabbix tournant sur l'hôte.
   *  `Status`: Sélectionnez l'état initial

 ![Bigger production ](http://tecadmin.net/wp-content/uploads/2013/10/add-zabbix-host-2.png)

   *  Cliquer sur `add`
   *  Sélectionner le template souhaité
   *  Cliquer sur `save `

 ![Bigger production ](http://tecadmin.net/wp-content/uploads/2013/10/add-zabbix-host-3.png)  


 ![Bigger production ](http://tecadmin.net/wp-content/uploads/2013/10/add-zabbix-host-4.png)  

   Congratulation! vous pouvez visualiser les métriques des agents monitorés par le serveur Zabbix.

 ![Bigger production ](http://tecadmin.net/wp-content/uploads/2013/10/graph-network.png)


<a name="console" />

### C’est bien tout ça, mais vous n’auriez pas un moyen de lancer l’application par la console ?

Et bien si ! En utilisant la console, vous pouvez déployer un serveur Zabbix :

1.	Allez sur le Github Cloudwatt dans le répertoire applications/bundle-trusty-zabbix
2.	Cliquez sur le fichier nommé bundle-trusty-zabbix.heat.yml
3.	Cliquez sur RAW, une page web apparait avec le détail du script
4.	Enregistrez-sous le contenu sur votre PC dans un fichier avec le nom proposé par votre navigateur (enlever le .txt à la fin)
5.  Rendez-vous à la section « [Stacks](https://console.cloudwatt.com/project/stacks/) » de la console.
6.	Cliquez sur « Lancer la stack », puis cliquez sur « fichier du modèle » et sélectionnez le fichier que vous venez de sauvegarder sur votre PC, puis cliquez sur « SUIVANT »
7.	Donnez un nom à votre stack dans le champ « Nom de la stack »
8.	Entrez votre keypair dans le champ « keypair_name »
9.	Choisissez la taille de votre instance parmi le menu déroulant « flavor_name » et cliquez sur « LANCER »

La stack va se créer automatiquement (vous pouvez en voir la progression cliquant sur son nom). Quand tous les modules deviendront « verts », la création sera terminée. Vous pourrez alors aller dans le menu « Instances » pour découvrir l’IP flottante qui a été générée automatiquement. Ne vous reste plus qu’à lancer votre IP dans votre navigateur.

Pour rappel, voici les ports par défaut où répondent les rôles Zabbix-server :

    Port d'écoute du trapper : 1051
    Port d'écoute de l'agent zabbix: 10050
    Port de la base de données lorsque le socket local n'est pas utilisé : 3306
    Interface web de gestion de Zabbix-server : 8O


## So watt ?

Ce tutoriel a pour but d'accélerer votre démarrage. A ce stade vous êtes maître(sse) à bord.

Vous avez un point d'entrée sur votre machine virtuelle en SSH via l'IP flottante exposée et votre clé privée (utilisateur `cloud` par défaut).

Vous pouvez commencer à faire vivre votre monitoring en prenant la main sur votre serveur. Les points d'entrée utiles :

* `/etc/default/zabbix-server`: le répertoire contenant le fichier de configuation zabbix-server
* `/etc/zabbix/zabbix_server.conf`: le répertoire contenant le fichier de configuration permettant à Zabbix-server de se connecter à la base de données
* `/usr/share/zabbix-server-mysql/`: le répertoire contenant les fichiers de la base de donnée de zabbix-server-mysql
* `/var/log/zabbix-server/zabbix_server.log`: le répertoire contenant les log.
* `/etc/apache2/sites-available/`: le repertoire contenant le fichier de configuration de l’interface web de gestion de Zabbix.
* ` /etc/php5/apache2/php.ini`: le repertoire contenant le fichier de configuration de php (php.ini) pour les pré-requis de l'installation de Zabbix
* `/etc/zabbix/zabbix.conf.php`: le repertoire contenant  le fichier de configuration de l'interface zabbix

#### Autres sources pouvant vous interesser:

* [Zabbix-monitoring Homepage](http://www.zabbix.com/)
* [Zabbix Solutions - Index](http://wiki.monitoring-fr.org/zabbix/zabbix-use)
* [Zabbix tutorial](http://sensors.egnite.de/en/climate-monitoring-querx-th-zabbix/3/)
* [Zabbix communauté](http://www.monitoring-fr.org/solutions/zabbix/)
* [Zabbix documentation Ubuntu documentation](https://doc.ubuntu-fr.org/zabbix)
* [Zabbix documentation ](https://www.zabbix.com/documentation/1.8/fr/manual/processes)
* [Zabbix blog ](http://tecadmin.net/add-host-zabbix-server-monitor/)

-----
Have fun. Hack in peace.
