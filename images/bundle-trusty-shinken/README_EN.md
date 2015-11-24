# 5 Minutes Stacks, Episode 1: Shinken

## Episode 1: Shinken

**Draft - Image not yet available...**

Shinken is an open source monitoring framework based on Nagios Core which has been rewritten in python to enhance flexibility, scalability, and ease of use. Shinken is fully compatible with Nagios and supports its plugins and configurations that can be used on the go without rewriting or adjusting.
Shinken has no limits regarding distribution. It can be scaled to the LAN, through the DMZs and even across several datacenters.
Shinken goes beyond the classical monitoring functions of Nagios, allowing distributed and highly available monitoring of assets, a smart and automatic management of openstack technology, and is able to monitor hosts applications automatically.
Shinken is considered 5 times faster than Nagios, and comes with a large number of monitoring packages that can be easily installed, providing a faster way to start monitoring servers, services, and applications.
For our scenario, we will start by declaring the debian jessie monitored host (Shinken slave), install and configure SNMP on it, and then monitor it using a custom community string.
The SNMP template will processes the following checks:

    host check each 5 minutes: check with a ping that the server is UP

    check disk spaces

    check load average

    check the CPU usage

    check physical memory and swap usage

    check network interface activities
Shinken server store his data in database. you can chose sqlitedb or mongodb when you installing. I chose sqlitedb for default.
Once it's done, we'll use SSH package to check  SSH states on the slave as an example on how to use packages. Shinken engine was installed but no graphical interface. In this step, we chose to install webui recommended that brings viewing (configuration is done by editing the files and rebooting the Shinken services)
## Preparations

### The version

* shinken (shinken-server/shinken-web) 2.4.2
* SQlitedb

### The prerequisites to deploy this stack

These should be routine by now:

