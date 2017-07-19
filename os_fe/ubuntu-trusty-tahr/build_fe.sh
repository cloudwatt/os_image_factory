#!/bin/bash

#sudo apt-get install libs3-2
# ./build_fe.sh ubuntu-trusty-tahr
# os_version is "Ubuntu 16.04 server 64bit" ,"Ubuntu 14.04 server 64bit", "CentOS 7.3 64bit" ... juste the os_version was accepted by Flexible Engine

BASENAME="ubuntu-14.04"
BUILDMARK="$(date +%Y-%m-%d-%H%M%S)"
IMG_NAME="$BASENAME-$BUILDMARK"
IMG_URL=http://cloud-images.ubuntu.com/releases/14.04/14.04/ubuntu-14.04-server-cloudimg-amd64-disk1.img
TMP_IMG_NAME="$BASENAME-tmp-$BUILDMARK"
#Fe variables
OS_VERSION="Ubuntu 14.04 server 64bit"
MINDISK=40
MINRAM=1024
BUCKET=factory-$BUILDMARK
AZ_NAME=eu-west-0a
IMG=$(echo "${IMG_URL##*/}")

source ../../lib/functions.sh

IMG=$(echo "${IMG_URL##*/}")

TMP_DIR=guest-ubuntu-14.04

if [ -f "$IMG" ]; then
    rm $IMG
fi

wget -q $IMG_URL

if [ ! -d "$TMP_DIR" ]; then
    mkdir $TMP_DIR
fi

guestmount -a $IMG -i $TMP_DIR

if [ "$?" != "0" ]; then
  echo "Failed to guestmount image"
  exit 1
fi

cp $TMP_DIR/etc/cloud/templates/hosts.debian.tmpl $TMP_DIR/etc/cloud/templates/hosts.tmpl
sed -i "/preserve_hostname/a manage_etc_hosts: true" $TMP_DIR/etc/cloud/cloud.cfg
sed -i "s/name: ubuntu/name: cloud/" $TMP_DIR/etc/cloud/cloud.cfg
sed -i "s/gecos: Ubuntu/gecos: Cloud user/" $TMP_DIR/etc/cloud/cloud.cfg
sed -i "/ed25519/d" $TMP_DIR/etc/ssh/sshd_config

sed -i "s#LABEL=cloudimg-rootfs#/dev/xvda1#" \
    $TMP_DIR/etc/fstab \
    $TMP_DIR/boot/grub/menu.lst \
    $TMP_DIR/boot/grub/grub.cfg

echo "sleep 5" >> $TMP_DIR/etc/init/plymouth-upstart-bridge.conf

sed -i "s/#GRUB_DISABLE_LINUX_UUID/GRUB_DISABLE_LINUX_UUID/" $TMP_DIR/etc/default/grub

echo "guestunmount $TMP_DIR"
guestunmount $TMP_DIR

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


check_bucket $BUCKET
PRECHECK=$?
if [ $PRECHECK -ne 0 ] ; then
  echo "======create the bucket"
 s3 create $BUCKET
else
  echo "======= the bucket "
  echo $BUCKET
  echo "existed"
fi

#upload image to S3
s3 put $BUCKET/$TMP_IMG_NAME.qcow2 filename=$IMG >& /dev/null


TOKEN=$(get_token)

create_image_via_s3 $TOKEN

echo "===========Wait for tmp image will be active================="

sleep 40

TMP_IMG_ID=$(openstack image list | grep $TMP_IMG_NAME | awk {'print $2'})>/dev/null 2>&1

wait_image_active $TMP_IMG_ID

#create keypair

create_keypair $BUILDMARK

#create vpc, net and subnet for test

VPC_ID=$(create_vpc $TOKEN $BUILDMARK)

NET_ID=$(create_net $TOKEN $VPC_ID $BUILDMARK)

#boot vm and bootstap
openstack server create --image $TMP_IMG_ID --flavor t2.micro --availability-zone $AZ_NAME --key-name mykey-${BUILDMARK} --nic net-id=$NET_ID ${IMG_NAME}-tmp  || exit 1

IP=$(openstack floating ip create admin_external_net | grep 'floating_ip_address' | awk {'print $4'})

openstack server add floating ip ${IMG_NAME}-tmp $IP

echo "===========Provisionning by Ansible====================="

ansible_bootstrap $IP

## create image
echo "===========Wait for image will be active================="

IMG_ID=$(create_image_via_ecs $TOKEN ${IMG_NAME} ${IMG_NAME}-tmp)

#IMG_ID=$(openstack image list | grep "${IMG_NAME}" | awk {'print $2'}) >/dev/null 2>&1 || exit 1


######### Purge Resources ##################
delete_image $TOKEN $TMP_IMG_ID

openstack server delete ${IMG_NAME}-tmp>/dev/null 2>&1

rm -rf $IMG

sleep 60

release_floating_ip

delete_keypair $BUILDMARK


s3 delete $BUCKET/$TMP_IMG_NAME.qcow2


s3 delete $BUCKET

if [ -z $IMG_ID ]
 then
 exit 1
fi
echo "========Test for image : " $IMG_ID "======================================"
export NOSE_IMAGE_ID=$IMG_ID

export NOSE_FLAVOR=t2.small

export NOSE_NET_ID=$NET_ID

export NOSE_AZ=$AZ_NAME

pushd ../../test-tools/pytesting_os_fe/

nosetests --nologcapture

popd

##delete vpc

delete_all_net $TOKEN $VPC_ID $NET_ID
echo "================END==================================================="
echo "IMG_ID for image '$IMG_NAME': $IMG_ID"



