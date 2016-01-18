#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2015, Orange, Inc. <alexis.lacroix@orange.com>

DOCUMENTATION = '''
module: mongodb_rs_get_primary
short_description: Retrieve the hostname and the port of the mongodb primary server for a replica set.
description:
    - Retrieve the name of the mongodb primary server for a replica set.
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
    replica_set:
        version_added: "1.6"
        description:
            - Replica set to connect to (automatically connects to primary for writes)
        required: false
        default: null
notes:
    - Requires the pymongo Python package on the remote host, version 2.4.2+. This
      can be installed using pip or the OS package manager. @see http://api.mongodb.org/python/current/installation.html
requirements: [ "pymongo" ]
author: "Alexis LACROIX"
'''

EXAMPLES = '''
- mongodb_rs_get_primary: login_user=roor login_password=12345 replica_set=replication
  register: rs_primary
- debug: msg="{{ rs_primary.host }}:{{ rs_primary.port }}"
'''

DEFAULT_PORT = 27017

import time

pymongo_found = False
try:
    from pymongo.errors import ServerSelectionTimeoutError
    from pymongo.errors import ConnectionFailure
    from pymongo.errors import OperationFailure
    from pymongo.errors import AutoReconnect
    from pymongo import MongoClient
    pymongo_found = True
except ImportError:
    try:  # for older PyMongo 2.2
        from pymongo import Connection as MongoClient
        pymongo_found = True
    except ImportError:
        pass

def authenticate(client, login_user, login_password):
    try:
        client.admin.authenticate(login_user, login_password)
    except OperationFailure:
        pass
    except ServerSelectionTimeoutError as e:
        raise Exception('unable to connect to database: %s' % e)

def rs_get_config(client):
    return client.local.system.replset.find_one()

def rs_get_status(client):
    return client.admin.command('replSetGetStatus')

def rs_get_primary(rs_status):
    if 'members' in rs_status:
        a = filter(lambda x: x['state'] == 1, rs_status['members'])
        return a[0] if a else None
    else:
        return None

def rs_wait_for_ok_and_primary(client, timeout = 60):
    while True:
        status = client.admin.command('replSetGetStatus', check=False)
        if status['ok'] == 1 and status['myState'] == 1:
            return

        timeout = timeout - 1
        if timeout == 0:
            raise Exception('reached timeout while waiting for rs.status() to become ok=1')

        time.sleep(1)

def main():
    module = AnsibleModule(
        argument_spec = dict(
            login_host      = dict(default='localhost'),
            login_port      = dict(type='int', default=DEFAULT_PORT),
            login_user      = dict(default=None),
            login_password  = dict(default=None),
            replica_set     = dict(default=None),
            ssl             = dict(default=False),
        )
    )

    if not pymongo_found:
        module.fail_json(msg='the python pymongo module is required')

    login_host      = module.params['login_host']
    login_port      = module.params['login_port']
    login_user      = module.params['login_user']
    login_password  = module.params['login_password']
    replica_set     = module.params['replica_set']
    ssl             = module.params['ssl']

    result = dict(changed=False)

    # connect
    client = None

    if replica_set is None:
        result['changed'] = True
        result['host'] = login_host
        result['port'] = login_port
    else:
        try:
            client = MongoClient(login_host, login_port, replicaSet=replica_set, ssl=ssl)
        except ConnectionFailure as e:
            module.fail_json(msg='unable to connect to database: %s' % e)

        # authenticate
        if login_user is not None and login_password is not None:
            authenticate(client, login_user, login_password)

        # get replica set status
        rs_status = rs_get_status(client)
        master_member = rs_get_primary(rs_status)
        if master_member is None:
            rs_wait_for_ok_and_primary(client)

        result['host'] = master_member['name'].split(":")[0]
        result['port'] = master_member['name'].split(":")[1]

    module.exit_json(**result)


from ansible.module_utils.basic import *
main()

