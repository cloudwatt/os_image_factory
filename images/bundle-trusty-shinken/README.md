# 5 Minutes Stacks, épisode 15 : Shinken #

## Le concept

Régulièrement, Cloudwatt publiera, de façon conjointe sur ce blog et
sur son github, des stacks applicatives avec un guide de déploiement.
Le but est de vous facilitez la vie pour démarrer des projets. La
procédure prend quelques minutes à préparer et 5 minutes à déployer.

Une fois la pile applicative déployée, vous êtes maître dessus et vous
pouvez commencer à l'exploiter immédiatement.

Si vous avez des questions, remarques, idées d'améliorations n'hésitez
pas à ouvrir une issue sur Github ou à soumettre une pull-request.

## Episode 15 : Shinken

Shinken est une application permettant la surveillance système et réseau.
Elle surveille les hôtes et services spécifiés, alertant lorsque les systèmes
vont mal et quand ils vont mieux. C'est un logiciel libre sous licence GNU AGPL.
Elle est complètement compatible avec le logiciel Nagios et elle a pour but
d'apporter une supervision distribuée et hautement disponible facile à mettre en
place.
La base de déploiement est une instance Debian jessie. Le serveur shinken,
l'interface graphique webui (apporte de l'interface graphique sur shinken ),
la base de données SQlitedb sont déployés dans une instance unique. De la machine
qui heberge le serveur shinken, vous pouvez lancer le déployement de la configuration
des machines à monitorer.

### Les versions

* Debian jessie
* shinken 2.4.2
* SQlitedb

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


description: Basic all-in-one LAMP stack


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

resources:
  network:
    type: OS::Neutron::Net

  subnet:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: network }
      ip_version: 4
      cidr: 10.0.7.0/24
      allocation_pools:
        - { start: 10.0.7.100, end: 10.0.7.199 }

  security_group:
    type: OS::Neutron::SecurityGroup
    properties:
      rules:
        - { direction: ingress, protocol: TCP, port_range_min: 22, port_range_max: 22 }
        - { direction: ingress, protocol: TCP, port_range_min: 7767, port_range_max: 7767 }
        - { direction: ingress, protocol: UDP, port_range_min: 161, port_range_max: 161 }
        - { direction: ingress, protocol: UDP, port_range_min: 123, port_range_max: 123 }
        - { direction: ingress, protocol: ICMP }
        - { direction: egress, protocol: ICMP }
        - { direction: egress, protocol: TCP }
        - { direction: egress, protocol: UDP }

  floating_ip:
    type: OS::Neutron::FloatingIP
    properties:
      floating_network_id: 6ea98324-0f14-49f6-97c0-885d1b8dc517

  floating_ip_link:
    type: OS::Nova::FloatingIPAssociation
    properties:
      floating_ip: { get_resource: floating_ip }
      server_id: { get_resource: server }

  server:
    type: OS::Nova::Server
    properties:
      key_name: { get_param: keypair_name }
      image: 168f7c6b-20a6-4a4e-8052-d1200aa36a1e                         <-------  your os image
      flavor: { get_param: flavor_name }
      networks:
        - network: { get_resource: network }
      security_groups:
        - { get_resource: security_group }

outputs:
  floating_ip_url:
    description: Shinken URL
    value:
      str_replace:
        template: http://$floating_ip:7767/
        params:
          $floating_ip: { get_attr: [floating_ip, floating_ip_address] }
~~~

### Démarrer la stack

Dans un shell, lancer le script `stack-start.sh` en passant en paramètre le nom que vous souhaitez lui attribuer :

~~~
./stack-start.sh shinken
~~~
Exemple :

```
~/os_image_factory/images/bundle-trusty-shinken$ ./stack-start.sh EXP_STACK
+--------------------------------------+-----------------+--------------------+----------------------+
| id                                   | stack_name      | stack_status       | creation_time        |
+--------------------------------------+-----------------+--------------------+----------------------+

| ee873a3a-a306-4127-8647-4bc80469cec4 | EXP_STACK       | CREATE_IN_PROGRESS | 2015-11-25T11:03:51Z |
+--------------------------------------+-----------------+--------------------+----------------------+
```

Enfin, attendez 5 minutes que le déploiement soit complet.

