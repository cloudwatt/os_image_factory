IMAGE="$URCHIN_IMG_ID"
TESTENV="./.current-run.env.sh"
FLAVOR_STD="n1.cw.standard-1"
FLAVOR_ALT="n1.cw.standard-2"
NETWORK="$FACTORY_NETWORK_ID"
FLOATING_IP_POOL="6ea98324-0f14-49f6-97c0-885d1b8dc517"
KEYPAIR="seconde"
PRIVATE_KEY="/var/lib/jenkins/.ssh/seconde.pem"
SSH_USER="cloud"
HOST="google.com"
LOG_FILE="/tmp/test-ubuntu.log"
USER_DATA_FILE="./userdata.yml"

# Floating IP pool to use
# packer openstack builder does not interpolate var for ip_pool
# so this value should also be put as-is in place in your packer files.
export FACTORY_FLOATING_IP_POOL="6ea98324-0f14-49f6-97c0-885d1b8dc517"



if [ -f "$TESTENV" ]; then
    . $TESTENV
fi
