#!/usr/bin/env bash

cd images/
ansible-playbook build.playbook.yml -e @$1/build-vars.yml -i ansible_local_inventory
