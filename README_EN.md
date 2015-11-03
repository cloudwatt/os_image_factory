# OpenStack Image Factory

If you've been with us for the last few months, you have certainly seen the [5 Minutes Stacks](http://dev.cloudwatt.com/fr/recherche.html?q=5+minutes+stacks&submit=submit) on our tech blog. Now, we offer you a chance to go backstage and create your own bundles! Follow this guide to get started... and watch your step: this stuff is *potent*.

## The Factory

Each episode presented a Heat stack based on a unique pre-built server image. These Ubuntu Trusty images were already packed with the related tools for a faster deployment. The toolbox used to create these practical images is simple and efficient... and completely open-source:

* *Debian Jessie:* OS on which the Factory rests.
* *Openstack CLI:* Crucial for integrating the images into the Cloudwatt Platform
* *Packer:* Created by Hashicorp, this tool utilizes a Builder and Provisioner system to assemble the server images for various platforms, notably OpenStack.
* *Ansible:* A configuration tool from the same family as Puppet, Chef, and SaltStack. The lack of need for an agent in order to function sets Ansible apart.
* *Shell:* Bash is great.

To facilitate you in the creation of new images, we've put our assembly line [on Github](https://github.com/cloudwatt/os_image_factory). Here we have put at your disposal the Ansible playbook and Heat template you will need to summon your *own* image-crafting server, stuffed with all the necessary software to get started. Jenkins sits at the helm of the Factory to offer you a pleasant development cycle.
Without further ado, let's generate your personal factory:

Wielding your Cloudwatt credentials, sign in on the [Cloudwatt Console](https://console.cloudwatt.com/) and ensure you have a [valid keypair](https://console.cloudwatt.com/project/access_and_security/?tab=access_security_tabs__keypairs_tab), the key safely downloaded on your local machine. You will also need your [OpenStack RC file](https://console.cloudwatt.com/project/access_and_security/api_access/openrc/) sourced correctly in your current shell session so that the OpenStack CLIs can function.

~~~ bash
$ source ~/Downloads/something-openrc.sh

~~~

Don't have the OpenStack CLIs? [Take a minute to fix that.](http://docs.openstack.org/cli-reference/content/install_clients.html)
To verify if the clients are correctly installed on your machine, you can attempt to list the stacks you have created:

~~~ bash
$ heat stack-list

~~~

Once you have equipped yourself with OpenStack, clone the Github repository and create yoour factory with the Heat CLI.

~~~ bash
$ git clone https://github.com/cloudwatt/os_image_factory
$ cd os_image_factory/
$ heat stack-create $FACTORY_NAME -f setup/os_image_factory.heat.yml -P keypair_name=$KEYPAIR_NAME
~~~

*Note that `$KEYPAIR_NAME` is not the path to your saved key, but the name you gave the keypair when you created it. If you enter this incorrectly you will not be able to connect to your factory, so don't get the two confused.*

The provisionning of the server applies the `setup/os_image_factory.playbook.yml` Ansible playbook to a fresh instance of Debian Jessie, so it takes a few minutes.

To minimize security risks, we've decided to only authorize SSH connections. To connect to the Jenkins of the factory you must thus set up an SSH tunnel with port forwarding:

~~~ bash
$ ssh $FACTORY_IP -l cloud -i $YOU_KEYPAIR_PATH -L 5000:localhost:8080
~~~

The above would allow you to connect to Jenkins on your browser at the address [localhost:5000](http://localhost:5000), for example.

To finish the installation a manual operation is needed. So that the Factory may interact with the OpenStack API, you must modify the file `/var/lib/jenkins/.profile` to insert your OpenStack credentials as follows:

~~~ bash
export OS_USERNAME=""
export OS_TENANT_NAME=""
export OS_TENANT_ID=""
export OS_PASSWORD=""

~~~

Make sure to restart Jenkins as shown below so that the changes can be taken into account. If you set up your SSH tunnel as shown above, you can [click here](http://localhost:5000) to get to Jenkins.

~~~ bash
$ sudo service jenkins restart
~~~

## The Assembly Line

In the `images/` directory you will find 4 files essential to the creation of new images.

* `ansible_local_inventory`: Ansible inventory file, injected by Packer into the provisioning image to allow Ansible to target the server.
* `build.packer.json`: Packer build file. It takes into account the parameters given to it by the Ansible playbook.
* `build.playbook.yml`: Ansible playbook which pilots the building of images.
* `build.sh`: Short shell script to simplify the use of the Ansible playbook.

The `images/` subdirectories are build examples, each containing the files needed to create a server image. To create your own just apply to following norm:

~~~
images/
    bundle-my-bundle/             # <-- Build directory
        ansible/
            bootstrap.yml         # <-- Ansible playbook for server provisioning
        output/
            my_stack_heat.yml.j2  # <-- Template to generate at the end of the build, currently a Heat template
        build-vars.yml            # <-- Build variables/settings, used by Packer and the piloting Ansible playbook

~~~

The `.j2` ([Jinja2](http://jinja.pocoo.org/)) templates you place in `bundle-my-bundle/output/` will be interpreted by the piloting Ansible playbook. We use them to generate your bundle's Heat template:

~~~ yaml
server:
    type: OS::Nova::Server
    properties:
      key_name: { get_param: keypair_name }
      image: {{ result_img_id }}             # <-- Will be replaced by generated image ID
      flavor: { get_param: flavor_name }
      networks:

~~~

The `build-vars.yml` file contains the variables given to the piloting Ansible playbook:

~~~ yaml
---
bundle:
  name: bundle-my-bundle                          # <-- Image name
  img_base: ae3082cb-fac1-46b1-97aa-507aaa8f184f  # <-- Glance ID of image to use as base
  properties:                                     # <-- Properties you want applied
    img_os: Ubuntu                                #     to the final image
    cw_bundle: MY_BUNDLE
    cw_origin: Cloudwatt

~~~

## Jenkins, would you kindly...

You've coded your own bundle and set the variables in `build-vars.yml`. Ready to try building an image?

**1.** Make sure to push your copy of the *os_image_factory* to a remote Git repository; Github, Bitbucket, whatever you use.

**2.** Open your Jenkins console in a browser and create a new job by clicking on **New Item**

**3.** Fill in the **Item name** (preferably the name of your bundle for simplicity), select **Freestyle project**, and click **OK**.

**4.** The first section of the settings is up to you; the default works fine. Under **Source Code Management** choose **Git**.

**5.** Specify the **Repository URL**, as well as **Credentials** if the project cannot be cloned with public permissions. Other permissions are inconsequential.

**6.** Near the end of the settings, choose **Execute shell** under **Add build step**, and input the following (replace `$BUNDLE_DIR_NAME`):
~~~ bash
$ images/build.sh $BUNDLE_DIR_NAME
~~~

`$BUNDLE_DIR_NAME` must correspond to the directory under `images/` in which you have created your bundle. With the setup above, `$BUNDLE_DIR_NAME` would be `bundle-my-bundle`.

**7.** Select **Archive the artifacts** under **Add post-build action** and input `packer.latest.log,images/target/$BUNDLE_DIR_NAME/output/*`. This isn't required, but prevents you from having to fish around for the generated Heat template or playbook log. Also, artifacts are saved *per build*, meaning that artifacts aren't lost with every new build.

**8.** Hit **Save** to be redirected to your new project page, and now you can click **Build Now** and started churning out images like no tomorrow!

Having followed these instructions, you should find yourself on the Jenkins Project page for your job.

* The **Workspace** consists of the cloned repository, and any changes to it, such as the generated logs and other files.
At the beginning of the build Jenkins will pull the latest changes from the supplied remote, but will not touch any files not monitored by Git.
* The **Build History** allows you to monitor the success of your builds, as well as recover saved artifacts from those builds.
* The **Last Successful Artifacts** offers a quick shortcut to your latest *successful* build's artifacts.

## The Workspace

After a build, three outputs are expected:

* The server image itself, which will be added to your Glance image catalog. The image ID can be easily found in the console output of the `build.sh` script.

* The Heat template generated by the piloting Ansible playbook, to be found in the directory `images/target/bundle-my-bundle/output/`.

* The Packer build logs, essential for debugging your bundle's Ansible playbook, can be found timestamped in `images/target/bundle-my-bundle/`, or the latest one can be easily found at the root, `packer.latest.log`.

## These are the keys...

The skeleton is in place and the toolbox is ready. If you wish to realize your own creations, take inspiration from the builds in the repository. Increase your knowledge of [Ansible](http://docs.ansible.com/ansible/index.html) and it's [playbook modules](http://docs.ansible.com/ansible/list_of_all_modules.html).

Hell, hack the `build.packer.json` file and configure in Puppet or Chef instead, if you want.

We hope our work can serve as a foundation for your own development architectures in the future.

Have fun. Hack in peace.