```
~/os_image_factory/images/bundle-trusty-shinken$ heat resource-list EXP_STACK
+------------------+---------------------------------------------------+---------------------------------+-----------------+----------------------+
| resource_name    | physical_resource_id                              | resource_type                   | resource_status | updated_time         |
+------------------+---------------------------------------------------+---------------------------------+-----------------+----------------------+
| floating_ip      | 44dd841f-8570-4f02-a8cc-f21a125cc8aa              | OS::Neutron::FloatingIP         | CREATE_COMPLETE | 2015-11-25T11:03:51Z |
| security_group   | efead2a2-c91b-470e-a234-58746da6ac22              | OS::Neutron::SecurityGroup      | CREATE_COMPLETE | 2015-11-25T11:03:52Z |
| network          | 7e142d1b-f660-498d-961a-b03d0aee5cff              | OS::Neutron::Net                | CREATE_COMPLETE | 2015-11-25T11:03:56Z |
| subnet           | 442b31bf-0d3e-406b-8d5f-7b1b6181a381              | OS::Neutron::Subnet             | CREATE_COMPLETE | 2015-11-25T11:03:57Z |
| server           | f5b22d22-1cfe-41bb-9e30-4d089285e5e5              | OS::Nova::Server                | CREATE_COMPLETE | 2015-11-25T11:04:00Z |
| floating_ip_link | 44dd841f-8570-4f02-a8cc-f21a125cc8aa-84.39.38.215 | OS::Nova::FloatingIPAssociation | CREATE_COMPLETE | 2015-11-25T11:04:30Z |
+------------------+---------------------------------------------------+---------------------------------+-----------------+----------------------
```

Le script `start-stack.sh` s'occupe de lancer les appels nécessaires sur les API Cloudwatt pour :

* démarrer une instance basée sur Debian jessie, pré-provisionnée avec la stack shinken,webui,sqlitedb
* l'exposer sur Internet via une IP flottante

### Enjoy

Une fois tout ceci fait, vous pouvez lancez le script `stack-get-url.sh` qui va récupérer l'url d'entrée de votre stack.

Exemple:

```
~/os_image_factory/images/bundle-trusty-shinken$ ./stack-get-url.sh EXP_STACK
EXP_STACK 84.39.38.215
```

* Après l'étape précédente, tester la connectivité en ssh sur la machine qui héberge le serveur shinken ( n'oubliez pas de renseigner votre clé):
Exemple:

```
~/os_image_factory/images/bundle-trusty-shinken$ ssh 84.39.38.215 -i ~/.ssh/buildshinken.pem -l cloud -vvv
```

Après avoir executé la commande précedente, vous serez connecté en ssh sur votre machine à distance.

```
cloud@exp-stack-server-gr7irra3c2tv:~$ sudo ifconfig
eth0      Link encap:Ethernet  HWaddr 02:bf:17:c9:28:09  
          inet addr:10.0.7.100  Bcast:10.0.7.255  Mask:255.255.255.0
```

Nous voici connecté à notre machine qui héberge shinken-server ( les fichiers de configuration de shinken sont dans: /etc/shinken/)   
```
exp-stack-server-gr7irra3c2tv:/etc/shinken$ ls
arbiters  certs     contactgroups  daemons       dev.cfg    escalations  hosts    notificationways  pollers       realms     resource.d  sample.cfg  servicegroups  shinken.cfg  timeperiods
brokers   commands  contacts       dependencies  discovery  hostgroups   modules  packs             reactionners  receivers  sample      schedulers  services       templates
```

* A ce niveau, vous pouvez vous connecter sur votre navigateur web avec le floatting IP de la machine sur le port http://xx.xx.xx.xx:7767
   Pour s'authentifier sur l'interface web: (login: admin  et le mot de passe: admin)

