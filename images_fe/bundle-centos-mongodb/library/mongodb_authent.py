#!/usr/bin/python

# (c) 2012, Elliott Foster <elliott@fourkitchens.com>
# Sponsored by Four Kitchens http://fourkitchens.com.
# (c) 2014, Epic Games, Inc.
# (c) 2015, Orange, Inc. <alexis.lacroix@orange.com>
#
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

DOCUMENTATION = '''
---
module: mongodb_authent
short_description: Adds or removes a user from a MongoDB database.
description:
    - Adds or removes a user from a MongoDB database.
version_added: "1.1"
options:
    login_user:
        description:
            - The username used to authenticate with
        required: false
        default: null
    login_password:
        description:
            - The password used to authenticate with
        required: false
        default: null
    login_host:
        description:
            - The host running the database
        required: false
        default: localhost
    login_port:
        description:
            - The port to connect to
        required: false
        default: 27017
    login_database:
        version_added: "2.0"
        description:
            - The database where login credentials are stored
        required: false
        default: null
    replica_set:
        version_added: "1.6"
        description:
            - Replica set to connect to (automatically connects to primary for writes)
        required: false
        default: null
    database:
        description:
            - The name of the database to add/remove the user from
        required: true
    name:
        description:
            - The name of the user to add or remove
        required: true
        default: null
        aliases: [ 'user' ]
    password:
        description:
            - The password to use for the user
        required: false
        default: null
    ssl:
        version_added: "1.8"
        description:
            - Whether to use an SSL connection when connecting to the database
        default: False
    roles:
        version_added: "1.3"
        description:
            - "The database user roles valid values are one or more of the following: read, 'readWrite', 'dbAdmin', 'userAdmin', 'clusterAdmin', 'readAnyDatabase', 'readWriteAnyDatabase', 'userAdminAnyDatabase', 'dbAdminAnyDatabase'"
            - This param requires mongodb 2.4+ and pymongo 2.5+
        required: false
        default: "readWrite"
    state:
        state:
        description:
            - The database user state
        required: false
        default: present
        choices: [ 'present', 'absent', 'admin' ]
    update_password:
        required: false
        default: always
        choices: ['always', 'on_create']
        version_added: "2.1"
        description:
          - C(always) will update passwords if they differ.  C(on_create) will only set the password for newly created users.
notes:
    - Requires the pymongo Python package on the remote host, version 2.4.2+. This
      can be installed using pip or the OS package manager. @see http://api.mongodb.org/python/current/installation.html
requirements: [ "pymongo" ]
author: "Elliott Foster (@elliotttf)"
'''

EXAMPLES = '''
# Create 'burgers' database user with name 'bob' and password '12345'.
- mongodb_authent: database=burgers name=bob password=12345 state=present
# Create a database user via SSL (MongoDB must be compiled with the SSL option and configured properly)
- mongodb_authent: database=burgers name=bob password=12345 state=present ssl=True
# Delete 'burgers' database user with name 'bob'.
- mongodb_authent: database=burgers name=bob state=absent
# Define more users with various specific roles (if not defined, no roles is assigned, and the user will be added via pre mongo 2.2 style)
- mongodb_authent: database=burgers name=ben password=12345 roles='read' state=present
- mongodb_authent: database=burgers name=jim password=12345 roles='readWrite,dbAdmin,userAdmin' state=present
- mongodb_authent: database=burgers name=joe password=12345 roles='readWriteAnyDatabase' state=present
# add a user to database in a replica set, the primary server is automatically discovered and written to
- mongodb_authent: database=burgers name=bob replica_set=blecher password=12345 roles='readWriteAnyDatabase' state=present
'''

import ConfigParser
from distutils.version import LooseVersion
try:
    from pymongo.errors import ConnectionFailure
    from pymongo.errors import OperationFailure
    from pymongo.errors import NotMasterError
    from pymongo import version as PyMongoVersion
    from pymongo import MongoClient
except ImportError:
    try:  # for older PyMongo 2.2
        from pymongo import Connection as MongoClient
    except ImportError:
        pymongo_found = False
    else:
        pymongo_found = True
else:
    pymongo_found = True

# =========================================
# MongoDB module specific support methods.
#

def check_compatibility(module, client):
    srv_info = client.server_info()
    if LooseVersion(srv_info['version']) >= LooseVersion('3.0') and LooseVersion(PyMongoVersion) <= LooseVersion('3.0'):
        module.fail_json(msg=' (Note: you must use pymongo 3.0+ with MongoDB >= 3.0)')
    elif LooseVersion(srv_info['version']) >= LooseVersion('2.6') and LooseVersion(PyMongoVersion) <= LooseVersion('2.7'):
        module.fail_json(msg=' (Note: you must use pymongo 2.7.x-2.9.x with MongoDB 2.6)')
    elif LooseVersion(PyMongoVersion) <= LooseVersion('2.5'):
        module.fail_json(msg=' (Note: you must be on mongodb 2.4+ and pymongo 2.5+ to use the roles param)')

