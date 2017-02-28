#!/usr/bin/env python
import time, paramiko,os,re,errno
from socket import error as socket_error
import openstackutils as c
from os import environ as env

cwlib =c.OpenStackUtils()


if __name__ == '__main__':

    #port= cwlib.create_port_with_sg() 688099dc-1cff-4dde-bfd9-13de09e972bf

    #print port['port']['id']

    #cwlib.delete_port(port)

    #84.39.51.34
    serv=cwlib.get_server('688099dc-1cff-4dde-bfd9-13de09e972bf')
    serv.reboot(reboot_type='HARD')
    time.sleep(20)
    print serv.status
    serv.reboot(reboot_type='SOFT')
    time.sleep(20)
    print serv.status