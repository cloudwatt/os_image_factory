#!/bin/sh

IMG_UBUNTU_TRUSTY="ae3082cb-fac1-46b1-97aa-507aaa8f184f"

ansible-playbook ../bundle-build.playbook.yml -e "bundle_label=bundle-trusty-lamp bundle_path=bundle-trusty-lamp bundle_src_img=ae3082cb-fac1-46b1-97aa-507aaa8f184f bundle_img_os=Ubuntu"