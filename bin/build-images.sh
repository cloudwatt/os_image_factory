#!/usr/bin/env bash

fe=$(echo $2 | tr '[:upper:]' '[:lower:]')

if [ $fe = true ] ; then

cd images_fe
sh build_fe.sh $1

else

cd images/
ansible-playbook build.playbook.yml -e @$1/build-vars.yml -i ansible_local_inventory


fi