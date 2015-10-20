#!/bin/bash

# HANDLE PARAMS:
#$REMOTE_IP
#$SSH_KEY
#$REMOTE_GROUPS
#$SRC
#$SWIFT_SIZE

echo -e "\e[32m=== Starting a Duplicity Swift Backup ===\e[0m"

function json_value {
  # json_value $JSON_INPUT $JSON_PATH
  jq -r "$2 // empty" <<< "$1"
}

if [ -n "$1" ] && [ ! "$2" ]; then
  echo "Json data passed as parameter."
  REMOTE_IP=`    json_value "$1" ".remote_ip"`
  SSH_KEY=`      json_value "$1" ".ssh_key"`
  SRC=`          json_value "$1" ".remote_path"`
  if [ -z "$SRC" ]; then SRC="/"; fi
  REMOTE_GROUPS=`json_value "$1" ".user_groups"`
  PRE_SCRIPT=`   json_value "$1" ".shell_script.before"`
  POST_SCRIPT=`  json_value "$1" ".shell_script.after"`
  ADD_PARAMS=`   json_value "$1" ".additional_duplicity_options"`
else
  REMOTE_IP=$1
  SSH_KEY=$2
  SRC=$3
  REMOTE_GROUPS=$4
  PRE_SCRIPT=$5
  POST_SCRIPT=$6
  ADD_PARAMS=$7
fi

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
  echo "ERROR: SSH Key does not exist or cannot be read."
  exit 1
fi

function ssh_cmd {
  # ssh_cmd $REMOTE_IP -l cloud -i $SSH_KEY_PATH "$COMMAND"
  ssh "$1" -l cloud -i "$2" "$3"
}

echo "Echoing remote server..."
ssh_cmd $REMOTE_IP $SSH_KEY_PATH "echo \"Successfully echoed remote server.\""
if [ "$?" != "0" ]; then
  echo "Could not echo from remote server."
  exit 1
fi

echo "Expanding remote path..."
NEW_SRC=`ssh_cmd $REMOTE_IP $SSH_KEY_PATH "sudo readlink -f $SRC"`
if [ "$?" != "0" ]; then
  echo "Remote path '$SRC' failed to expand."
  echo "Path may be incorrect or directories may not exist."
  exit 1
fi
echo "Remote path expanded from '$SRC' to '$NEW_SRC'."
SRC="$NEW_SRC"
if [ "$SRC" == "/" ]; then
  echo "Remote path includes server root:"
  echo "Excluding '/dev', '/mnt', '/proc', and '/tmp' to avoid summoning Cthulu."
  ADD_PARAMS="$ADD_PARAMS --exclude /mnt/droplet/dev  \
                          --exclude /mnt/droplet/mnt  \
                          --exclude /mnt/droplet/proc \
                          --exclude /mnt/droplet/tmp"
fi

if [ -n "$PRE_SCRIPT" ]; then
  echo "Running pre-backup shell script on remote:"
  echo "$PRE_SCRIPT"
  echo "@== OUTPUT START ==@"
  ssh_cmd $REMOTE_IP $SSH_KEY_PATH "$PRE_SCRIPT"
  echo "@==  OUTPUT END  ==@"
else
  echo "No pre-backup shell script provided. Skipping."
fi

echo "Adding user 'cloud' to each requested usergroup."
NEW_GROUPS=""
unset IFS
for GROUP in $REMOTE_GROUPS ; do
  if ssh_cmd $REMOTE_IP $SSH_KEY_PATH "groups cloud | grep &>/dev/null \"\b${GROUP}\b\""; then
    echo " - User 'cloud' already in group '$GROUP'."
  else
    echo " - Adding user 'cloud' to group '$GROUP'..."
    ssh_cmd $REMOTE_IP $SSH_KEY_PATH "sudo usermod -a -G $GROUP cloud"
    NEW_GROUPS="$GROUP $NEW_GROUPS"
  fi
done

mkdir -p /mnt/droplet
umount /mnt/droplet
echo "Mounting ${REMOTE_IP}:/ to /mnt/droplet..."
sshfs -o "IdentityFile=$SSH_KEY_PATH" "cloud@${REMOTE_IP}:/" /mnt/droplet

if [ "$?" != "0" ]; then
  echo "ERROR: Mount failed."
elif [ ! -e "/mnt/droplet/${SRC}" ]; then
  echo "ERROR: Target file or directory not found: /mnt/droplet/${SRC}"
else
  echo "Mount successful."
  echo "Fetching OpenStack Credentials..."
  source /etc/duplicity/export_os_cred.sh
  echo "Fetching GnuPG Keys..."
  source /etc/duplicity/dup_vars.sh
  echo "Fetching remote hostname..."
  REMOTE_HOSTNAME=`ssh_cmd $REMOTE_IP $SSH_KEY_PATH "hostname"`
  echo "Remote Hostname: $REMOTE_HOSTNAME"
  echo "Local Hostname:  $(hostname)"
  SWIFT_URL="swift://$(hostname)__${REMOTE_HOSTNAME}_$(echo $SRC | tr "/" "_")"

  echo "Backing up /mnt/droplet/${SRC} to $SWIFT_URL"
  echo -e "\e[32m@== Duplicity START ==@\e[0m"
  HOME=/root \
  duplicity --verbosity notice           \
            --encrypt-key "$ENCRYPT_KEY" \
            --sign-key "$SIGN_KEY"       \
            --num-retries 3              \
            --asynchronous-upload        \
            $ADD_PARAMS                  \
            "/mnt/droplet/${SRC}" "$SWIFT_URL"
            # --full-if-older-than 10D     \
  echo -e "\e[32m@==  Duplicity END  ==@\e[0m"
fi

echo "Unmounting /mnt/droplet..."
umount /mnt/droplet

if [ -n "$NEW_GROUPS" ]; then
  echo "Removing user 'cloud' from each group it was not already in..."
  export LC_ALL=C
  for GROUP in $NEW_GROUPS ; do
    ssh_cmd $REMOTE_IP $SSH_KEY_PATH "sudo deluser cloud $GROUP"
  done
else
  echo "No groups to remove user 'cloud' from."
fi

if [ -n "$POST_SCRIPT" ]; then
  echo "Running post-backup shell script on remote:"
  echo "$POST_SCRIPT"
  echo "@== OUTPUT START ==@"
  ssh_cmd $REMOTE_IP $SSH_KEY_PATH "$POST_SCRIPT"
  echo "@==  OUTPUT END  ==@"
else
  echo "No post-backup shell script provided. Skipping."
fi

echo -e "\e[32m===   End of Duplicity Swift Backup   ===\e[0m"
