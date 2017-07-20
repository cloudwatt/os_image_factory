import time
from basics import test_resources
import openstackutils


cwlib = openstackutils.OpenStackUtils()

def test_boot_snapshot_in_other_flavor():
    global test_resources

    new_server = cwlib.boot_vm(image_id=test_resources['snapshot'], flavor='s1.medium',keypair=test_resources['my_keypair'])

    floating = cwlib.create_floating_ip()

    cwlib.associate_floating_ip_to_server(floating, new_server)

    ssh_connection = cwlib.initiate_ssh(floating,test_resources['my_private_key'])
   
    assert ssh_connection

    cwlib.destroy_server(new_server)

    cwlib.delete_floating_ip(floating)

