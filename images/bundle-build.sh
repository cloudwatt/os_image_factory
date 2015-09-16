#!/bin/sh

USAGE="\
bundle-build.sh BUNDLE_LABEL CLOUDWATT_BUNDLE_ID BUNDLE_PATH BUNDLE_SRC_IMG BUNDLE_IMG_OS [FACTORY_FLAVOR]

BUNDLE-PATH is relative to bundle-build.sh"

BASENAME=$1
CW_BUNDLE_ID=$2
BUNDLE_PATH=$3
SRC_IMG=$4
IMG_OS=$5
FACTORY_FLAVOR=$6

if [ ! "$BASENAME" ]; then
    echo "BUNDLE_LABEL parameter is mandatory"
    echo "$USAGE"
    exit 1
fi

if [ ! "$CW_BUNDLE_ID" ]; then
    echo "CLOUDWATT_BUNDLE_ID parameter is mandatory"
    echo "$USAGE"
    exit 1
fi

if [ ! "$BUNDLE_PATH" ]; then
    echo "BUNDLE_PATH parameter is mandatory"
    echo "$USAGE"
    exit 1
fi

if [ ! "$SRC_IMG" ]; then
    echo "BUNDLE_SRC_IMG parameter is mandatory"
    echo "$USAGE"
    exit 1
fi

if [ ! "$IMG_OS" ]; then
    echo "BUNDLE_IMG_OS parameter is mandatory"
    echo "$USAGE"
    exit 1
fi

if [ ! "$FACTORY_FLAVOR" ]; then
    FACTORY_FLAVOR="16"
fi

if [ ! "$OS_TENANT_ID" ]; then
    echo "OS_TENANT_ID env variable is mandatory"
    exit 1
fi

SELF_PATH=`dirname "$0"`

BUNDLE_PATH="$SELF_PATH/$BUNDLE_PATH"

PACKER_FILE="$SELF_PATH/bundle-bootstrap.packer.json"
BUILDMARK="$(date +%Y-%m-%d-%H%M)"
IMG_NAME="$BASENAME-$BUILDMARK"

echo "======= Packer provisionning..."

packer build -var "source_image=$SRC_IMG" -var "image_name=$IMG_NAME" -var "factory_flavor=$FACTORY_FLAVOR" $PACKER_FILE

echo "======= Glance upload done"

echo "======= Cleaning image properties"
IMG_ID="$(openstack image list --private | grep $IMG_NAME | tr "|" " " | tr -s " " | cut -d " " -f2)"

script -q -c "glance image-update \
    --property cw_bundle=$CW_BUNDLE_ID \
    --property cw_os=$IMG_OS \
    --property cw_origin=Cloudwatt \
    --property hw_rng_model=virtio \
    --min-disk 10 \
    --purge-props $IMG_ID 1>&2 > /dev/null" /dev/null

echo "======= Pruning unassociated floating ips"
FREE_FLOATING_IP="$(neutron floatingip-list | grep -v "+" | grep -v "id" | tr -d " " | grep -v -E "^\|.+\|.+\|.+\|.+\|$" | cut -d "|" -f 2)"
for floating_id in $FREE_FLOATING_IP; do
    neutron floatingip-delete $floating_id
done

echo "======= Deleting deprecated images"
glance image-list | grep -E "$BASENAME-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}" | tr "|" " " | tr -s " " | cut -d " " -f 3 | sort -r | awk 'NR>5' # | xargs -r glance image-delete

echo "======= Generating Heat Orchestration Templates"
if [ -d "$BUNDLE_PATH/target" ]; then
    rm -rf $BUNDLE_PATH/target
fi

mkdir $BUNDLE_PATH/target

# FIXME: 'bundle-trusty-dokuwiki.restore.heat.yml' didn't get image->$IMAGE$
for STACK in `find $BUNDLE_PATH/heat -type f -name "$BASENAME*.heat.yml"`; do
  sed "s/\\\$IMAGE\\\$/$IMG_ID/g" $STACK > $BUNDLE_PATH/target/$(basename $STACK)
done

echo "===================="
echo "======= BUILD RESULT"

glance image-show $IMG_ID
