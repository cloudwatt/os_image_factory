#!/bin/sh

ansible-playbook $(dirname $0)/bundle-build.playbook.yml -e @$(dirname $0)/$1/build-vars.yml