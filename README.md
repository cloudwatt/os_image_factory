# OpenStack Image Factory

Depuis plusieurs semaines, si vous nous suivez, vous avez pu voir passer les différents épisodes des [Stacks 5
Minutes](http://dev.cloudwatt.com/fr/recherche.html?q=5+minutes+stacks&submit=submit). Nous allons passer dans
les coulisses et vous expliquer comment construire les vôtres. Suivez le guide et faites attention où vous marchez.

## L'usine

Chaque épisode faire référence à des stacks HEAT qui utilisent chacune un id d'image différent. Ces images serveurs
sont des Ubuntu Trusty Tahr, préparées avec une pile applicative complète, pour avoir un démarrage plus rapide.
Pour préparer ces images serveurs, nous utilisons une boîte à outils full Open Source, simple et efficace :

* Openstack CLI : Indispensable pour interagir avec notre plate-forme.
* Packer : Créé par Hashicorp, vouer à créer des images préprovisionnés pour différentes plates-formes de virtualisation
et cloud
* Ansible : Outil de gestion de configuration
* Shell : What Else ?

Pour vous faciliter la prise en main et vous donnez la possibilité de créer vos propres images, nous avons rassemblé notre
chaine de montage [dans un projet Github](https://github.com/cloudwatt/os_image_factory). Pour démarrer votre propre usine :

* Faites un clone local du repository ```os_image_factory```.
* PLacez vous dedans
* Lancer la stack HEAT qui va assembler l'usine' :

```
heat stack-create $FACTORY_NAME -f setup/os_image_factory.heat.yml -Pkeypair_name=$YOUR_KEYPAIR
```

Le provisionning de ce serveur se fait en partant d'une image de base Ubuntu Trusty et en applicant le playbook
Ansible ```setup/os_image_factory.playbook.yml```, cela prend donc quelques minutes. Pour minimiser les risques, nous
avons pris le partis de n'autoriser que des connexions via SSH. Pour accéder au Jenkins de l'usine, il faut donc établir
un tunnel SSH entre votre machine et le serveur de la stack :


```
ssh $FACTORY_IP -l cloud -i $YOU_KEYPAIR_PATH -L 8080:localhost:8080
```

Pour finaliser l'installation, une opération manuelle est nécessaire. Vous devez aller manuellement modifier le fichier
```/var/lib/jenkins/.profile``` pour y insérer vos crédentials Openstack.

```
# Fill these values to enable full throttle mode.
export OS_USERNAME=""
export OS_TENANT_NAME=""
export OS_TENANT_ID=""
export OS_PASSWORD=""
```

Puis, lancer ```sudo service jenkins restart```, de façon à ce que Jenkins prenne ces valeurs en compte. Si votre tunnel
avec forward est toujours en place, vous devriez pouvoir accéder au Jenkins de l'usine en cliquant [ici](http://localhost:8080).


## Les chaînes d'assemblage

Dans le répertoire ```images/``` vous trouverez 4 fichiers, générique pour toutes les images à assembler :

* ```ansible_local_inventory``` : fichier de définition de groupe Ansible, injecté par Packer dans les images à
provisionner, pour permettre à Ansible de cibler le serveur.
* ```build.packer.json``` : fichier de build Packer
* ```build.playbook.yml``` : Playbook Ansible de pilotage d'un build.
* ```build.sh``` : Micro script shell pour faciliter l'utilisation du playbook de build

Les répertoires placés sous le répertoire ```images/``` sont des exemples de build. Pour écrire les vôtres, il
vous suffit de respecter la norme suivante :

1. dans un répertoire sous ```images/```
2. créer un fichier ```build-vars.yml``` qui contiendra la description de votre image serveur :

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

3. dans votre répertoire de build, un sous-répertoire ```ansible``` contenant un playbook ansible à nommer ```bootstrap.yml```
C'est ce playbook qui sera appliquer à l'image de base pour le provisionning de votre image serveur.

Une fois ceci fait, vous pouvez démarrer un build en lançant :

```
# YOUR_BUNDLE_NAME doit correspondre au nom du répertoire sous images dans lequel vous avez créé vos fichiers de bundle

images/build.sh $YOUR_BUNDLE_NAME
```




bien parler du extra_vars