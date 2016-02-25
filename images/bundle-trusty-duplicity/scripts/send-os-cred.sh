#!/bin/bash

STACK_NAME=$1
SSH_KEY_PATH=$2

if [ ! "$STACK_NAME" ] || [ ! "$SSH_KEY_PATH" ]; then
    echo "STACK_NAME and SSH_KEY_PATH parameters are mandatory"
    echo "USAGE: ./send-os-cred.sh STACK_NAME SSH_KEY_PATH"
    exit 1
fi

if [ ! -r "$SSH_KEY_PATH" ]; then
  echo "ERROR: SSH Key does not exist or cannot be read.";
  exit 1;
fi

STACK_FLOATING_IP=` heat resource-list $STACK_NAME          \
                 | grep "| OS::Nova::FloatingIPAssociation" \
                 | cut -d"|" -f3                            \
                 | awk -F"-" '{print $NF}'                  \
                 `
if [ -z "$STACK_FLOATING_IP" ]; then
    echo "Stack floating-IP could not be found."
    heat resource-list $STACK_NAME
    exit 1
fi

ssh "$STACK_FLOATING_IP" -l cloud -i "$SSH_KEY_PATH" "echo \"Successfully echoed stack server.\""
if [ "$?" != "0" ]; then
    echo "Could not echo from stack server."
    exit 1
fi

echo -n "Enter Cloudwatt Email (for authentication): "
read -r EMAIL

echo -n "Enter Cloudwatt Password: "
read -rs PASSWORD
echo ""

curl -sf 'https://identity.fr1.cloudwatt.com/v2.0/tokens' \
     -X POST -H "Content-Type: application/json" \
     -H "Accept: application/json" \
     -d "{\"auth\": {\"tenantName\": \"\", \"passwordCredentials\": {\"username\": \"$EMAIL\", \"password\": \"$PASSWORD\"}}}" \
     > /dev/null
if [ "$?" != "0" ]; then
    echo "EMAIL and/or PASSWORD parameter is incorrect."
    exit 1
fi

ssh "$STACK_FLOATING_IP" -l cloud -i "$SSH_KEY_PATH" "sudo bash /etc/duplicity/set_os_cred.sh $EMAIL $PASSWORD"
