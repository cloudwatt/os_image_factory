# 5 Minutes Stacks, épisode 15 : Shinken #

## Episode 15 : Shinken-server

![Minimum setup](http://www.samuelpoggioli.fr/wp-content/uploads/2014/12/Shinken-624x192.jpg)

Shinken est une application permettant la surveillance système et réseau.
Elle surveille les hôtes et services spécifiés, alertant lorsque les systèmes
vont mal et quand ils vont mieux. C'est un logiciel libre sous licence GNU AGPL.
Elle est complètement compatible avec le logiciel Nagios et elle a pour but
d'apporter une supervision distribuée et hautement disponible facile à mettre en
place.
La base de déploiement est une instance Debian Jessie. Le serveur shinken,
l'interface graphique webui (apporte de l'interface graphique sur shinken ),
la base de données SQlitedb sont déployés dans une instance unique. De la machine
qui heberge le serveur shinken, vous pouvez lancer le déployement de la configuration
des machines à monitorer.



### Les versions

* Debian Jessie 8.2
* shinken 2.4.2
* SQlitedb 3.8.2

### Les pré-requis pour déployer cette stack

* un accès internet
* un shell Linux
* un [compte Cloudwatt](https://www.cloudwatt.com/authentification), avec une [paire de clés existante](https://console.cloudwatt.com/project/access_and_security/?tab=access_security_tabs__keypairs_tab)
* les outils [OpenStack CLI](http://docs.openstack.org/cli-reference/content/install_clients.html)
* un clone local du dépôt git [Cloudwatt applications](https://github.com/cloudwatt/applications)

### Taille de l'instance

Par défaut, le script propose un déploiement sur une instance de type " Small " (s1.cw.small-1) en tarification à l'usage (les prix à l'heure et au mois sont disponibles sur la [page Tarifs](https://www.cloudwatt.com/fr/produits/tarifs.html) du site de Cloudwatt). Bien sur, vous pouvez ajuster les parametres de la stack et en particulier sa taille par défaut.

### Au fait...

Si vous n’aimez pas les lignes de commande, vous pouvez passer directement à la version « lancement par la console » en cliquant sur [ce lien](#console)

## Tour du propriétaire

Une fois le repository cloné, vous trouvez, dans le répertoire `bundle-trusty-shinken/`:

* `bundle-trusty-shinken.heat.yml` : Template d'orchestration HEAT, qui va servir à déployer l'infrastructure nécessaire.
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

Dans le fichier `bundle-trusty-shinken.heat.yml` vous trouverez en haut une section `parameters`. Le seul paramètre obligatoire à ajuster
est celui nommé `keypair_name` dont la valeur `default` doit contenir le nom d'une paire de clés valide dans votre compte utilisateur.
C'est dans ce même fichier que vous pouvez ajuster la taille de l'instance par le paramètre `flavor`.

~~~ yaml

heat_template_version: 2013-05-23


description: All-in-one Shinken stack


parameters:
  keypair_name:
    default: buildshinken                             <-- Mettez ici le nom de votre paire de clés
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



Dans un shell, placer vous dans votre dossier cloné (`$ cd ~/os_image_factory/images/bundle-trusty-shinken`) et lancer le script `stack-start.sh` en passant en paramètre le nom que vous souhaitez lui attribuer :

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

Enfin, attendez 5 minutes que le déploiement soit complet.

```
$ heat resource-list EXP_STACK
+------------------+---------------------------------------------------+---------------------------------+-----------------+----------------------+
| resource_name    | physical_resource_id                              | resource_type                   | resource_status | updated_time         |
+------------------+---------------------------------------------------+---------------------------------+-----------------+----------------------+
| floating_ip      | 44dd841f-8570-4f02-a8cc-f21a125cc8aa                | OS::Neutron::FloatingIP         | CREATE_COMPLETE | 2015-11-25T11:03:51Z |
| security_group   | efead2a2-c91b-470e-a234-58746da6ac22                | OS::Neutron::SecurityGroup      | CREATE_COMPLETE | 2015-11-25T11:03:52Z |
| network          | 7e142d1b-f660-498d-961a-b03d0aee5cff                | OS::Neutron::Net                | CREATE_COMPLETE | 2015-11-25T11:03:56Z |
| subnet           | 442b31bf-0d3e-406b-8d5f-7b1b6181a381                | OS::Neutron::Subnet             | CREATE_COMPLETE | 2015-11-25T11:03:57Z |
| server           | f5b22d22-1cfe-41bb-9e30-4d089285e5e5                | OS::Nova::Server                | CREATE_COMPLETE | 2015-11-25T11:04:00Z |
| floating_ip_link | 44dd841f-8570-4f02-a8cc-f21a125cc8aa-`floatting IP` | OS::Nova::FloatingIPAssociation | CREATE_COMPLETE | 2015-11-25T11:04:30Z |
+------------------+---------------------------------------------------+---------------------------------+-----------------+----------------------
```

Le script `start-stack.sh` s'occupe de lancer les appels nécessaires sur les API Cloudwatt pour :

* démarrer une instance basée sur Debian Jessie, pré-provisionnée avec la stack shinken, webui, sqlitedb
* l'exposer sur Internet via une IP flottante

### Enjoy

Une fois tout ceci fait, vous pouvez lancez le script `stack-get-url.sh` qui va récupérer l'url d'entrée de votre stack.

Exemple:

```
$ ./stack-get-url.sh EXP_STACK
EXP_STACK `floatting IP `
```

* A ce niveau, vous pouvez vous connecter sur votre navigateur web avec votre floatting IP, sur le port 7767 (http://xx.xx.xx.xx:7767)
   Pour s'authentifier sur l'interface web: (login: admin  et le mot de passe: admin)

![Interface connection shinken](https://mescompetencespro.files.wordpress.com/2012/12/authentification-shinken.png)

Un fois l'authentication est faite, cliquez sur l'onglet 'ALL' pour voir les différentes métriques monitorées par shinken

![Bigger production setup](http://shinken.readthedocs.org/en/latest/_images/shinken_webui.png)

* Vous pouvez enrichir votre `Dashboard` avec des widgets comme suit:

![Bigger production ](http://shinkenlab.io/images/course2/course2-dasboardfilled.png)

 Bravo !!! Vous pouvez visualiser les métriques monitorées par shinken-server.



### Pour monitorer plus de  machines

  Il faut s'assurer que les machines à monitorer sont :
   - en visibilité dans le réseau
   - l'agent SNMP est bien installé sur la ou les machine(s)  avec le paquet snmpd
   - les ports `161 (port d'échanges d'informations avec le protocole  snmp)` ,`123 en protocole udp (port de synchronisation du server NTP)`
     sont autorsés
   - le fichier `localhost.cfg` présent dans le repertoitre  /etc/shinken/hosts/localhost.cfg (sur la machine qui héberge Shinken-server)
     contient les adresses IP de vos machines à monitorer



### Exemple pour créer et monitorer un Ghost sur la plateforme de cloudwatt

  *  cliquez [ici](https://dev.cloudwatt.com/fr/blog/5-minutes-stacks-episode-cinq-ghost.html)

  * Dans l'onglet `access_and_security` autoriser les ports `22 (connexion en ssh)`,`161 en udp (port d'échanges d'informations *
    avec le protocole  snmp)` ,`123 en protocole udp (port de synchronisation du server NTP)`


  * Après avoir crée votre machine ghost, vous pouvez recuperer son subnet comme suit:

  1. connectez-vous à la machine host que vous venez de créer et procedez comme suit:
  ```
  $ heat resource-list nom_stack_ghost                       //création de votre  machine cliente

  +------------------+---------------------------------------------------+---------------------------------+-----------------+----------------------+
  | resource_name    | physical_resource_id                              | resource_type                   | resource_status | updated_time         |
  +------------------+---------------------------------------------------+---------------------------------+-----------------+----------------------+
  | security_group   | 8e86058f-4933-4835-9d95-d2145f46dbc5              | OS::Neutron::SecurityGroup      | CREATE_COMPLETE | 2015-11-24T15:18:27Z |
  | floating_ip      | a7357436-68b0-4108-a77c-7f25489380d1              | OS::Neutron::FloatingIP         | CREATE_COMPLETE | 2015-11-24T15:18:29Z |
  | network          | ad58e87f-c52b-4a43-a9a4-eae6445534b3              | OS::Neutron::Net                | CREATE_COMPLETE | 2015-11-24T15:18:29Z |
  | subnet           | bd69c3f5-ddc8-4fe4-8cbe-19ecea0fdf2c              | OS::Neutron::Subnet             | CREATE_COMPLETE | 2015-11-24T15:18:30Z |
  | server           | 81ce0266-3361-471a-9b0c-6c37e32c9e9e              | OS::Nova::Server                | CREATE_COMPLETE | 2015-11-24T15:18:38Z |
  | floating_ip_link | a7357436-68b0-4108-a77c-7f25489380d1-`floating @IP`| OS::Nova::FloatingIPAssociation | CREATE_COMPLETE | 2015-11-24T15:19:31Z |
  +------------------+---------------------------------------------------+---------------------------------+-----------------+---------------
  ```

  2. Dans le cas où votre host n'est pas dans le meme sous réseau que votre machine qui héberge Shinken-server,
    alors vous devez créer un routeur avec la technologie openstack, comme suit :

     * Ouvrez une nouvelle fenêtre dans le terminal shell

    ```
    $ neutron router-create nomrouter         // création du routeur

    Created a new router:
    +-----------------------+--------------------------------------+
    | Field                 | Value                                |
    +-----------------------+--------------------------------------+
    | admin_state_up        | True                                 |
    | external_gateway_info |                                      |
    | id                    | babdd078-c0c6-4280-88f5-0f77951a5933 |
    | name                  | nomrouter                            |
    | status                | ACTIVE                               |
    | tenant_id             | 8acb072da1b14c61b9dced19a6be3355     |
    +-----------------------+--------------------------------------+
    ```
  * Il s'agira par la suite d'ajouter  le `subnet_host` de votre host à l'interface du routeur `id du routeur` :
    ```
    ~$ neutron router-interface-add `id_router` `subnet_host`                                // Add id du router + subnet host
    Added interface `subnet_host` to router `id_router`

    ```
  3. Connectez-vous en mode root à la machine qui héberge  shinken-server
     Renseignez le fichier `hosts` d'ansible installer automatiquement sur votre machine qui héberge shinken-server     
  ```         
  # vim /etc/ansible/hosts     

  # This is the default ansible 'hosts' file.
  #
  # It should live in /etc/ansible/hosts
  #   - A hostname/ip can be a member of multiple groups
  [...]
 [shinken]
 localhost  ansible_connection=local

 [slaves]
  xx.xx.xx.xx ansible_ssh_user=cloud ansible_ssh_private_key_file=/home/pierre/.ssh/buildshinken.pem
  ...
  xx.xx.xx.xx  ansible_ssh_user=cloud ansible_ssh_private_key_file=/home/pierre/.ssh/buildshinken.pem
  ```

  4. Tester la connectivité toujours en restant en mode root
  ```                                     
  # ansible slaves -m ping
  ```


  5. Déployer la configuration slave-monitoring.yml sur la machine cliente
  ```
  #ansible-playbook slave-monitoring.yml
  ```

  6. Redemarrer le serveur shinken
    ```
  # service shinken restart
    ```
  7. Reconnectez-vous en interface graphique à l'adresse http://xx.xx.xx.xx:7767  et cliquez sur l'onglet `ALL`

<a name="console" />

### C’est bien tout ça, mais vous n’auriez pas un moyen de lancer l’application par la console ?

Et bien si ! En utilisant la console, vous pouvez déployer un serveur shinken :

1.	Allez sur le Github Cloudwatt dans le répertoire applications/bundle-trusty-shinken
2.	Cliquez sur le fichier nommé bundle-trusty-shinken.heat.yml
3.	Cliquez sur RAW, une page web apparait avec le détail du script
4.	Enregistrez-sous le contenu sur votre PC dans un fichier avec le nom proposé par votre navigateur (enlever le .txt à la fin)
5.  Rendez-vous à la section « [Stacks](https://console.cloudwatt.com/project/stacks/) » de la console.
6.	Cliquez sur « Lancer la stack », puis cliquez sur « fichier du modèle » et sélectionnez le fichier que vous venez de sauvegarder sur votre PC, puis cliquez sur « SUIVANT »
7.	Donnez un nom à votre stack dans le champ « Nom de la stack »
8.	Entrez votre keypair dans le champ « keypair_name »
9.	Choisissez la taille de votre instance parmi le menu déroulant « flavor_name » et cliquez sur « LANCER »

La stack va se créer automatiquement (vous pouvez en voir la progression cliquant sur son nom). Quand tous les modules deviendront « verts », la création sera terminée. Vous pourrez alors aller dans le menu « Instances » pour découvrir l’IP flottante qui a été générée automatiquement. Ne vous reste plus qu’à lancer votre IP dans votre navigateur.

Pour rappel, voici les ports par défaut où répondent les rôles Shinken :

    Arbiter : 7770
    Broker : 7772
    WebUI : 7767
    Reactionner : 7769
    Scheduler : 7768
    Poller : 7771

## So watt ?

Ce tutoriel a pour but d'accélerer votre démarrage. A ce stade vous êtes maître(sse) à bord.

Vous avez un point d'entrée sur votre machine virtuelle en SSH via l'IP flottante exposée et votre clé privée (utilisateur `cloud` par défaut).

Vous pouvez commencer à construire votre site en prenant la main sur votre serveur. Les points d'entrée utiles :

* `/etc/shinken/hosts/`: le répertoire contenant le fichier hosts ( les machines à monitorer)
* `/usr/bin/shinken-`: le répertoire contenant les scripts de shinken
* `/var/lib/shinken`: le répertoire contenant les modules de monitoring de shinken
* `/var/log/shinken`: le répertoire contenant les log

#### Autres sources pouvant vous interesser:

* [shinken-monitoring Homepage](http://www.shinken-monitoring.org/)
* [Shinken Solutions - Index](http://www.shinken-solutions.com/)
* [Shinken manual](http://shinken.readthedocs.org/en/latest/)
* [Shinken blog](http://shinkenlab.io/online-course-2-webui/)
* [shinken-monitoring architecture](https://shinken.readthedocs.org/en/latest/)
* [shinken, webui installation](http://blogduyax.madyanne.fr/installation-de-shinken.html)
* [Installing MongoDB ](https://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/)
* [Installing sqlitedb ](http://www.tutorialspoint.com/sqlite/sqlite_installation.htm)

-----
Have fun. Hack in peace.
