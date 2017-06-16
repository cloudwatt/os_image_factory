#!/bin/bash

#sudo apt-get install libs3-2
# ./cloudwattToFe.sh image_cloudwatt_name image_fe_name os_version
# os_version is "Ubuntu 16.04 server 64bit" ,"Ubuntu 14.04 server 64bit", "CentOS 7.3 64bit" ... juste the os_version was accepted by Flexible Engine


function check_bucket {

s3 list | grep $1 > /dev/null 2>&1
bucket_ret=$?
  if [ $bucket_ret -ne 0 ] ; then
    echo "------- could not find $1"
    echo "------- create the bucket $1"
    s3 create $1
  else
    echo "------- found $1"
  fi
  return $bucket_ret

}

IMAGE_NAME=$2
OS_VERSION=$3

MINDISK=40
BUCKET=images

IMG_ID=$(openstack image list | grep "$1" | awk {'print $2'})

echo "======= Download image to local disk"

glance image-download --file current.qcow2 $IMG_ID || exit 1

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
  echo "exist"
fi

s3 put $BUCKET/$IMAGE_NAME.qcow2 filename=current.qcow2 >& /dev/null

rm -rf current.qcow2

TOKEN=$(curl -i -k $OS_AUTH_URL/auth/tokens -H "Content-type: application/json" -X POST -d @<(cat <<EOF
{
"auth":{"identity":{"methods":["password"],"password":{"user":{"name":'$OS_USERNAME',"password":'$OS_PASSWORD',"domain":{"name":'$OS_DOMAIN_NAME'}}}},"scope":{"project":{"name":'$OS_TENANT_NAME'}}}
}
EOF
)  | grep "X-Subject-Token:"| cut -d : -f 2)


curl -sS https://ims.eu-west-0.prod-cloud-ocb.orange-business.com/v2/cloudimages/action -X POST -H 'Content-Type: application/json' -H 'Accept: application/json' -H "X-Auth-Token: $TOKEN" -H 'X-Language: en-us' -d @<(cat <<EOF
{"name": "$IMAGE_NAME",
"description": "Create an image using a file in the OBS bucket.",
"image_url": "$BUCKET:$IMAGE_NAME.qcow2",
"os_version": "$OS_VERSION",
"is_config_init":true,
"min_disk": $MINDISK,
"is_config":true}
EOF
)

sleep 20

ID=$(openstack image list | grep $IMAGE_NAME | awk {'print $2'})

if [ -z "$ID" ] ;then
exit 1
fi

status=$(glance image-show $ID | grep status |awk {'print $4'})

if [ -z "$status" ] ;then
exit 1
fi

while [ "$status" != "active" ]
do

echo "===========Wait for image will be active==========="
sleep 40
status=$(glance image-show $ID | grep status |awk {'print $4'})
done

echo "===================Finished the image ID on Fe is : "
echo $ID
