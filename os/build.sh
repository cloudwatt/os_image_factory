#!/bin/sh

ansible-playbook $(dirname $0)/build.playbook.yml -e @$(dirname $0)/$1/build-vars.yml -i ansible_local_inventory