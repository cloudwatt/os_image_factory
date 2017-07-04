#!/usr/bin/env bash


PASSWORD=Test@123

BUILDMARK="$(date +%Y-%m-%d-%H%M%S)"

AZ_NAME=eu-west-0a

source functions.sh

TOKEN=$(get_token)

#VPC_ID=$(create_vpc $TOKEN $BUILDMARK)

#NET_ID=$(create_net $TOKEN $VPC_ID $BUILDMARK)

#SUBNET_ID=$(openstack network show $NET_ID -f json | jq '.subnets' | sed -e 's/^"//'  -e 's/"$//')

#sleep 30

NET_ID=b5819521-1e15-465b-9e3e-306e5fffcb44

VPC_ID=d16d04b5-0d36-4cb4-b9a9-b518910a85b2

SUBNET_ID=90589dac-33bf-488d-951c-48feae02168f



#RDS_ID=$(create_rds $TOKEN $PASSWORD)

#echo "ssssss" $RDS_ID
#IP=$(get_ip_rds $TOKEN $RDS_ID)

#echo $IP":8635"
curl -sS https://rds.$OS_REGION_NAME.prod-cloud-ocb.orange-business.com/rds/v1/$OS_PROJECT_ID/instances -X POST -H 'Content-Type: application/json' -H 'Accept: application/json' -H "X-Auth-Token: $TOKEN" -H 'X-Language: en-us' -d @<(cat <<EOF
{
 "instance": {
 "name": "rds-$BUILDMARK-ha",
 "datastore": {
 "type": "MySQL",
 "version": "5.6.35"
 },
 "flavorRef": "c5cac226-b5d3-4169-a7e9-3c19369b4072",
 "volume": {
 "type": "COMMON",
 "size": 100
 },
 "region": "$OS_REGION_NAME",
 "availabilityZone": "$AZ_NAME",
 "vpc": "d16d04b5-0d36-4cb4-b9a9-b518910a85b2",
 "nics": {
 "subnetId": "b5819521-1e15-465b-9e3e-306e5fffcb44"
 },
 "securityGroup": {
 "id": "71c89962-34a1-45e1-b985-c481a0dfa23e"
 },
 "backupStrategy": {
 "startTime": "00:00:00",
 "keepDays": 3
 },
 "dbRtPd": "$PASSWORD",
 "ha": {
 "enable": true,
 "replicationMode": "async"
 }
 }
}

EOF
)


#heat stack-create wordpress-3-tiers-$BUILDMARK -f 3tiers.heat.yaml -Pkey_name="honey" -Pvpc_id="$VPC_ID" -Pnet_id="$NET_ID" -Psubnet_id="$SUBNET_ID"


#while ! nc -z $IP 8635; do
#  sleep 20
#  echo "Wait for ssh connexion will be established"
#done