![Minimum setup](https://assets.digitalocean.com/articles/Shrinken_Ubuntu/1.png)

Un fois l'authentication est faite, cliquez sur l'onglet 'ALL' pour voir les différentes métriques monitorées par shinken

![Bigger production setup](https://assets.digitalocean.com/articles/Shrinken_Ubuntu/2.png)

* Pour lancer la configuration sur les machines clientes,
  Pour vous créer une machine cliente sur la plateforme de cloudwatt,connectez-vous sur cloudwatt.com, cliquez sur l'onglet  'produit' puis sur l'option 'application' et Choisissez 'ghost'.

* connectez-vous à la console de cloudwatt (https://console.cloudwatt.com), dans l'onglet 'stack' vous pourrez recuperer l'addresse ip de votre stack et dans l'onglet 'access_and_security' autoriser les ports :
```
- { direction: ingress, protocol: TCP, port_range_min: 22, port_range_max: 22 }
- { direction: ingress, protocol: TCP, port_range_min: 7767, port_range_max: 7767 }
- { direction: ingress, protocol: UDP, port_range_min: 161, port_range_max: 161 }
- { direction: ingress, protocol: UDP, port_range_min: 123, port_range_max: 123 }
- { direction: ingress, protocol: ICMP }
- { direction: egress, protocol: UDP, port_range_min: 161, port_range_max: 161 }
- { direction: egress, protocol: UDP, port_range_min: 123, port_range_max: 123 }
- { direction: egress, protocol: ICMP }
- { direction: egress, protocol: TCP }
- { direction: egress, protocol: UDP }
```
```
$ heat resource-list stack-ghost       //création de votre  machine cliente

+------------------+---------------------------------------------------+---------------------------------+-----------------+----------------------+
| resource_name    | physical_resource_id                              | resource_type                   | resource_status | updated_time         |
+------------------+---------------------------------------------------+---------------------------------+-----------------+----------------------+
| security_group   | 8e86058f-4933-4835-9d95-d2145f46dbc5              | OS::Neutron::SecurityGroup      | CREATE_COMPLETE | 2015-11-24T15:18:27Z |
| floating_ip      | a7357436-68b0-4108-a77c-7f25489380d1              | OS::Neutron::FloatingIP         | CREATE_COMPLETE | 2015-11-24T15:18:29Z |
| network          | ad58e87f-c52b-4a43-a9a4-eae6445534b3              | OS::Neutron::Net                | CREATE_COMPLETE | 2015-11-24T15:18:29Z |
| subnet           | bd69c3f5-ddc8-4fe4-8cbe-19ecea0fdf2c              | OS::Neutron::Subnet             | CREATE_COMPLETE | 2015-11-24T15:18:30Z |
| server           | 81ce0266-3361-471a-9b0c-6c37e32c9e9e              | OS::Nova::Server                | CREATE_COMPLETE | 2015-11-24T15:18:38Z |
| floating_ip_link | a7357436-68b0-4108-a77c-7f25489380d1-84.39.36.143 | OS::Nova::FloatingIPAssociation | CREATE_COMPLETE | 2015-11-24T15:19:31Z |
+------------------+---------------------------------------------------+---------------------------------+-----------------+----------------------

```

Si vous êtes dans un sous réseau différent, vous aurez besoins de créer un routeur pour interconnecter les deux sous-reseaux.

Exemple:


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

~$ neutron router-interface-add babdd078-c0c6-4280-88f5-0f77951a5933 bd69c3f5-ddc8-4fe4-8cbe-19ecea0fdf2c      // Add id du router + subnet host ghost
Added interface a31a1d46-63f4-4315-8eb6-594bd17bc42f to router babdd078-c0c6-4280-88f5-0f77951a5933.
~$ heat resource-list maresource      

$ neutron router-interface-add babdd078-c0c6-4280-88f5-0f77951a5933 bd69c3f5-ddc8-4fe4-8cbe-19ecea0fdf2c      // Add id du router + subnet host ghost

Added interface a31a1d46-63f4-4315-8eb6-594bd17bc42f to router babdd078-c0c6-4280-88f5-0f77951a5933.

$ heat resource-list BUILD_SHINE

+------------------+---------------------------------------------------+---------------------------------+-----------------+----------------------+
| resource_name    | physical_resource_id                              | resource_type                   | resource_status | updated_time         |
+------------------+---------------------------------------------------+---------------------------------+-----------------+----------------------+
| floating_ip      | ce734a7e-2079-46a9-84c7-e136446cb879              | OS::Neutron::FloatingIP         | CREATE_COMPLETE | 2015-11-24T14:47:33Z |
| security_group   | 916f6d0c-02ac-4ce9-ad3a-67ddf9a61b03              | OS::Neutron::SecurityGroup      | CREATE_COMPLETE | 2015-11-24T14:47:35Z |
| network          | e9ca7722-e5c7-4b17-b842-1343155b4461              | OS::Neutron::Net                | CREATE_COMPLETE | 2015-11-24T14:47:36Z |
| subnet           | 57b4ea12-75c9-4f0c-87e9-2c1ebe58e860              | OS::Neutron::Subnet             | CREATE_COMPLETE | 2015-11-24T14:47:37Z |
| server           | fd868139-6333-49ae-a1d4-6b9099eab4cd              | OS::Nova::Server                | CREATE_COMPLETE | 2015-11-24T14:47:41Z |
| floating_ip_link | ce734a7e-2079-46a9-84c7-e136446cb879-84.39.33.194 | OS::Nova::FloatingIPAssociation | CREATE_COMPLETE | 2015-11-24T14:48:30Z |
+------------------+---------------------------------------------------+---------------------------------+-----------------+----------------------+

~$ neutron router-interface-add babdd078-c0c6-4280-88f5-0f77951a5933 57b4ea12-75c9-4f0c-87e9-2c1ebe58e860        // Add id du router + subnet host server
Added interface 4455951e-17ce-4dfb-bee9-6c7025494103 to router babdd078-c0c6-4280-88f5-0f77951a5933.
```
* copier le contenu de votre clé d'authentication à la plateforme de cloudwatt et coller ce contenu dans un fichier sur la machine hebergeant shinken server.
```
$ cat .ssh/buildshinken.pem       
```                                         
```
$ neutron router-interface-add babdd078-c0c6-4280-88f5-0f77951a5933 57b4ea12-75c9-4f0c-87e9-2c1ebe58e860        // Add id du router + subnet host server
Added interface 4455951e-17ce-4dfb-bee9-6c7025494103 to router babdd078-c0c6-4280-88f5-0f77951a5933.
```

* copier le contenu de votre clé d'authentication à la plateforme de cloudwatt et coller ce contenu dans un fichier sur la machine hebergeant shinken server
```
$ cat .ssh/buildshinken.pem                                                
```
Et par la suite, connecter vous à la machine qui heberge shinken serveur

1.edit un fichier file.pem puis coller le contenu de la clé précedente
```
exp-stack-server-gr7irra3c2tv# vim .ssh/build_shinken.pem
```
2.Donner des permissions d'execution de votre file.pem
```
exp-stack-server-gr7irra3c2tv# chmod 600 .ssh/file.pem
```
3.connectez-vous en ssh à l'adrese IP de la machine cliente
```
exp-stack-server-gr7irra3c2tv#ssh '@IP machine cliente '-l cloud -i .ssh/file.pem
```
4.renseignez le fichier hosts d'ansible installer automatiquement sur la machine serveur     
```         
exp-stack-server-gr7irra3c2tv# vim /etc/ansible/hosts                                             
exp-stack-server-gr7irra3c2tv# ansible slaves -m ping
```
5.Deployer la configuration slave-monitoring.yml sur la machine cliente
```
exp-stack-server-gr7irra3c2tv#ansible-playbook slave-monitoring.yml
```

<a name="console" />

### C’est bien tout ça, mais vous n’auriez pas un moyen de lancer l’application par la console ?

Et bien si ! En utilisant la console, vous pouvez déployer un serveur LAMP :

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

C’est (déjà) FINI !


## So watt ?

Ce tutoriel a pour but d'accélerer votre démarrage. A ce stade vous êtes maître(sse) à bord.

Vous avez un point d'entrée sur votre machine virtuelle en SSH via l'IP flottante exposée et votre clé privée (utilisateur `cloud` par défaut).

Vous pouvez commencer à construire votre site en prenant la main sur votre serveur. Les points d'entrée utiles :

* `/ etc / shinken`: le repertoire contenant les fichiers de configuration de shinken
* `/ usr / bin / shinken-`: le repertoire contenant les scripts de shinken
* `/ var / lib / shinken`: le repertoire contenant les modules de monitoring de shinken
* `/ var / log / shinken`: le repertoire contenant les log

#### Autres sources pouvant vous interesser:

* [shinken-monitoring Homepage](http://www.shinken-monitoring.org/)
* [Shinken Solutions - Index](http://www.shinken-solutions.com/)
* [shinken-monitoring architecture](https://shinken.readthedocs.org/en/latest/)
* [shinken, webui installation](http://blogduyax.madyanne.fr/installation-de-shinken.html)
* [Installing MongoDB on Ubuntu](https://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/)
* [Installing sqlitedb on Ubuntu](http://www.tutorialspoint.com/sqlite/sqlite_installation.htm)
-----
Have fun. Hack in peace.
