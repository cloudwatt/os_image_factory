import os, paramiko, time
import openstackutils


cwlib = openstackutils.OpenStackUtils()
test_resources = {}



def setup():
    global test_resources
    start_chrono = int(round(time.time() * 1000))

    port= cwlib.create_port_with_sg()
    keypair, private_key = cwlib.create_keypair()
    floating_ip = cwlib.create_floating_ip()

    #cwlib.associate_floating_ip_to_port(floating_ip)

    userdata_path = os.path.dirname(os.path.realpath(__file__)) + '/userdata.yml'
    server = cwlib.boot_vm_with_userdata_and_port(userdata_path,keypair,port)
    cwlib.associate_floating_ip_to_server(floating_ip, server)
    cwlib.wait_for_cloud_init(server)
    test_resources['my_port']= port
    test_resources['my_keypair'] = keypair
    test_resources['my_floating'] = floating_ip
    test_resources['my_server'] = server
    test_resources['my_private_key'] = private_key
    test_resources['ssh_connection'] = cwlib.initiate_ssh(floating_ip,private_key)

    stop_chrono = int(round(time.time() * 1000))

    print("Setup 'cloudinit' testsuite in " + str(stop_chrono - start_chrono) + " ms")


def teardown():
    global test_resources
    cwlib.destroy_server(test_resources['my_server'])
    time.sleep(60)
    cwlib.delete_floating_ip(test_resources['my_floating'])
    cwlib.delete_keypair(test_resources['my_keypair'],test_resources['my_private_key'])


