#!/bin/bash

set -e
echo "Factory"
echo "-----------------------"
if [[ -z "$OS_PASSWORD" ]]
then
  cat <<EOF
  You must set OS_USERNAME / OS_PASSWORD / OS_TENANT_NAME / OS_AUTH_URL ...
  The simple way to do this is to follow theses instructions:
  - Bring your Cloudwatt credentials and go to this url : https://console.cloudwatt.com/project/access_and_security/api_access/openrc/
  - If you are not connected, fill your Cloudwatt username / password
  - A file suffixed by openrc.sh will be downloaded, once complete, type in your terminal :
    source COMPUTE-[...]-openrc.sh
EOF
  exit 1
fi
cat <<EOF
Openstack credentials :
Username: ${OS_USERNAME}
Password: *************
Tenant name: ${OS_TENANT_NAME}
Authentication url: ${OS_AUTH_URL}
Region: ${OS_REGION_NAME}
-----------------------
EOF
KEYS=$(nova keypair-list | egrep '\|.*' | tail -n +2 | cut -d' ' -f 2)
echo "What is your keypair name ?"
select KEYPAIR in ${KEYS}
do
  echo "Key selected: $KEYPAIR"
  break;
done

read -p "How do you want to name this stack : " NAME
if [ "${NAME}" == "" ]; then echo "Name cannot be empty"; exit 1; fi


heat stack-create ${NAME} -f setup/os_image_factory.heat.yml -P openstack_username=${OS_USERNAME} -P openstack_password=${OS_PASSWORD} -P tenant_name=${OS_TENANT_NAME} -P keypair_name=${KEYPAIR}

until openstack stack show  ${NAME} 2> /dev/null | egrep 'CREATE_COMPLETE|CREATE_FAILED'
do
  echo "Waiting for stack to be ready..."
  sleep 10
done

if openstack stack show  ${NAME} 2> /dev/null | grep CREATE_FAILED
then
  echo "Error while creating stack"
  exit 1
fi

for output in $(openstack stack output list  ${NAME} 2> /dev/null | egrep '\|.*' | tail -n +2 | cut -d' ' -f 2)
do
  echo "$output: $(openstack stack output show ${NAME} ${output} 2> /dev/null)"
done