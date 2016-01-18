# mongodb-orange-playbook README v1.0.0[^1] #
[^1]: <20160112_1626>

**mongodb-orange-playbook**, an ansible role to deploy a mongodb replica set. This role has been tested in **push and pull** mode on Redhat/Centos 6 (CB Platon) !

## Requirements ##

This component needs:

- **git** *>= 1.7.1*
- **ansible** *>= 1.9.2*
- **yum repository** to retrieve from your managed hosts:
	- **lvm2**
	- **ntp**
	- **logrotate**
	- **python** *== 2.6*
	- **python-setuptools**
	- **mongodb-orange-products-server-[shell/server/tools/mongos]**
- A **sudoers** user like osadmin with a ssh connection
- An **egg pymongo driver** compiled for your environment (depends on python version) 


## Install ##

You need to be able to retrieve the git playbook.

> mongodb >= 2.6.x:
>
> - git clone git@scm.runmytest.rd.francetelecom.fr:nosql/mongodb-orange-playbook.git


## Configuration ##

This part describe how to configure the playbook.

There is 1 config file in the **defaults** directory: **main.yml** that stores: *system variables / mongod variables / ntp / hosts variables*


- **main.yml**:

| Parameters name | Value         | Comment         |
| --------------- |:-------------:| --------------- |
| mongodb_version | 3.0.6 | mongodb version to install|
| mongodb_product_name | mongodb-orange-products | mongodb product name|
| mongodb_version | mongodb | mongodb user name|
| mongodb_version | mongodb | mongodb group name|
| site | all | logical name for machine group (no need to update this parameter)|
| system_user | osadmin | system user for the playbook usage, must be a sudoers|
| iface | eth0 | interface name for the mongod replication communication|
| playbook_comment | "#mongodb-orange-playbook comment#" | Text added to the modified lines by the ansible playbook (ntp.conf/hosts)|
---

| Parameters name | Value         | Comment         |
| --------------- |:-------------:| --------------- |
| system_hosts | enabled / disabled | /etc/hosts file management (**only set the replica set hosts name**)|
| system_hosts_extra | - "@ip hostname" | Extra value for the hosts file|
---

| Parameters name | Value         | Comment         |
| --------------- |:-------------:| --------------- |
| system_ntp | enabled / disabled | /etc/ntp.conf file management (**only set some new lines**)|
| system_ntp_extra | - "server ntp-g5-1.si.francetelecom.fr" | ntp servers name|
| system_ntp_extra_comment | "server 0.rhel.pool.ntp.org" | ntp servers name to be commented|
---

| Parameters name | Value         | Comment         |
| --------------- |:-------------:| --------------- |
| system_mount | enabled / disabled | mongodb data mount point management. If this part is enabled, you must set the mondata in the group_vars/mongod file|
| mondata_path | /mondata | Path of the mongodb instance directory|
| *mondata_pv* | /dev/vdb | Name of the physical volume. **If not set, mongodb will use the entire "mondata device"**|
| *mondata_vg* | infravg | Name of the volume group. **If not set, mongodb will use the entire "mondata device"**|
| *mondata_lv* | mondata_lv | Name of the logical volume. **If not set, mongodb will use the entire "mondata device"**|
| mondata_dev | /dev/vdb | Name of the mondata device|
| *mondata_size* | "100%FREE" | Size used to create the logical volume. **If not set, mongodb will use the entire "mondata device"**|
| mondata_fstype | ext4 | Filesystem type. For the moment, **ext4** is the only FS tested|
| mondata_fsopts | noatime | Option specified to the mounted devices|
---

| Parameters name | Value         | Comment         |
| --------------- |:-------------:| --------------- |
| repo_mongo_name | mongodb-orange-product | The repo name used by yum/apt to install the mongodb products (**mongodb-orange-products-server-[shell/server/tools/mongos]**)|
| repo_extra_name | epel-orange | The repo name used by yum/apt to install the extra products (**lvm2**, **ntp**, **logrotate**, **easy_install**)|
| repo_mongo | enabled / disabled | Activate yum/apt repository for mongodb|
| repo_mongo_file | [repo_mongo_file]("" "/etc/yum.repos.d/{{ repo_mongo_name }}.repo") | The repo file name|
| repo_mongo_content | multi-line |<div align=left><pre><code>repo_mongo_content: &#124;<br>  [{{ repo_mongo_name }}]<br>  name={{ repo_mongo_name }}<br>  baseurl="http://repoyum-central.itn.ftgroup/yum/repos/orange/product/nosql/el6/"<br>  enabled=0<br>  gpgcheck=0</code></pre></div>|
| repo_extra | enabled / disabled | Activate yum/apt repository for extra packages|
| repo_extra_file | [repo_extra_file]("" "/etc/yum.repos.d/{{ repo_extra_name }}.repo") | yum nosql repository url to retrieve the mongodb package|
| repo_extra_content | multi-line |<div align=left><pre><code>repo_mongo_content: &#124;<br>  [{{ repo_extra_name }}]<br>  name=Extra Packages for Enterprise Linux 6 -<br>  baseurl="http://repoyum-central.itn.ftgroup/yum/repos/asis/epel/6/x86_64/"<br>  enabled=0<br>  gpgcheck=0</code></pre></div>|
---

