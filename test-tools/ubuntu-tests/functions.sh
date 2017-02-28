TIMEOUT=180
SMALL_SLEEP=60
MINI_SLEEP=10
SLES=0
VOLUME_SIZE=1
REBOOT=0

wait_to_boot() {
    local vm_id=$1
    local ip=$2
    local count=1

    if [ $SLES -eq 1 ]; then
        count=2
    fi

    if [ $REBOOT -eq 1 ]; then
        count=1
    fi

    vm_state=`nova list | grep $vm_id | awk '{print $6}'`
    if [ "$vm_state" = "ERROR" ]; then
    	echo "TEST failed : server in error state"
	    return 1
    fi

    msg="Cloud-init .* finished at"

    RETRY=20

    while [[ $RETRY -gt 0 ]]; do

        n=$(nova console-log $vm_id | grep -i -c "$msg")

        if  [[ $n -lt $count ]]; then
            sleep 30
            RETRY=$(($RETRY - 1))
            continue
        fi

        if ping -w 1 -c 1 $ip &>/dev/null; then
            return 0
        else
            return 1
        fi
    done
    return 1
}


wait_vm_state() {

    local id=$1
    local state=$2
    local vm_state=`nova list | grep $id | awk '{print $6}'`

    while [ "$vm_state" != "$state" ]; do
        sleep $MINI_SLEEP
        vm_state=`nova list | grep $id | awk '{print $6}'`
        if [ "$vm_state" = "ERROR" ]; then
            return
        fi
    done
}


boot_vm() {

    local sg=$1
    local name=$2
    local key=$3
    local image=$4
    local flavor=$5
    local args=$6

    ID=`nova boot --flavor $flavor --image "$image" --key-name $key --security-groups $sg --nic net-id=$NETWORK $args $name | grep " id " | awk '{print $4}'`

    wait_vm_state $ID "ACTIVE"

    echo $ID
}

boot_vm_with_port_and_userdata() {

    local sg=$1
    local name=$2
    local key=$3
    local image="$4"
    local flavor=$5
    local port=$6
    local user_data=$7

    echo "BOOT_USERDATA = nova boot --flavor $flavor --image $image --key-name $key --security-groups $sg --nic port-id=$port --user-data $user_data $name"  >> $LOG_FILE 2>&1

    ID=`nova boot --flavor $flavor --image "$image" --key-name $key --security-groups $sg --nic port-id=$port --user-data $user_data $name | grep " id " | awk '{print $4}'`

    wait_vm_state $ID "ACTIVE"

    echo $ID
}

create_port() {

    local network=$1
    local sg=$2

    PORT_ID=`neutron port-create $network --security-group $sg| grep " id " | awk '{print $4}'`
    echo $PORT_ID

}

delete_port() {
    neutron port-delete $1
    sleep $MINI_SLEEP
}


get_floatingip_id() {
    echo `neutron floatingip-list | grep " $1 " | awk '{print $2}'`
}

create_floating_ip() {
    echo `neutron floatingip-create $FLOATING_IP_POOL | grep "floating_ip_address" | awk '{print $4}'`
}

associate_floating_to_vm() {

    local ip=$1
    local vm_id=$2

    nova floating-ip-associate $vm_id $ip

}

associate_floating_to_port() {

    local ip_id=$1
    local port_id=$2

    neutron floatingip-associate $ip_id $port_id
}



delete_floating_ip() {

    local ip=$1

    ID=`neutron floatingip-list | grep $ip | awk '{print $2}'`
    neutron floatingip-delete $ID
    sleep $MINI_SLEEP
}


create_test_sg() {

    RAND=$RANDOM
    SG_NAME="test-sg-$RAND"

    ID=`neutron security-group-create $SG_NAME | grep " id " | awk '{print $4}'`

    neutron security-group-rule-create --direction ingress --protocol tcp --port-range-min 22 --port-range-max 22 $ID >> $LOG_FILE 2>&1
    neutron security-group-rule-create --direction ingress --protocol icmp $ID >> $LOG_FILE 2>&1
    neutron security-group-rule-create --direction egress --protocol icmp $ID >> $LOG_FILE 2>&1

    echo $SG_NAME
}

create_keypair() {

    KEY_NAME="key-$RANDOM"
    ssh-keygen -t rsa -f $KEY_NAME -P ""
    private=`nova keypair-add --pub-key "./$KEY_NAME.pub" $KEY_NAME`
    echo $KEY_NAME
}

delete_keypair() {
    local key=$1

    nova keypair-delete $key
    rm -f $key $key.pub
}

delete_test_sg() {

    local sg=$1

    neutron security-group-delete $sg
    sleep $MINI_SLEEP
}

detach_delete_volume() {
    local vm_id=$1
    local volume_id=$2

    nova volume-detach $vm_id $volume_id

    V_STATUS=`openstack volume list | grep $VOLUME_ID | awk '{print $6}'`
    while [ "$V_STATUS" != "available" ] && [ "$V_STATUS" ]; do
      sleep $MINI_SLEEP
	    V_STATUS=`openstack volume list | grep $VOLUME_ID | awk '{print $6}'`
    done

    openstack volume delete $volume_id
}

create_attach_volume() {
    local vm_id=$1

    VOLUME_ID=$(openstack volume create --size 10 urchin-vol | grep -v "+" | grep " id " | awk '{print $4}')
    if [ "$VOLUME_ID" ]; then
      V_STATUS=`openstack volume list | grep $VOLUME_ID | awk '{print $6}'`
      while [ "$V_STATUS" != "available" ] && [ "$V_STATUS" ]; do
        sleep $MINI_SLEEP
  	    V_STATUS=`openstack volume list | grep $VOLUME_ID | awk '{print $6}'`
      done

      nova volume-attach $vm_id $VOLUME_ID /dev/vdb >> $LOG_FILE 2>&1

      echo "$VOLUME_ID"
    fi
}

ssh_vm_execute_cmd() {
    local key=$1
    local server=$2
    local cmd="$3"

    output=$(ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ConnectTimeout=10 -t -q -i $key $server $cmd)

    echo "$output"
}

delete_vm() {
    local vm_id=$1

    nova delete $vm_id

    sleep $MINI_SLEEP
}
