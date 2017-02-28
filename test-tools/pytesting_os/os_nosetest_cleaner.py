import time, shade
from os import environ as env
import sys

shade.simple_logging()
cloud = None


def get_cloud():
    global cloud
    if not cloud:
        cloud = shade.OpenStackCloud(cloud=sys.argv[1])
    return cloud

all_servers = [server for server in get_cloud().list_servers() if server['name'].startswith('test_server')]
all_sg = get_cloud().list_security_groups()
all_ports = get_cloud().list_ports()
all_test_sg = [sg for sg in all_sg if sg['name'].startswith('test-')]

for server in all_servers:
    get_cloud().delete_server(server['id'])

for sg in all_test_sg:
    print("FOUND "+str(sg))
    print("EOF ")
    print("deleting "+sg['id'])

    for sgr in sg['security_group_rules']:
        get_cloud().delete_security_group_rule(sgr['id'])

    all_port_concerned_by_sg = [port for port in all_ports if sg['id'] in port['security_groups']]

    for port in all_port_concerned_by_sg:
        get_cloud().delete_port(port['id'])

    get_cloud().delete_security_group(sg['id'])


all_net = get_cloud().list_networks()

for net in all_net:
    if net['name'] != 'public' and net['name'].startswith('test_'):
        print("==> DELETE NETWORK "+net['name'])
        get_cloud().delete_network(net['id'])

for fip in [fip for fip in get_cloud().list_floating_ips() if not fip['attached']]:
    get_cloud().delete_floating_ip(fip['id'])