| Parameters name | Value         | Comment         |
| --------------- |:-------------:| --------------- |
| mongodb_pymongo_version | 3.1.1 | The pymongo package version to install/check |
| mongodb_pymongo_path | /tmp | The temporary directory to put the egg file if needed |
| mongodb_pymongo_name | [pymongo.egg]("" "pymongo-{{ mongodb_pymongo_version }}-py2.6-linux-x86_64.egg") | The name of the egg file to be installed|
---

| Parameters name | Value         | Comment         |
| --------------- |:-------------:| --------------- |
| mongodb_logrotate | enabled / disabled | Activate the logrotate process for mongodb|
---

| Parameters name | Value         | Comment         |
| --------------- |:-------------:| --------------- |
| monconf_version | 1.0.0 | Configuration Number |
| monconf_backupPath | [backup]("" "{{ mondata_path }}/backup") | Backup path for mongodb |
| monconf_logPath | [log]("" "{{ mondata_path }}/log") | Log path for mongodb |
| monconf_systemLogpath | [logPath]("" "{{ monconf_logPath }}/mongod.log") | Path to the mongod log file |
| monconf_dbPath | [dbPath]("" "{{ mondata_path }}/data") | Path to the mongodb data directory |
| monconf_cfgPath | [cfgPath]("" "{{ mondata_path }}/cfg") | Configuration path for mongodb |
| monconf_cfgFilePath | [cfgFilePath]("" "{{ monconf_cfgPath }}/mongod.conf") | Configuration Number |
| monconf_pidFilePath | [pidFilePath]("" "{{ mondata_path }}/run/mongod.pid") | Path to the mongod pid file |
| monconf_pathPrefix | [pathPrefix]("" "{{ mondata_path }}/run") | Path to the mongodb prefix directory |
| monconf_port | 27017 | Port number used by mongodb |
| monconf_journalenabled | "true" | Enable journaling |
| monconf_engine | mmapv1 / wiredTiger | Plugable engine used |
| monconf_mmapv1smallFiles | "true" | Small file for mmapv1 (size of file divided by 4) |
| monconf_wiredTigercacheSizeGB | 1 | Cache Size for wiredTiger in Gb |
| monconf_slowOpThresholdMs | 100 | Journalised slow operation threshold journaling in ms |
| monconf_replication | enabled / disabled | Enable the replication mode |
| monconf_replSetName | replication | Name of the replica set |
| monconf_oplogSizeMB | 20 | Size of the replication operation log in Mb |
| monconf_authorization | enabled / disabled | Authorization enabled or disabled (**not tested disabled by default**)|
| monconf_keyFile | [keyfile]("" "{{ monconf_cfgPath }}/mongodb-keyfile") | Path to the key file (Communication between mongodb servers is encrypted). (**not tested disabled by default**)|
| mongodb_siteUserAdmin_name | siteUserAdmin | adminAnyDatabases user if monconf_authorization is enabled |
| mongodb_siteUserAdmin_password | siteUserAdmin | adminAnyDatabases password if monconf_authorization is enabled |
| mongodb_siteRootAdmin_name | root | root user if monconf_authorization is enabled |
| mongodb_siteRootAdmin_password | root | root password if monconf_authorization is enabled |


## Example Playbook

The inventory file should looks like:

| Section | Comment         |
| ------- | --------------- |
| mongodb-rs | List of servers to be managed by the mongodb role |

~~~~~~~~~~~~~~~~~~~~~
[mongodb-rs]
dvalacentos01 state=present
dvalacentos02 state=present arbiter_only=yes
dvalacentos03 state=present
~~~~~~~~~~~~~~~~~~~~~

*You can also, use a dynamic inventory, with meta !*

Openstack example:
<pre>
  instance_03:
    type: OS::Nova::Server
    depends_on: server_security_group
    properties:
      name: dvalacentos03
      image: centos6_webcom_sbx
      flavor: m1.medium
      networks: [{ network: Private_Net }]
      security_groups: [{ get_resource: server_security_group }]
      key_name: nosql
<b><i>      metadata:
        host_groups: "mongodb-rs"
        host_vars: "state->present;arbiter_only->yes"</i></b>
      user_data_format: RAW
      user_data: |
          #cloud-config
</pre>


## Example Playbook

In your **site.yml** file, (the playbook launcher), you can use the role like this:

	- hosts: mongodb-rs
	  serial: 1
	  remote_user: "{{ system_user }}"
	  roles:
	    - { role: mongodb-orange-playbook, mongodb_operator: "{{ groups['mongodb-rs'][0] }}", _rsconfig: "{{ groups['mongodb-rs'] }}" }


