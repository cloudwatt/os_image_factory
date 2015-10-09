#!/bin/bash

# HANDLE PARAMS:
#$REMOTE_IP
#$SSH_KEY
#$REMOTE_GROUPS
#$SRC
#$SWIFT_SIZE

REMOTE_IP=$1
SSH_KEY=$2
SRC=$3
REMOTE_GROUPS=$4
PRE_SCRIPT=$5
POST_SCRIPT=$6
ADD_PARAMS=$7

if [ ! "$REMOTE_IP" ] || [ ! "$SSH_KEY" ] || [ ! "$SRC" ]; then
  echo -e """\
\e[32mUSAGE:\e[0m sudo /etc/duplicity/to_swift.sh REMOTE_IP SSH_KEY SRC [REMOTE_GROUPS [PRE_SCRIPT [POST_SCRIPT [ADD_PARAMS]]]]

REMOTE_IP     - IP address for remote server to backup
SSH_KEY       - SSH key for remote server
REMOTE_GROUPS - Usergroups to add to user 'cloud' on remote server
SRC           - Path to file or directory to back up
PRE_SCRIPT    - Shell script to run on remote server before backup
POST_SCRIPT   - Shell script to run on remote server after backup
ADD_PARAMS    - Additional duplicity parameters

\e[32mEXAMPLE:\e[0m sudo /etc/duplicity/to_swift.sh 8.8.8.8 \\
                                         ssh_key.pem \\
                                         /home/cloud \\
                                         \"root www-data\" \\
                                         \"sudo service apache stop;\" \\
                                         \"sudo service apache start;\" \\
                                         \"--volsize 10\"
"""
  exit 1
fi

SSH_KEY_PATH="/root/.ssh/$SSH_KEY"

if [ ! -r "$SSH_KEY_PATH" ]; then
  echo "ERROR: SSH Key does not exist or cannot be read.";
  exit 1;
fi

function ssh_cmd {
  # ssh_cmd $REMOTE_IP -l cloud -i $SSH_KEY_PATH "$COMMAND"
  ssh "$1" -l cloud -i "$2" "$3"
}

ssh_cmd $REMOTE_IP $SSH_KEY_PATH "echo \"Successfully echoed remote server.\""
if [ "$?" != "0" ]; then
  echo "Could not echo from remote server."
  exit 1
fi

if [ -n $PRE_SCRIPT ]; then
  echo "Running pre-backup shell script on remote:"
  echo "$PRE_SCRIPT"
  echo "@=============@"
  ssh_cmd $REMOTE_IP $SSH_KEY_PATH "$PRE_SCRIPT"
  echo "@=============@"
  exit 1
else
  echo "No pre-backup shell script provided. Skipping."
fi

echo "Adding user 'cloud' to each requested usergroup."
NEW_GROUPS=""
for GROUP in $REMOTE_GROUPS ; do
  if ssh_cmd $REMOTE_IP $SSH_KEY_PATH "groups cloud | grep &>/dev/null \"\b${GROUP}\b\""; then
    echo " - User 'cloud' already in group '$GROUP'."
  else
    echo " - Adding user 'cloud' to group '$GROUP'..."
    ssh_cmd $REMOTE_IP $SSH_KEY_PATH "usermod -a -G $GROUP cloud"
    NEW_GROUPS="$GROUP $NEW_GROUPS"
  fi
done

mkdir -p /mnt/droplet
umount /mnt/droplet
echo "Mounting {REMOTE_IP}:/ to /mnt/droplet..."
sshfs -o "IdentityFile=$SSH_KEY_PATH" "cloud@${REMOTE_IP}:/" /mnt/droplet

if [ "$?" != "0" ]; then
  echo "ERROR: Mount failed."
  exit 1
elif [ ! -a "/mnt/droplet/${SRC}" ]; then
  echo """\
ERROR: Target file or directory not found: /mnt/droplet/${SRC}
Unmounting /mnt/droplet...
"""
  umount /mnt/droplet
  echo "Removing user 'cloud' from each group it was not already in..."
  export LC_ALL=C
  for GROUP in $NEW_GROUPS ; do
    ssh_cmd $REMOTE_IP $SSH_KEY "deluser cloud $GROUP"
  done
  echo "Exiting."
  exit 1
fi

REMOTE_HOSTNAME=`ssh_cmd $REMOTE_IP $SSH_KEY_PATH "hostname"`

# OpenStack Credentials
source /etc/duplicity/export_os_cred.sh
# GnuPG Passphrase and Keys
source /etc/duplicity/dup_vars.sh
# Duplicity START
echo "Remote Hostname: $REMOTE_HOSTNAME"
echo "Local Hostname:  $(hostname)"
echo "Backing up /mnt/droplet/${SRC} to swift://$(hostname)/$REMOTE_HOSTNAME/${SRC}"
duplicity --verbosity notice           \
          --encrypt-key "$ENCRYPT_KEY" \
          --sign-key "$SIGN_KEY"       \
          --num-retries 3              \
          --exclude /mnt/droplet/mnt   \
          --exclude /mnt/droplet/proc  \
          --exclude /mnt/droplet/tmp   \
          --asynchronous-upload        \
          $ADD_PARAMS                  \
          "/mnt/droplet/${SRC}" "swift://$(hostname)/$REMOTE_HOSTNAME/${SRC}"
          # --full-if-older-than 10D     \
# Duplicity END

echo "Unmounting /mnt/droplet..."
umount /mnt/droplet

echo "Removing user 'cloud' from each group it was not already in..."
export LC_ALL=C
for GROUP in $NEW_GROUPS ; do
  ssh_cmd $REMOTE_IP $SSH_KEY "deluser cloud $GROUP"
done

if [ -n $POST_SCRIPT ]; then
  echo "Running post-backup shell script on remote:"
  echo "$POST_SCRIPT"
  echo "@=============@"
  ssh_cmd $REMOTE_IP $SSH_KEY_PATH "$POST_SCRIPT"
  echo "@=============@"
  exit 1
else
  echo "No post-backup shell script provided. Skipping."
fi
