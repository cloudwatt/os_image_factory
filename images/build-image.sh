#!/bin/sh

ansible-playbook $(dirname $0)/bundle-build.playbook.yml -e @$1