It will execute the role, and will connect to the mongodb_operator (groups['mongodb-rs'][0]) to configure the replica set. All the commands will be serialized.

In your **site_deploy.yml** file, (the playbook launcher for a new Platform), you can use the role like this:

	- hosts: mongodb-rs
	  remote_user: "{{ system_user }}"
	  roles:
	    - { role: mongodb-orange-playbook, mongodb_operator: "{{ groups['mongodb-rs'][0] }}", _rsconfig: "{{ groups['mongodb-rs'] }}" }

It will execute the role, and will connect to the mongodb_operator (groups['mongodb-rs'][0]) to configure the replica set. All the commands will be parallelized.

## Run a playbook with ansible ##

This part describe how to use the playbook:

> For the first time, when you are deploying all the machines (parallel actions), you can use this command:

~~~~~~~~~~~~~~~~~~~~~
ansible-playbook -i production site_deploy.yml
~~~~~~~~~~~~~~~~~~~~~

> With a dynamic inventory script, you can use this command:

~~~~~~~~~~~~~~~~~~~~~
ansible-playbook -i inventory/dyn-hosts.py site_deploy.yml
~~~~~~~~~~~~~~~~~~~~~

> After, in a production mode (rolling update), you can use this command:

~~~~~~~~~~~~~~~~~~~~~
ansible-playbook -i production site.yml
~~~~~~~~~~~~~~~~~~~~~

> You can test your environment with (audit mode) --check:

~~~~~~~~~~~~~~~~~~~~~
ansible-playbook -i production site.yml --check
~~~~~~~~~~~~~~~~~~~~~

> if you want test and know the exact difference:

~~~~~~~~~~~~~~~~~~~~~
ansible-playbook -i production site.yml --check --diff
~~~~~~~~~~~~~~~~~~~~~

> if you want to know the tags list (execute specifics modules of the playbook):

~~~~~~~~~~~~~~~~~~~~~
ansible-playbook site.yml --list-tags

playbook: site.yml

  play #1 (mongodb-rs): TAGS: []
    TASK TAGS: [mongodb-orange-playbook, mongodb-orange-playbook-authent, mongodb-orange-playbook-db, mongodb-orange-playbook-requirement, mongodb-orange-playbook-rsconfig, mongodb-orange-playbook-rsinit]

~~~~~~~~~~~~~~~~~~~~~

> And then, you can launch the role:

~~~~~~~~~~~~~~~~~~~~~
ansible-playbook -i production site.yml --tags mongodb-orange-playbook
~~~~~~~~~~~~~~~~~~~~~

> And then, if you can launch the requirements part of this role:

~~~~~~~~~~~~~~~~~~~~~
ansible-playbook -i production site.yml --tags mongodb-orange-playbook-requirement
~~~~~~~~~~~~~~~~~~~~~

> And then, if you can launch the database part of this role:

~~~~~~~~~~~~~~~~~~~~~
ansible-playbook -i production site.yml --tags mongodb-orange-playbook-db
~~~~~~~~~~~~~~~~~~~~~

> And then, if you can launch the replica set part of this role:

~~~~~~~~~~~~~~~~~~~~~
ansible-playbook -i production site.yml --tags mongodb-orange-playbook-rsconfig
~~~~~~~~~~~~~~~~~~~~~


## Playbook structure ##

~~~~~~~~~~~~~~~~~~~~~
mongodb-orange-playbook
├── defaults
│   └── main.yml
├── files
│   └── disable-transparent-hugepages
├── handlers
│   └── main.yml
├── library
│   ├── mongodb_authent.py
│   ├── mongodb_rs_get_primary.py
│   └── mongodb_rs.py
├── meta
│   └── main.yml
├── tasks
│   ├── Debian_mongodb_requirement_install.yml
│   ├── main.yml
│   ├── mongodb_authent_management.yml
│   ├── mongodb_authent.yml
│   ├── mongodb_dbconfig_keyfile.yml
│   ├── mongodb_dbconfig_logrotate.yml
│   ├── mongodb_dbconfig.yml
│   ├── mongodb_requirement_hosts.yml
│   ├── mongodb_requirement_ntp.yml
│   ├── mongodb_requirement_volume.yml
│   ├── mongodb_requirement.yml
│   ├── mongodb_rsconfig.yml
│   ├── mongodb_rsinit.yml
│   └── RedHat_mongodb_requirement_install.yml
└── templates
    ├── mongod.conf.j2
    ├── mongod-logrotate.j2
    ├── repo_extra-product.j2
    └── repo_mongodb-product.j2

~~~~~~~~~~~~~~~~~~~~~


## Program notes ##

### Files explanation : ###

~~~~~~~~~~~~~~~~~~~~~
Under construction
~~~~~~~~~~~~~~~~~~~~~

