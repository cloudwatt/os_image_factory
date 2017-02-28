#!/usr/bin/env python
import os, paramiko

ssh_connex = paramiko.SSHClient()
ssh_connex.set_missing_host_key_policy(paramiko.AutoAddPolicy())

ssh_connex.connect('84.39.51.34', username='cloud', key_filename='/home/mohamed/.ssh/alikey.pem', timeout=180)

chan_in, chan_out, chan_err = ssh_connex.exec_command('lsblk | grep vda1 | awk \'{$1=" "; print $4}\'| tr -d "G"')

data = chan_out.read()


print data
#if data is not None:
#    print "n'est pas vide"
#else:
#    print "vide"
#if data.find("GNU Emacs") != -1:
#    print("SUCCESS "+str(data.find("GNU Emacs")))
#else:
#    print("FAILURE "+str(data.find("GNU Emacs")))
