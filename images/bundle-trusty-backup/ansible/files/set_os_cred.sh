#!/bin/bash

EMAIL=$1
PASSWORD=$2

if [ ! "$EMAIL" ] || [ ! "$PASSWORD" ]; then
    echo "EMAIL and PASSWORD parameters are mandatory"
    exit 1
fi

TENANT_ID =   `\
curl -s 'https://identity.fr1.cloudwatt.com/v2.0/tokens' \
     -X POST -H "Content-Type: application/json" \
     -H "Accept: application/json" \
     -d "{\"auth\": {\"tenantName\": \"\", \"passwordCredentials\": {\"username\": \"$EMAIL\", \"password\": \"$PASSWORD\"}}}" \
     | jq '.access.token.id' | xargs echo`
TENANT_NAME = `\
curl -s 'https://identity.fr1.cloudwatt.com/v2.0/tenants' \
     -X GET -H "User-Agent: python-keystoneclient" \
     -H "X-Auth-Token: $TENANT_ID" \
     | jq ".tenants[0].name" | xargs echo`

echo """\
#!/bin/bash

# OpenStack Credentials for Duplicity
export SWIFT_USERNAME="${TENANT_NAME}:${EMAIL}"
export SWIFT_PASSWORD="$PASSWORD"
export SWIFT_AUTHURL="https://identity.fr1.cloudwatt.com/v2.0/"
export SWIFT_AUTHVERSION="2"
""" > /etc/duplicity/export_os_cred.sh

chmod 755 /etc/duplicity/export_os_cred.sh

echo "File \"/etc/duplicity/export_os_cred.sh\" successfully updated."
