#!/bin/bash

function check_bucket {

s3 list | grep $1 > /dev/null 2>&1
bucket_ret=$?
  if [ $bucket_ret -ne 0 ] ; then
    echo "------- could not find $1"
    echo "------- create the bucket $1"
  else
    echo "------- found $1"
  fi
  return $bucket_ret

}



function get_token {
token=$(curl -i -k $OS_AUTH_URL/auth/tokens -H "Content-type: application/json" -X POST -d @<(cat <<EOF
{
"auth":{"identity":{"methods":["password"],"password":{"user":{"name":'$OS_USERNAME',"password":'$OS_PASSWORD',"domain":{"name":'$OS_DOMAIN_NAME'}}}},"scope":{"project":{"name":'$OS_TENANT_NAME'}}}
}
EOF
) | grep "X-Subject-Token:"| cut -d : -f 2)

echo $token
}



function create_image_via_s3 {

#create_image_via_s3 $TOKEN
curl -sS https://ims.$OS_REGION_NAME.prod-cloud-ocb.orange-business.com/v2/cloudimages/action -X POST -H 'Content-Type: application/json' -H 'Accept: application/json' -H "X-Auth-Token: $1" -H 'X-Language: en-us' -d @<(cat <<EOF
{"name": "$TMP_IMG_NAME",
"description": "Create an image using a file in the OBS bucket.",
"image_url": "$BUCKET:$TMP_IMG_NAME.qcow2",
"os_version": "$OS_VERSION",
"is_config_init":true,
"min_disk": $MINDISK,
"min_ram": $MINRAM,
"is_config":true}
EOF
)

}

function wait_image_active {

if [ -z $1 ]
 then
  exit 1
fi

status=$(openstack image show $1 | grep status |awk {'print $4'})>/dev/null 2>&1

while [ "$status" != "active" ]
do
sleep 40
status=$(openstack image show $1 | grep status |awk {'print $4'})>/dev/null 2>&1
done

}


function create_image_via_ecs {
#create_image_via_ecs $TOKEN $IMG_NAME $SERVER_NAME

openstack server stop $3

status=$(openstack server list | grep $3 |  awk {'print $6'})>/dev/null 2>&1

while [ "$status" != "SHUTOFF" ]
do
sleep 20
status=$(openstack server list | grep $3 |  awk {'print $6'})>/dev/null 2>&1
done

SERVER_ID=$(openstack server show $3 -f json |jq '.id' | sed -e 's/^"//'  -e 's/"$//')>/dev/null 2>&1

curl -sS https://ims.$OS_REGION_NAME.prod-cloud-ocb.orange-business.com/v2/cloudimages/action -X POST -H 'Content-Type: application/json' -H 'Accept: application/json' -H "X-Auth-Token: $1" -H 'X-Language: en-us' -d @<(cat <<EOF
{
"name": "$2",
"description":"Create an image using an ECS.",
"instance_id": "$SERVER_ID"
}
EOF
)>/dev/null 2>&1

sleep 10

ID=$(openstack image list | grep "$2" | awk {'print $2'})>/dev/null 2>&1

wait_image_active $ID

glance image-update $ID --property  schema=/v2/schemas/image --min-ram $MINRAM>/dev/null 2>&1

echo $ID

}



function delete_image {

#delete_image $token $image_id

curl -sS https://ims.$OS_REGION_NAME.prod-cloud-ocb.orange-business.com/v2/images/$2 -X DELETE -H "Accept: application/json" -H "X-Auth-Token: $1" >/dev/null 2>&1

}


function ansible_bootstrap {

#$1 is floating ip

while ! </dev/tcp/$1/22; do
  sleep 20
  echo "Wait for ssh connexion will be established"
done

 cat << EOF > host_inventory
[local]
$1 ansible_ssh_user=cloud ansible_ssh_private_key_file=~/mykey-${BUILDMARK}.pem
EOF
export ANSIBLE_HOST_KEY_CHECKING=False

 if [ -z $2 ]
   then
   ansible-playbook ./ansible/bootstrap.yml -i host_inventory
   if [ "$?" != "0" ]; then
    echo "Ansible failed"
    exit 1
   fi
 else
    ansible-playbook ./$2/ansible/bootstrap.yml -i host_inventory
    if [ "$?" != "0" ]; then
     echo "Ansible failed"
     exit 1
    fi
    ansible-playbook purge_image_fe.yml -i host_inventory
 fi


rm -f host_inventory


}


function create_keypair {

openstack keypair create mykey-$1 > ~/mykey-$1.pem
chmod 600 ~/mykey-$1.pem

}

function delete_keypair {

openstack keypair delete mykey-$1>/dev/null 2>&1

rm -f ~/mykey-$1.pem

}


function create_vpc {
#create_vpc $TOKEN

curl -sS  https://vpc.eu-west-0.prod-cloud-ocb.orange-business.com/v1/$OS_PROJECT_ID/vpcs -X POST -H 'Content-Type: application/json' -H 'Accept: application/json' -H "X-Auth-Token: $1" -H 'X-Language: en-us' -d @<(cat <<EOF
{
 "vpc":
 {
 "name": "vpc-$2",
 "cidr": "10.20.30.0/24"
 }
}
EOF
) | jq '.vpc.id' | sed -e 's/^"//'  -e 's/"$//'

}

function create_net {

#create_subnet $TOKEN $VPC_ID

curl -sS https://vpc.$OS_REGION_NAME.prod-cloud-ocb.orange-business.com/v1/$OS_PROJECT_ID/subnets -X POST -H 'Content-Type: application/json' -H 'Accept: application/json' -H "X-Auth-Token: $1" -H 'X-Language: en-us' -d @<(cat <<EOF
{
 "subnet":
 {
 "name": "subnet-$3",
 "cidr": "10.20.30.0/24",
 "gateway_ip": "10.20.30.1",
 "dhcp_enable": "true",
 "primary_dns": "100.125.0.41",
 "secondary_dns": "100.126.0.41",
 "availability_zone":"$AZ_NAME",
 "vpc_id":"$2"
 }
}
EOF
) | jq '.subnet.id' | sed -e 's/^"//'  -e 's/"$//'

}



function delete_all_net {
#delete_all_net $TOKEN $VPC_ID $NET_ID

curl -sS https://vpc.$OS_REGION_NAME.prod-cloud-ocb.orange-business.com/v1/$OS_PROJECT_ID/vpcs/$2/subnets/$3 -X DELETE -H "Accept: application/json" -H "X-Auth-Token: $1" >/dev/null 2>&1

sleep 10

#delete vpc
curl -sS https://vpc.$OS_REGION_NAME.prod-cloud-ocb.orange-business.com/v1/$OS_PROJECT_ID/vpcs/$2 -X DELETE -H "Accept: application/json" -H "X-Auth-Token: $1" >/dev/null 2>&1


}

function release_floating_ip {

echo "======= Release floating IPs"

FREE_FLOATING_IP="$(neutron floatingip-list | grep -v "+" | grep -v "id" | tr -d " " | grep -v -E "^\|.+\|.+\|.+\|.+\|$" | cut -d "|" -f 2)">/dev/null 2>&1

for floating_id in $FREE_FLOATING_IP; do

  echo "floating id should be deleted"

  neutron floatingip-delete $floating_id >/dev/null 2>&1

done

}


