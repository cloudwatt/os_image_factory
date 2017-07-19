# Flexible Engine Image Factory

## L'usine

Dans chaque épisode, vous trouverez des stacks HEAT, qui s'appuient sur des images serveur différentes. Ces images
sont préparées avec une pile applicative complète, pour avoir un démarrage plus rapide.

La boîte à outils pour assembler ces images est full Open Source, simple et efficace :

* *Centos 7 :* Comme système de référence pour l'usine.
* *Openstack CLI :* Indispensable pour interagir avec notre plate-forme
s serveurs pour différentes plates-formes, notamment Openstack.
* *Ansible :* Outil de gestion de configuration, de la même famille que Puppet, Chef ou SaltStack. Sa principale
particularité est de fonctionner sans agent.
* *Shell :* What Else ?


Pour faciliter la création de vos propres images, nous avons rassemblé notre chaîne de montage
[dans un projet Github](https://github.com/cloudwatt/os_image_factory). 

Nous vous avons également préparé une stack HEAT qui vont vous fournir un serveur de build d'image avec tous les outils nécessaires. Pour un peu
plus de confort, nous avons ajouté un serveur Jenkins dans la boîte à outils. Donc, pour démarrer votre propre usine :

* Munissez vous de :
    * votre [compte Flexible Engine](https://console.prod-cloud-ocb.orange-business.com), 
    * une [paire de clés existante](https://console.prod-cloud-ocb.orange-business.com/ecm/?agencyId=31f8f902b5ab4b05b0c767f5c79d2cae&region=as-west-0&locale=en-us#/keypairs/manager/keypairsList)

Le provisionning de ce serveur se fait en partant d'une image dites **bundle** avec l'ensemble des outils necessaires. Pour minimiser les risques, nous avons pris le parti de n'autoriser que des connexions via SSH. Pour accéder au Jenkins de l'usine, il faut donc établir
un tunnel SSH avec forward de port, entre votre machine et le serveur de la stack :

```
ssh $FACTORY_IP -l cloud -i $YOU_KEYPAIR_PATH -L 8080:localhost:8080
```

Vous devriez pouvoir accéder au Jenkins de l'usine en cliquant [ici](http://localhost:8080)

Pour finaliser l'installation, une opération manuelle est nécessaire. Vous devez aller manuellement chercher le contenu du fichier  ```/var/lib/jenkins/secrets/initialAdminPassword``` via la connexion SSH lors de la première initialisation.

```
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Installer les plugins suggéré
 
 ![plugins](../statics/plugins.png)
 
Entrez à présent vos informations qui serviront à sécuriser votre jenkins. Pour rappel celui-ci a connaissance de vos indentifiants Cloudwatt et est donc capable de piloter votre tenant.
 ![info](../statics/infos.png)
 
Jenkins est à présent initialisé.
  
Avant tout commençons par découvrir la chaine d'assemblage afin de maitriser le processus de bout en bout.
   
## La chaîne d'assemblage
 
Sur le github de [Cloudwatt](https://github.com/cloudwatt/os_image_factory) vous trouverez l'ensemble de nos scripts. 
Dans le répertoire ```images/``` vous trouverez 4 fichiers, génériques pour toutes les images à assembler :
 
 
 * ```purge_image_fe.yml``` : playbook Ansible de pilotage de build.
 * ```build_fe.sh``` : Micro script shell pour faciliter l'utilisation du playbook de build
 
Les répertoires placés sous ```images_fe/``` sont des exemples de build. Pour écrire les vôtres, il vous suffit de respecter la norme suivante :
 
 ```
 images/
     my_bundle/      # <-- répertoire du build
         ansible/
             bootstrap.yml       # <-- playbook de provisionning du serveur
         output/
             my_stack_heat.yml.j2    # <-- template à générer à la fin du build, couramment une stack HEAT
         build-vars-fe          # <-- variables de description du build
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
 
Le fichier ```build-vars-fe``` contient les variables fournies au playbook de pilotage de build. Dans sa
plus simple expression, voici un exemple :
 
```
SOURCE_IMAGE_ID=d57abb8b-2010-4f23-bb00-2999d4d3b5d5  <---- ID de l'image source
AZ_NAME=eu-west-0a <----- Zone souhaité pour le build
MINDISK=40 <----- Disque minimum souhaité pour lancer l'image
MINRAM=1024 <------ RAM minimum souhaitée pour lancer l'image
``` 
 
Maintenant que vous avez connaissance de l'ensemble des la chaine de montage d'un image, vous pouvez vous lancer dans la construction de votre propre image bundle.
 
## Fabrication image Bundle

**1..** Dans un premier temps, ajouter vos identifiants dans le fichier `/var/lib/jenkins/honey.sh`, comme ci-dessous :
~~~
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_ID=***********
export OS_PASSWORD=***************
export OS_AUTH_URL=https://iam.eu-west-0.prod-cloud-ocb.orange-business.com/v3
export OS_USERNAME=***************
export OS_TENANT_NAME=eu-west-0
export OS_USER_DOMAIN_ID=**********
export OS_REGION_NAME=eu-west-0
export OS_ENDPOINT_TYPE=publicURL
export CINDER_ENDPOINT_TYPE=publicURL
export OS_VOLUME_API_VERSION=2
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
export OS_USER_DOMAIN_NAME=********
export OS_DOMAIN_NAME=OCB****
export S3_ACCESS_KEY_ID="********"
export S3_SECRET_ACCESS_KEY="*********"
export S3_HOSTNAME="oss.eu-west-0.prod-cloud-ocb.orange-business.com"
~~~
**2.** Assurez-vous d'avoir fait une copie du dếpot **os_image_factory** vers un dépôt Git distant; Github, Bitbucket, tout ce que vous utilisez.

**3.** Cliquez sur **"Créer un nouveau job"**
 
 ![start](../statics/start.png)
 
**4.** Choisissez de faire un projet de type **free-style**
 
 ![name](../statics/name.png)
 
**5.** Donnez maintenant un nom à votre projet, puis spécifiez le repos github à cloner pour lancer le build de votre image.
 
 ![config](../statics/conf.png)
 
**6.** Configurez maintenant la commande à exécuter pour lancer votre build, si vous avez cloner notre repos [OS_image_factory](https://github.com/cloudwatt/os_image_factory.git)

**7.** En fin de page, choisissez **Exécuter un script shell** sous **Build**, puis saisissez les éléments suivants (remplacez `$ BUNDLE_DIR_NAME`):
 
```
cd images_fe && ./build_fe.sh $BUNDLE_NAME
```
```$BUNDLE_NAME``` doit correspondre au nom du répertoire sous ```images/``` dans lequel vous avez créé votre
 bundle.
 ![build](../statics/build_fe.png)
  
**7.** Sélectionnez **Archiver les artefacts** sous **Ajouter une action post-build** et saisir ```packer.latest.log, images/target/$BUNDLE_DIR_NAME/output/*``` . Cela n'est pas obligatoire, mais ca vous empêchera d'avoir des problèmes à générer le template HEAT ou les logs du playbook. En outre, les outputs sont enregistrés à chaque lancement de projet, ce qui signifie que vous pourrez retrouver les logs de vos anciennes actions.

**8.**  Lancez maintenant votre projet
 
## Fabrication d'image OS  
 
La factory nous sert aussi à fabriquer nos propres images d'OS que l'on propose aux clients de flexible engine.
Vous trouverez l'ensemble des scripts de création dans le répertoire **OS** sur le repo github [OS_image_factory](https://github.com/cloudwatt/os_image_factory.git)
 
La démarche pour fabriquer une image OS et image image bundle est là même, c'est juste la commande à lancer qui est un peu différente car effectivement il faut télécharger l'image au format QCOW2 et l'uploader dans votre glance avant de lancer le build. 
Voici comment faire, vous pouvez démarrer un build en lançant la commande suivante :
 
```
cd os_fe/$OS_DIR_NAME/ && ./build_fe.sh
```

Si vous avez regardé le script ```build_fe.sh``` qui se trouve dans chaque répertoire des OS, vous avez pu remarquer qu'une suite de test unitaire était lancé afin de tester l'image dans notre environnement Openstack.
Celle ci est ecrite en Python et vous retrouverez l'ensemble des scripts dans le répertoire **test-tools/pytesting_os_fe**.
Pour information rien ne vous empeche d'ajouter vos propres tests ou de modifier les notres si besoin.


## L'entrepôt

Lors d'un build, deux outputs sont attendus :

* Les images serveurs elles-mêmes, qui atterrissent dans votre catalogue d'images privées Glance. L'ID de l'image
assemblée est visible dans les traces d'exécution du script ```build_fe.sh```.


## Voici les clés

Le squelette est posé et la boite à outils rôdée. Si vous souhaitez faire vos propres réalisations, prenez exemple
sur les builds présents dans le repository, approfondissez [Ansible](http://docs.ansible.com/ansible/index.html), ou hackez
le ```./lib/fuctions.sh``` pour utiliser plutôt Puppet ou Chef.

Nous espérons que cela pourra vous servir pour bâtir vos propres architectures dans le futur.

-------
Have fun. Hack in peace.