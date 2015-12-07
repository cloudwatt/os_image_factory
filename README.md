# OpenStack Image Factory

Depuis plusieurs semaines, si vous nous suivez, vous avez pu voir passer les différents épisodes des [Stacks 5
Minutes](http://dev.cloudwatt.com/fr/recherche.html?q=5+minutes+stacks&submit=submit). Nous allons passer dans
les coulisses et vous expliquer comment construire les vôtres. Suivez le guide et faites attention où vous marchez.

## L'usine

Dans chaque épisode, vous trouverez des stacks HEAT, qui s'appuient sur des images serveur différentes. Ces images
sont des Ubuntu Trusty Tahr, préparées avec une pile applicative complète, pour avoir un démarrage plus rapide.
La boîte à outils pour assembler ces images est full Open Source, simple et efficace :

* *Debian Jessie :* Comme système de référence pour l'usine.
* *Openstack CLI :* Indispensable pour interagir avec notre plate-forme
* *Packer :* Créé par Hashicorp, cet outil s'appuie sur un système de Builder et de Provisionners pour faire de l'assemblage
d'images serveurs pour différentes plates-formes, notamment Openstack.
* *Ansible :* Outil de gestion de configuration, de la même famille que Puppet, Chef ou SaltStack. Sa principale
particularité est de fonctionner sans agent.
* *Shell :* What Else ?

Pour faciliter la création de vos propres images, nous avons rassemblé notre chaîne de montage
[dans un projet Github](https://github.com/cloudwatt/os_image_factory). Nous avons également pour vous un playbook
Ansible et une stack HEAT qui vont vous fournir un serveur de build d'image avec tous les outils nécessaires. Pour un peu
plus de confort, nous avons ajouté un serveur Jenkins dans la boîte à outils. Donc, pour démarrer votre propre usine :

* Munissez vous de :
    * votre [compte Cloudwatt](https://www.cloudwatt.com/cockpit/#/create-contact), avec une [paire de clés existante](https://console.cloudwatt.com/project/access_and_security/?tab=access_security_tabs__keypairs_tab)
    * les outils [OpenStack CLI](http://docs.openstack.org/cli-reference/content/install_clients.html)
* Faites un clone local du repository [os_image_factory](https://github.com/cloudwatt/os_image_factory)
* Placez vous dedans
* Lancez la stack HEAT qui va assembler l'usine :

```
heat stack-create $FACTORY_NAME -f setup/os_image_factory.heat.yml -Pkeypair_name=$YOUR_KEYPAIR_NAME
```

Le provisionning de ce serveur se fait en partant d'une image de base Debian Jessie et en applicant le playbook
Ansible ```setup/os_image_factory.playbook.yml```, cela prend donc quelques minutes. Pour minimiser les risques, nous
avons pris le parti de n'autoriser que des connexions via SSH. Pour accéder au Jenkins de l'usine, il faut donc établir
un tunnel SSH avec forward de port, entre votre machine et le serveur de la stack :


```
ssh $FACTORY_IP -l cloud -i $YOU_KEYPAIR_PATH -L 8080:localhost:8080
```

Pour finaliser l'installation, une opération manuelle est nécessaire. Il faut que votre usine d'assemblage d'image puisse
interagir avec les API Openstack. Vous devez aller manuellement modifier le fichier ```/var/lib/jenkins/.profile```
pour y insérer vos credentials Openstack.

```
# Fill these values to enable full throttle mode.
export OS_USERNAME=""
export OS_TENANT_NAME=""
export OS_TENANT_ID=""
export OS_PASSWORD=""
```

Puis, lancer ```sudo service jenkins restart```, de façon à ce que Jenkins prenne ces valeurs en compte. Si votre tunnel
avec forward est toujours en place, vous devriez pouvoir accéder au Jenkins de l'usine en cliquant [ici](http://localhost:8080).


## La chaîne d'assemblage

Dans le répertoire ```images/``` vous trouverez 4 fichiers, génériques pour toutes les images à assembler :

* ```ansible_local_inventory``` : fichier de définition de groupe Ansible, injecté par Packer dans les images à
provisionner, pour permettre à Ansible de cibler le serveur.
* ```build.packer.json``` : fichier de build Packer. Il prend des paramètres qui lui seront fournis par le playbook
de pilotage de build.
* ```build.playbook.yml``` : playbook Ansible de pilotage de build.
* ```build.sh``` : Micro script shell pour faciliter l'utilisation du playbook de build

Les répertoires placés sous le répertoire ```images/``` sont des exemples de build. Pour écrire les vôtres, il
vous suffit de respecter la norme suivante :

```
images/
    my_bundle/      # <-- répertoire du build
        ansible/
            bootstrap.yml       # <-- playbook de provisionning du serveur
        output/
            my_stack_heat.yml.j2    # <-- template à générer à la fin du build, couramment une stack HEAT
        build-vars.yml          # <-- variables de description du build, exploité par Packer et le playbook de pilotage
```

Les templates que vous placez dans le répertoire output de votre bundle seront interprétés par le playbook de pilotage
de build. Nous l'utilisons pour générer des stacks HEAT en insérant au bon endroit l'ID de l'image serveur créée en cours de build :

```
server:
    type: OS::Nova::Server
    properties:
      key_name: { get_param: keypair_name }
      image: {{ result_img_id }}                <-- result_img_id entre moustache sera remplacé
      flavor: { get_param: flavor_name }            par l'id de la nouvelle image serveur
      networks:
```

Le fichier ```build-vars.yml``` contient les variables fournies au playbook de pilotage de build. Dans sa
plus simple expression, voici un exemple :

```
---
bundle:
  name: bundle-trusty-lamp                          # <-- le nom de votre image
  img_base: ae3082cb-fac1-46b1-97aa-507aaa8f184f    # <-- l'id glance de l'image de base à utiliser
  properties:                                       # <-- les propriétés que vous souhaitez voir
    img_os: Ubuntu                                  #     appliquées sur l'image finale provisionnée
    cw_bundle: LAMP
    cw_origin: Cloudwatt
```


Une fois ceci fait, vous pouvez démarrer un build en lançant la commande suivante :

```
images/build.sh $YOUR_BUNDLE_NAME
```

```$YOUR_BUNDLE_NAME``` doit correspondre au nom du répertoire sous ```images/``` dans lequel vous avez créé votre
bundle.

## L'entrepôt

Lors d'un build, deux outputs sont attendus :

* Les images serveurs elles-mêmes, qui atterrissent dans votre catalogue d'images privées Glance. L'ID de l'image
assemblée est visible dans les traces d'exécution du script ```build.sh```.

* Les sorties des templates placés dans votre répertoire output : Une fois interprétés, ils sont placés dans le
répertoire ```images/target/my_bundle/output```.

## Voici les clés

Le squelette est posé et la boite à outils rôdée. Si vous souhaitez faire vos propres réalisations, prenez exemple
sur les builds présents dans le repository, approfondissez [Ansible](http://docs.ansible.com/ansible/index.html), ou hackez
le ```build.packer.json``` pour utiliser plutôt Puppet ou Chef.

Nous espérons que cela pourra vous servir pour bâtir vos propres architectures dans le futur.

Have fun. Hack in peace.
