#!/bin/sh

BASENAME="Centos"
# TENANT_ID="772be1ffb32e42a28ac8e0205c0b0b90"
BUILDMARK="$(date +%Y-%m-%d-%H%M)"
IMG_NAME="$BASENAME-$BUILDMARK"
TMP_IMG_NAME="$BASENAME-tmp-$BUILDMARK"

IMG=CentOS-7-x86_64-GenericCloud.qcow2
IMG_URL=http://cloud.centos.org/centos/7/images/$IMG
TMP_DIR=centos-guest

if [ -f "$IMG" ]; then
  echo "rm $IMG"
  rm $IMG
fi

echo "wget -q $IMG_URL"
wget -q $IMG_URL

if [ ! -d "$TMP_DIR" ]; then
  echo "mkdir $TMP_DIR"
  mkdir $TMP_DIR
fi

echo "guestmount -a $IMG -i $TMP_DIR"
guestmount -a $IMG -i $TMP_DIR

if [ "$?" != "0" ]; then
  echo "Failed to guestmount image"
  exit 1
fi

echo "sed -i \"s/name: centos/name: cloud/\" $TMP_DIR/etc/cloud/cloud.cfg"
sed -i "s/name: centos/name: cloud/" $TMP_DIR/etc/cloud/cloud.cfg

echo "sed -i \"s/- resizefs/- resolv-conf/\" $TMP_DIR/etc/cloud/cloud.cfg"
sed -i "s/- resizefs/- resolv-conf/" $TMP_DIR/etc/cloud/cloud.cfg

if [ ! -d "$TMP_DIR/etc/cloud/cloud.cfg.d" ]; then
    mkdir $TMP_DIR/etc/cloud/cloud.cfg.d
fi

cat << EOF >> $TMP_DIR/etc/cloud/cloud.cfg.d/00_datasource.cfg

EOF



echo "guestunmount $TMP_DIR"
guestunmount $TMP_DIR

echo "glance image-create ... $IMG ... $TMP_IMG_NAME"
glance image-create \
       --file $IMG \
       --disk-format qcow2 \
       --container-format bare \
       --name "$TMP_IMG_NAME"

TMP_IMG_ID="$(openstack image list --private | grep $TMP_IMG_NAME | tr "|" " " | tr -s " " | cut -d " " -f2)"
echo "TMP_IMG_ID for image '$TMP_IMG_NAME': $TMP_IMG_ID"

sed "s/TMP_IMAGE_ID/$TMP_IMG_ID/" $(dirname $0)/build-vars.template.yml > $(dirname $0)/build-vars.yml
sed -i "s/B_TARGET_NAME/$IMG_NAME/" $(dirname $0)/build-vars.yml


cd $(dirname $0)/..
./build.sh centos

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

pushd ../test-tools/pytesting_os/

nosetests --nologcapture

popd



#cd ../test-tools/pytesting/
#nosetests -sv

# FIXME: Actually delete images
# echo "======= Deleting deprecated images"
echo "======= Listing deprecated images"
openstack image list | grep -E "$BASENAME-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}" | tr "|" " " | tr -s " " | cut -d " " -f 3 | sort -r | awk 'NR>5' # | xargs -r openstack image delete

glance image-show $IMG_ID
