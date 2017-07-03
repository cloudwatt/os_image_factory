#!/usr/bin/env python
#-*- coding: utf-8 -
#import keystoneclient.v2_0.client as keystone
#from keystoneauth1.identity import v2
#from keystoneauth1 import session

from keystoneclient.v3 import client as keystone
from keystoneclient.auth.identity import v3
from keystoneclient import session as session


import novaclient.client as nova
import cinderclient.client as cinder
from glanceclient.v1 import client as glance
import neutronclient.v2_0.client as neutron
import heatclient.client as heat

import time, paramiko,os,re,errno
from socket import error as socket_error
from os import environ as env
import urllib3


class OpenStackUtils():

    def __init__(self):

        urllib3.disable_warnings()
        auth = v3.Password(auth_url=env['OS_AUTH_URL'],
                   username=env['OS_USERNAME'],
                   password=env['OS_PASSWORD'],
                   project_id=env['OS_PROJECT_ID'],
                   user_domain_id=env['OS_USER_DOMAIN_ID'])

        sess = session.Session(auth=auth, verify=False)


        self.keystone_client = keystone.Client(session=session)
        self.nova_client = nova.Client('2.1', region_name=env['OS_REGION_NAME'], session=sess)
        self.cinder_client = cinder.Client('2', region_name=env['OS_REGION_NAME'], session=sess)
        self.glance_client = glance.Client('2', region_name=env['OS_REGION_NAME'], session=sess)
        self.neutron_client = neutron.Client(region_name=env['OS_REGION_NAME'], session=sess)


    def boot_vm_with_userdata_and_port(self,userdata_path,keypair,port):
        nics = [{'port-id': port['port']['id'] }]
        server = self.nova_client.servers.create(name="test-server-" + self.current_time_ms(),
                                                 image=env['NOSE_IMAGE_ID'],flavor=env['NOSE_FLAVOR'],userdata=file(userdata_path),
                                                 availability_zone=env['NOSE_AZ'],key_name=keypair.name, nics=nics)
        print 'Building, please wait...'
        # wait for server create to be complete
        self.wait_server_is_up(server)
        return server

    def boot_vm(self,image_id=env['NOSE_IMAGE_ID'],flavor=env['NOSE_FLAVOR'],keypair='default'):
        nics = [{'net-id': env['NOSE_NET_ID']}]
        server = self.nova_client.servers.create(name="test-server-" + self.current_time_ms(),
                                                 image=image_id,flavor=flavor,
                                                 #security_groups=[env['NOSE_SG_ID']],
                                                 availability_zone=env['NOSE_AZ'],key_name=keypair.name, nics=nics)
        print 'Building, please wait...'
        self.wait_server_is_up(server)
        return server

    def get_server(self,server_id):
        return self.nova_client.servers.get(server_id)


    def destroy_server(self,server):
        self.nova_client.servers.delete(server)


    def current_time_ms(self):
        return str(int(round(time.time() * 1000)))


    def create_server_snapshot(self,server):
        image= self.nova_client.servers.create_image(server=server,image_name=server.name+"snap")
        return image

    def get_image(self,image_id):
        return self.glance_client.images.get(image_id)


    def destroy_image(self,image):
        self.glance_client.images.delete(image)


    def initiate_ssh(self,floating_ip,private_key_filename):
        ssh_connection = paramiko.SSHClient()
        ssh_connection.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        flag=0
        while flag==0:
           try:
               ssh_connection.connect(floating_ip['floatingip']['floating_ip_address'],username='cloud',key_filename=private_key_filename,timeout=10)
               print "\n\n\nconnected successfully to: " + floating_ip['floatingip']['floating_ip_address']
               flag=1
           except:
              print "ssh connection not yet successful to: " + floating_ip['floatingip']['floating_ip_address']
        return ssh_connection


    def create_floating_ip(self):
        body_value={"floatingip": {"floating_network_id": "0a2228f2-7f8a-45f1-8e09-9039e1d09975"}}
        return self.neutron_client.create_floatingip(body=body_value)


    def associate_floating_ip_to_server(self,floating_ip, server):
        self.nova_client.servers.get(server.id).add_floating_ip(floating_ip['floatingip']['floating_ip_address'])
        time.sleep(10)


    def delete_floating_ip(self,floating_ip):
        self.neutron_client.delete_floatingip(floating_ip['floatingip']['id'])


    def rescue(self,server):
        self.wait_server_available(server)
        return self.nova_client.servers.get(server.id).rescue()

    def unrescue(self,server):
        self.wait_server_available(server)
        return self.nova_client.servers.get(server.id).unrescue()


    def attach_volume_to_server(self,server,volume):
        #self.nova_client.volumes.create_server_volume(server_id=server.id,volume_id=env['NOSE_VOLUME_ID'])
        self.nova_client.volumes.create_server_volume(server_id=server.id,volume_id=volume.id)
        status =volume.status
        while status != 'in-use':
             status = self.cinder_client.volumes.get(volume.id).status
             print status
        print "volume is in use Now : "+ status


    def detach_volume_from_server(self,server,volume):
        self.nova_client.volumes.delete_server_volume(server.id,volume.id)
        status =volume.status
        while status != 'available':
            status = self.cinder_client.volumes.get(volume.id).status
            print status
        print "volume is available : "+ status

    def get_flavor_disk_size(self,flavor_id):
        return self.nova_client.flavors.get(flavor_id).disk

    def server_reboot(self,server,type):
        serv=self.get_server(server.id)
        serv.reboot(reboot_type=type)

    def wait_server_is_up(self,server):
        status = server.status
        while status != 'ACTIVE':
              status = self.get_server(server.id).status
        print "server is up"


    def wait_server_available(self,server):
        task_state = getattr(server,'OS-EXT-STS:task_state')
        while task_state is not None:
              task_state = getattr(self.get_server(server.id),'OS-EXT-STS:task_state')
        print "the server is available"

    def create_keypair(self):
        suffix =self.current_time_ms()
        keypair= self.nova_client.keypairs.create(name="nose_keypair"+suffix)
        private_key_filename = env['HOME']+'/key-'+suffix+'.pem'
        fp = os.open(private_key_filename, os.O_WRONLY | os.O_CREAT, 0o600)
        with os.fdopen(fp, 'w') as f:
               f.write(keypair.private_key)
        return keypair , private_key_filename

    def delete_keypair(self,keypair,private_key_filename):
        self.nova_client.keypairs.delete(keypair.id)
        os.remove(private_key_filename)

    def create_port_with_sg(self):
        body_value = {'port': {
                      'admin_state_up': True,
                      #'security_groups': [env['NOSE_SG_ID']],
                      'name': 'port-test'+self.current_time_ms(),
                      'network_id': env['NOSE_NET_ID'],
                    }}
        port=self.neutron_client.create_port(body=body_value)
        time.sleep(20)
        return port

    def delete_port(self,port):
        self.neutron_client.delete_port(port['port']['id'])


    def create_volume(self):
        volume=self.cinder_client.volumes.create(5,availability_zone=env['NOSE_AZ'] ,name="test-volume"+self.current_time_ms())
        print "the status of volume is:"+ volume.status
        status = volume.status
        while status != 'available':
            status = self.cinder_client.volumes.get(volume.id).status
        print "volume is created : "+ status
        return volume

    def delete_volume(self,volume):
           self.cinder_client.volumes.delete(volume.id)

