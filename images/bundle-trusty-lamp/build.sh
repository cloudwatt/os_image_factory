#!/bin/sh

IMG_UBUNTU_TRUSTY="ae3082cb-fac1-46b1-97aa-507aaa8f184f"

export FACTORY_SECURITY_GROUP_NAME=`neutron security-group-show $FACTORY_SECURITY_GROUP_ID | grep "| name" | cut -d"|" -f3 | tr -d " "`

ansible-playbook ../bundle-build.playbook.yml -e "bundle_label=bundle-trusty-lamp bundle_path=bundle-trusty-lamp bundle_src_img=ae3082cb-fac1-46b1-97aa-507aaa8f184f bundle_img_os=Ubuntu"