#!/usr/bin/env bash

source functions.sh

TOKEN=$(get_token)

image_id=1785fab9-c9ee-4132-88ab-751e5125acbb

delete_image $TOKEN $image_id

curl -i --insecure ' https://ims.$OS_REGION_NAME.prod-cloud-ocb.orange-business.com/v2/images/84ac7f2bbf19-4efb-86a0-b5be8771b476/file'
-X PUT -H "X-Auth-Token: $TOKEN" -H
"Content-Type:application/octet-stream" -T /mnt/userdisk/images/suse.zvhd



