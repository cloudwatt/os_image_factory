#!/bin/bash

#./build_fe.sh bundle-trusty-lamp

BASENAME=$1
BUILDMARK=$(date +%Y-%m-%d-%H%M%S)
IMG_NAME=$BASENAME-$BUILDMARK

unset OS_USERNAME
unset OS_PASSWORD
unset OS_DOMAIN_NAME
unset OS_TENANT_NAME
unset OS_AUTH_URL
unset OS_REGION_NAME
unset OS_TENANT_ID
unset OS_IDENTITY_API_VERSION
unset OS_ENDPOINT_TYPE
unset OS_INTERFACE

source ~/honey.sh
source $BASENAME/build-vars-fe
source ../lib/functions.sh

TOKEN=$(get_token)

#create vpc, net and subnet

VPC_ID=$(create_vpc $TOKEN $BUILDMARK)
NET_ID=$(create_net $TOKEN $VPC_ID $BUILDMARK)

#create keypair

create_keypair $BUILDMARK

#boot vm and bootstap
openstack server create --image $SOURCE_IMAGE_ID --flavor t2.micro --availability-zone $AZ_NAME --key-name mykey-${BUILDMARK} --nic net-id=$NET_ID ${IMG_NAME}-tmp || exit 1

IP=$(openstack floating ip create admin_external_net | grep 'floating_ip_address' | awk {'print $4'})

openstack server add floating ip ${IMG_NAME}-tmp $IP>/dev/null 2>&1
echo "===========Provisionning by Ansible====================="
ansible_bootstrap $IP $BASENAME

## create image
echo "===========Wait for image will be active================="
IMG_ID=$(create_image_via_ecs $TOKEN ${IMG_NAME} ${IMG_NAME}-tmp)


## Purge
openstack server delete ${IMG_NAME}-tmp>/dev/null 2>&1

##wait
sleep 60

release_floating_ip

delete_all_net $TOKEN $VPC_ID $NET_ID

delete_keypair $BUILDMARK



echo "IMG_ID for image '$IMG_NAME': $IMG_ID"