def user_find(client, user):
    for mongo_user in client["admin"].system.users.find():
        if mongo_user['user'] == user:
            return mongo_user
    return False

def user_add(module, client, db_name, user, password, roles):
    #pymono's user_add is a _create_or_update_user so we won't know if it was changed or updated
    #without reproducing a lot of the logic in database.py of pymongo
    db = client[db_name]
    if roles is None:
        db.add_user(user, password, False)
    else:
        try:
            db.add_user(user, password, None, roles=roles)
            return True
        except OperationFailure, e:
            err_msg = "[function user_add] " + str(e)
            module.fail_json(msg=err_msg)
        except NotMasterError, e:
            pass
    return False

def user_remove(module, client, db_name, user):
    exists = user_find(client, user)
    if exists:
        db = client[db_name]
        db.remove_user(user)
    else:
        module.exit_json(changed=False, user=user)

def load_mongocnf():
    config = ConfigParser.RawConfigParser()
    mongocnf = os.path.expanduser('~/.mongodb.cnf')

    try:
        config.readfp(open(mongocnf))
        creds = dict(
          user=config.get('client', 'user'),
          password=config.get('client', 'pass')
        )
    except (ConfigParser.NoOptionError, IOError):
        return False

    return creds

def authenticate(client, login_user, login_password, login_database):
    try:
        client.admin.authenticate(login_user, login_password)
    except OperationFailure:
        pass

# =========================================
# Module execution.
#

def main():
    module = AnsibleModule(
        argument_spec = dict(
            login_user=dict(default=None),
            login_password=dict(default=None),
            login_host=dict(default='localhost'),
            login_port=dict(default='27017'),
            login_database=dict(default=None),
            replica_set=dict(default=None),
            database=dict(required=True, aliases=['db']),
            name=dict(required=True, aliases=['user']),
            password=dict(aliases=['pass']),
            ssl=dict(default=False),
            roles=dict(default=None, type='list'),
            state=dict(default='present', choices=['absent', 'present', 'admin']),
            update_password=dict(default='always', choices=['always', 'on_create']),
        )
    )

    if not pymongo_found:
        module.fail_json(msg='the python pymongo module is required')

    login_user = module.params['login_user']
    login_password = module.params['login_password']
    login_host = module.params['login_host']
    login_port = module.params['login_port']
    login_database = module.params['login_database']

    replica_set = module.params['replica_set']
    db_name = module.params['database']
    user = module.params['name']
    password = module.params['password']
    ssl = module.params['ssl']
    roles = module.params['roles']
    state = module.params['state']
    update_password = module.params['update_password']

    try:
        if replica_set:
            client = MongoClient(login_host, int(login_port), replicaset=replica_set, ssl=ssl)
        else:
            client = MongoClient(login_host, int(login_port), ssl=ssl)

        if login_user is None or login_password is None:
            module.fail_json(msg='when supplying login arguments, both login_user and login_password must be provided')

        if login_user is not None and login_password is not None:
            authenticate(client, login_user, login_password, login_database)
        elif  LooseVersion(PyMongoVersion) >= LooseVersion('3.0'):
            if db_name != "admin":
                module.fail_json(msg='The localhost login exception only allows the first admin account to be created')
            #else: this has to be the first admin user added

    except ConnectionFailure, e:
        module.fail_json(msg='unable to connect to database: %s' % str(e))

    check_compatibility(module, client)

    change_state=False
    if state == 'admin':
        if password is None and update_password == 'always':
            module.fail_json(msg='password parameter required when adding a user unless update_password is set to on_create')

        try:
            if update_password == 'on_create' and user_find(client, user):
                addU=False
            else:
                addU=True
        except OperationFailure:
            addU=True

        if addU:
            try:
                if user_add(module, client, db_name, user, password, roles):
                    change_state=True
            except OperationFailure, e:
                module.fail_json(msg='Unable to add or update user: %s' % str(e))

    if state == 'present':
        if password is None and update_password == 'always':
            module.fail_json(msg='password parameter required when adding a user unless update_password is set to on_create')

        if update_password != 'always' and user_find(client, user):
            password = None

        try:
            if user_add(module, client, db_name, user, password, roles):
                change_state=True
        except OperationFailure, e:
            module.fail_json(msg='Unable to add or update user: %s' % str(e))

    elif state == 'absent':
        try:
            user_remove(module, client, db_name, user)
            change_state=True
        except OperationFailure, e:
            module.fail_json(msg='Unable to remove user: %s' % str(e))

    module.exit_json(changed=change_state, user=user)


from ansible.module_utils.basic import *
main()