* Internet access
* A Linux shell
* A [Cloudwatt account](https://www.cloudwatt.com/authentification) with a [valid keypair](https://console.cloudwatt.com/project/access_and_security/?tab=access_security_tabs__keypairs_tab)
* The tools of the trade: [OpenStack CLI](http://docs.openstack.org/cli-reference/content/install_clients.html)
* A local clone of the [Cloudwatt applications](https://github.com/cloudwatt/applications) git repository

### Size of the instance

By default, the stack deploys on an instance of type "Small" (s1.cw.small-1). A variety of other instance types exist to suit your various needs, allowing you to pay only for the services you need. Instances are charged by the minute and capped at their monthly price (you can find more details on the [Tarifs page](https://www.cloudwatt.com/fr/produits/tarifs.html) on the Cloudwatt website).

Stack parameters, of course, are yours to tweak at your fancy.

## What will you find in the repository

Once you have cloned the github repository, you will find in the `bundle-trusty-shinken/` directory:

* `bundle-trusty-shinken.heat.yml`: Heat orchestration template. It will be use to deploy the necessary infrastructure.
* `stack-start.sh`: Stack launching script, which simplifies the parameters and secures the admin password creation.
* `stack-get-url.sh`: Returns the floating-IP in a URL, which can also be found in the stack output.

## Start-up

### Initialize the environment

Have your Cloudwatt credentials in hand and click [HERE](https://console.cloudwatt.com/project/access_and_security/api_access/openrc/).
If you are not logged in yet, complete the authentication and save the credentials script.
With it, you will be able to wield the amazing powers of the Cloudwatt APIs.

Source the downloaded file in your shell and enter your password when prompted to begin using the OpenStack clients.

~~~ bash
$ source COMPUTE-[...]-openrc.sh
Please enter your OpenStack Password:

~~~

Once this done, the Openstack command line tools can interact with your Cloudwatt user account.

### Adjust the parameters

In the `.heat.yml` files (heat templates), you will find a section named `parameters` near the top. The mandatory parameters are the `keypair_name` and the `password` for the shinken *admin* user.

You can set the `keypair_name`'s `default` value to save yourself time, as shown below.
Remember that key pairs are created [from the console](https://console.cloudwatt.com/project/access_and_security/?tab=access_security_tabs__keypairs_tab), and only keys created this way can be used.

The `password` field provides the password for shinken default *admin* user. You will need it upon initial login, but you can always create other users later. You can also adjust (and set the default for) the instance type by playing with the `flavor` parameter accordingly.

By default, the stack network and subnet are generated for the stack, in which the shinken server sits alone. This behavior can be changed within the `.heat.yml` as well, if needed.

~~~ yaml

heat_template_version: 2013-05-23


description: All-in-one Shinken stack


parameters:
  keypair_name:
    description: Keypair to inject in instance
    label: SSH Keypair
    type: string

  flavor_name:
    default: s1.cw.small-1
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

<a name="startup" />

### Stack up with a terminal

In a shell, run the script `stack-start.sh`:

~~~ bash
$ ./stack-start.sh TICKERTAPE «my-keypair-name»
Enter your new admin password:
Enter your new password once more:
Creating stack...
+--------------------------------------+------------+--------------------+----------------------+
| id                                   | stack_name | stack_status       | creation_time        |
+--------------------------------------+------------+--------------------+----------------------+
| xixixx-xixxi-ixixi-xiixxxi-ixxxixixi | TICKERTAPE | CREATE_IN_PROGRESS | 2025-10-23T07:27:69Z |
+--------------------------------------+------------+--------------------+----------------------+
~~~

Within 5 minutes the stack will be fully operational. (Use watch to see the status in real-time)

~~~ bash
$ watch -n 1 heat stack-list
+--------------------------------------+------------+-----------------+----------------------+
| id                                   | stack_name | stack_status    | creation_time        |
+--------------------------------------+------------+-----------------+----------------------+
| xixixx-xixxi-ixixi-xiixxxi-ixxxixixi | TICKERTAPE | CREATE_COMPLETE | 2025-10-23T07:27:69Z |
+--------------------------------------+------------+-----------------+----------------------+
~~~

### Stack URL with a terminal

Once all of this done, you can run the `stack-get-url.sh` script.

~~~ bash
$ ./stack-get-url.sh TICKERTAPE
TICKERTAPE  http://70.60.637.17:9000/
~~~

As shown above, it will parse the assigned floating-IP of your stack into a URL link, with the right port included. You can then click or paste this into your browser of choice and bask in the glory of a fresh shinken instance.

<a name="console" />

### Please console me

There there, it's okay... shinken stacks can be spawned from our console as well!

To create our shinken stack from the console:

1.	Go the Cloudwatt Github in the [applications/bundle-trusty-shinken](https://github.com/cloudwatt/applications/tree/master/bundle-trusty-shinken) repository
2.	Click on the file named `bundle-trusty-shinken.heat.yml`
3.	Click on RAW, a web page will appear containing purely the template
4.	Save the page to your PC. You can use the default name proposed by your browser (just remove the .txt if needed)
5.  Go to the [Stacks](https://console.cloudwatt.com/project/stacks/) section of the console
6.	Click on **Launch stack**, then **Template file** and select the file you just saved to your PC, and finally click on **NEXT**
7.	Name your stack in the **Stack name** field
8.	Enter the name of your keypair in the **SSH Keypair** field
9.	Enter your new admin password
10.	Choose your instance size using the **Instance Type** dropdown and click on **LAUNCH**

The stack will be automatically generated (you can see its progress by clicking on its name). When all modules become green, the creation will be complete. You can then go to the "Instances" menu to find the floating-IP, or simply refresh the current page and check the Overview tab for a handy link.

Remember that the shinken UI is on port 9000, not the default port 80!

## So watt?

The goal of this tutorial is to accelerate your start. At this point **you** are the master of the stack. An easy way to [get started](http://docs.shinken.org/en/1.2/pages/getting_started.html#get-messages-in) is to have your shinken server log itself!

shinken takes inputs from a plethora of ports and protocols, I recommend you take the time to document yourselves on the possibilities. Just remember that all input and output ports must be explicitly set for the [security group](https://console.cloudwatt.com/project/access_and_security/?tab=access_security_tabs__security_groups_tab). To add an input, click on **MANAGE RULES** for your stack's security group and then, once on the page *MANAGE SECURITY GROUP RULES*, click **+ ADD RULE**. If logs don't make it to your shinken instance, check the [security group](https://console.cloudwatt.com/project/access_and_security/?tab=access_security_tabs__security_groups_tab) first!

You also now have an SSH access point on your virtual machine through the floating-IP and your private key pair (default user name `cloud`). Be warned, the default browser connection to shinken is not encrypted (HTTP): if you are using your shinken instance to store sensitive data, you may want to connect with an SSH tunnel instead.

~~~ bash
user@home$ cd applications/bundle-trusty-shinken/
user@home$ ./stack-get-url.sh TICKERTAPE
TICKERTAPE  http://70.60.637.17:9000/
user@home$ ssh 70.60.637.17 -l cloud -i /path/to/your/.ssh/keypair.pem -L 5000:localhost:9000
[...]
cloud@shinken-server$ █
~~~

By doing the above, I could then access my shinken server from http://localhost:7767/ on my browser. ^^

## Accessing the WebUI

For now, our monitoring server and client are configured. We need to access the Shinken Web UI using the IP address of our server http://X.X.X.X:7767.

![Minimum setup](https://assets.digitalocean.com/articles/Shrinken_Ubuntu/1.png)

Once authenticated, we will see a blank page saying “You don't have any widget yet?” We will configure it later with custom widgets to get the information needed, but first we need to check if our client is configured and reachable by the server. Click on All tab and you will see a list of all monitored machines, including the server(localhost). On the same list you should find Shinken_slave like .

![Bigger production setup](https://assets.digitalocean.com/articles/Shrinken_Ubuntu/2.png)

In the dashboard, you can to create widgets. Since we have only one monitored droplet, we will add graph, problems and relation widgets. Click on add a widget then choose the one you want from the panel. By default, the widgets will get the localhost (monitoring server) states and informations. We can edit them to reflects the host we want by clicking and specifying the “Element name” as shown

![Bigger production ](https://assets.digitalocean.com/articles/Shrinken_Ubuntu/4.png)

#### The interesting directories are:

-"/ etc / shinken": the whole program configuration of shinken-server
- "/ usr / bin / shinken-*": launch scripts of daemons
- "/ var / lib / shinken": shinken the modules and supervision plugins (we will return)
- "/ var / log / shinken": top secret

#### Other resources you could be interested in:

* [shinken-monitoring Homepage](http://www.shinken-monitoring.org/)
* [Shinken Solutions - Index](http://www.shinken-solutions.com/)
* [shinken-monitoring architecture](https://shinken.readthedocs.org/en/latest/)
* [shinken, webui installation](http://blogduyax.madyanne.fr/installation-de-shinken.html)
* [Installing MongoDB on Ubuntu](https://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/)
* [Installing sqlitedb on Ubuntu](http://www.tutorialspoint.com/sqlite/sqlite_installation.htm)

-----
Have fun. Hack in peace.
