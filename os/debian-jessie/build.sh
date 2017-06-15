#!/bin/sh

BASENAME="debian-jessie"
BUILDMARK="$(date +%Y-%m-%d-%H%M)"
IMG_NAME="$BASENAME-$BUILDMARK"
TMP_IMG_NAME="$BASENAME-tmp-$BUILDMARK"

IMG=debian-8.7.1-20170215-openstack-amd64.qcow2
IMG_URL=http://cdimage.debian.org/cdimage/openstack/current/$IMG

TMP_DIR=debian-jessie-guest

if [ -f "$IMG" ]; then
    rm $IMG
fi

wget -q $IMG_URL

if [ ! -d "$TMP_DIR" ]; then
    mkdir $TMP_DIR
fi

guestmount -a $IMG -i $TMP_DIR

sed -i "s#name: debian#name: cloud#" $TMP_DIR/etc/cloud/cloud.cfg
sed -i "s#gecos: Debian#gecos: Cloud user#" $TMP_DIR/etc/cloud/cloud.cfg
sed -i "s#debian#cloud#" $TMP_DIR/etc/sudoers.d/debian-cloud-init
sed -i "/ed25519/d" $TMP_DIR/etc/ssh/sshd_config
sed -i "/gecos/a \ \ \ \ \ shell: \/bin\/bash" $TMP_DIR/etc/cloud/cloud.cfg


guestunmount $TMP_DIR

glance image-create \
       --file $IMG \
       --disk-format qcow2 \
       --container-format bare \
       --name "$TMP_IMG_NAME"

TMP_IMG_ID="$(openstack image list --private | grep $TMP_IMG_NAME | tr "|" " " | tr -s " " | cut -d " " -f2)"
echo "TMP_IMG_ID for image '$TMP_IMG_NAME': $TMP_IMG_ID"

sed "s/TMP_IMAGE_ID/$TMP_IMG_ID/" $(dirname $0)/build-vars.template.yml > $(dirname $0)/build-vars.yml
sed -i "s/B_TARGET_NAME/$IMG_NAME/" $(dirname $0)/build-vars.yml

mkdir -p $(dirname $0)/output

cd ..

./build.sh debian-jessie

BUILD_SUCCESS="$?"

echo "======= Deleting temporary image..."
glance image-delete $TMP_IMG_ID

if [ ! "$BUILD_SUCCESS" ]; then
  echo "Build failed! Check packer log for details."
  echo "Error code: $BUILD_SUCCESS"
  exit 1
fi

IMG_ID="$(openstack image list --private | grep $IMG_NAME | tr "|" " " | tr -s " " | cut -d " " -f2)"
echo "IMG_ID for image '$IMG_NAME': $IMG_ID"


export NOSE_IMAGE_ID=$IMG_ID

export NOSE_FLAVOR=21

export NOSE_NET_ID=$FACTORY_NETWORK_ID

export NOSE_SG_ID=$FACTORY_SECURITY_GROUP_ID

pwd
pushd ../test-tools/pytesting_os/

nosetests --nologcapture

popd


# FIXME: Actually delete images
# echo "======= Deleting deprecated images"
echo "======= Listing deprecated images"
openstack image list | grep -E "$BASENAME-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}" | tr "|" " " | tr -s " " | cut -d " " -f 3 | sort -r | awk 'NR>5' # | xargs -r openstack image delete

glance image-show $IMG_ID

#if [ "$?" = "0" ]; then
#  echo "======= Validation testing..."
#  echo "URCHIN_IMG_ID=$IMG_ID $WORKSPACE/test-tools/urchin $WORKSPACE/test-tools/ubuntu-tests"
#  URCHIN_IMG_ID=$IMG_ID "$WORKSPACE/test-tools/urchin" "$WORKSPACE/test-tools/ubuntu-tests"
#fi


./cloudwattToFe.sh $IMG_NAME $IMG_NAME "Debian GNU/Linux 8.6.0 64bit"