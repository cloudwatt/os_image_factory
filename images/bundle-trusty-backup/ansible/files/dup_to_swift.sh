#!/bin/bash

# HANDLE PARAMS
#$REMOTE_IP
#$SSH_KEY
#$REMOTE_GROUPS
#$SRC
#$SWIFT_SIZE

SSH_KEYPATH="/root/.ssh/$SSH_KEY"

function ssh_cmd {
  # ssh_cmd $REMOTE_IP -l cloud -i $SSH_KEYPATH "$COMMAND"
  ssh "$1" -l cloud -i "$2" "$3"
}

# Add user `cloud` to each requested usergroup
NEW_GROUPS=""
for GROUP in $REMOTE_GROUPS ; do
  if ssh_cmd $REMOTE_IP $SSH_KEYPATH "groups cloud | grep &>/dev/null \"\b${GROUP}\b\""; then
    echo "User 'cloud' already in group '$GROUP'."
  else
    echo "Adding user 'cloud' to group '$GROUP'..."
    ssh_cmd $REMOTE_IP $SSH_KEYPATH "usermod -a -G $GROUP cloud"
    NEW_GROUPS="$GROUP $NEW_GROUPS"
  fi
done

# Get remote Hostname
REMOTE_HOSTNAME=`ssh_cmd $REMOTE_IP $SSH_KEYPATH "hostname"`
# Mount remote directory
mkdir -p /mnt/droplet
umount /mnt/droplet
echo "Mounting {REMOTE_IP}:/ to /mnt/droplet..."
sshfs -o "IdentityFile=$SSH_KEYPATH" "cloud@${REMOTE_IP}:/" /mnt/droplet
if [ "$?" != "0" ]; then echo "ERROR: Mount failed."; exit 1; fi

# OpenStack Credentials
source /etc/duplicity/export_os_cred.sh
# GnuPG Passphrase and Keys
source /etc/duplicity/dup_vars.sh
# Duplicity START
duplicity --verbosity notice           \
          --encrypt-key "$ENCRYPT_KEY" \
          --sign-key "$SIGN_KEY"       \
          --num-retries 3              \
          --exclude /mnt/droplet/mnt   \
          --exclude /mnt/droplet/proc  \
          --exclude /mnt/droplet/tmp   \
          --asynchronous-upload        \
          --volsize "$SWIFT_SIZE"      \
           "/mnt/droplet/${SRC}" "/$REMOTE_HOSTNAME/${SRC}"
          # --full-if-older-than 10D     \
# Duplicity END

# Unmount remote directory
echo "Unmounting /mnt/droplet..."
umount /mnt/droplet

# Remove user `cloud` from each group it was not already in
echo "Removing user 'cloud' from each group it was not already in..."
export LC_ALL=C
for GROUP in $NEW_GROUPS ; do
  ssh_cmd $REMOTE_IP $SSH_KEY "deluser cloud $GROUP"
done
