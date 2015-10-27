#!/bin/bash

# HANDLE PARAMS:
#$REMOTE_IP
#$SSH_KEY
#$REMOTE_GROUPS
#$SRC
#$SWIFT_SIZE

echo -e "\e[32m=== Starting a Duplicity Swift Restore ===\e[0m"

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

REMOTE_IP     - IP address for remote server to restore
SSH_KEY       - SSH key for remote server
REMOTE_GROUPS - Usergroups to add to user 'cloud' on remote server
SRC           - Path to file or directory to restore
PRE_SCRIPT    - Shell script to run on remote server before restore
POST_SCRIPT   - Shell script to run on remote server after restore
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

rm -Rf   /tmp/dup_tmp
mkdir -p /tmp/dup_tmp

echo "Fetching OpenStack Credentials..."
source /etc/duplicity/export_os_cred.sh
echo "Fetching GnuPG Keys..."
source /etc/duplicity/dup_vars.sh
echo "Fetching remote hostname..."
REMOTE_HOSTNAME=`ssh_cmd $REMOTE_IP $SSH_KEY_PATH "hostname"`
echo "Remote Hostname: $REMOTE_HOSTNAME"
echo "Local Hostname:  $(hostname)"
SWIFT_URL="swift://$(hostname)__${REMOTE_HOSTNAME}_$(echo $SRC | tr "/" "_")"

echo "Restoring $SWIFT_URL to /tmp/dup_tmp/${SRC}"
echo -e "\e[92m@== Duplicity START ==@\e[0m"
HOME=/root \
duplicity --verbosity notice           \
          --encrypt-key "$ENCRYPT_KEY" \
          --sign-key "$SIGN_KEY"       \
          --num-retries 3              \
          --asynchronous-upload        \
          $ADD_PARAMS                  \
          "$SWIFT_URL" "/tmp/dup_tmp/${SRC}"
if [ "$?" != "0" ]; then
  echo -e "\e[92mDuplicity encountered an error! Cancelling restore.\e[0m"
  exit 1
fi
echo -e "\e[92m@==  Duplicity END  ==@\e[0m"

echo "Removing old /tmp/restore.tar if present..."
rm -Rf    /tmp/restore.tar
echo "Compressing /tmp/dup_tmp into restore.tar..."
tar -vcpf /tmp/restore.tar -C /tmp/dup_tmp . --remove-files
echo "Removing vestigal /tmp/dup_tmp directory..."
rm -Rf    /tmp/dup_tmp
echo "Removing old /tmp/restore.tar on remote if present."
ssh_cmd $REMOTE_IP $SSH_KEY_PATH "sudo rm /tmp/restore.tar"

if [ -n "$PRE_SCRIPT" ]; then
  echo "Running pre-restore shell script on remote:"
  echo "$PRE_SCRIPT"
  echo "@== OUTPUT START ==@"
  ssh_cmd $REMOTE_IP $SSH_KEY_PATH "$PRE_SCRIPT"
  echo "@==  OUTPUT END  ==@"
else
  echo "No pre-restore shell script provided. Skipping."
fi

echo "Copying restore.tar to remote..."
scp -o "IdentityFile=$SSH_KEY_PATH" /tmp/restore.tar "cloud@$REMOTE_IP:/tmp/restore.tar"
echo "Extracting restore.tar on remote..."
ssh_cmd $REMOTE_IP $SSH_KEY_PATH "sudo tar -vxpf /tmp/restore.tar -C / --overwrite"
echo "Removing restore.tar on remote."
ssh_cmd $REMOTE_IP $SSH_KEY_PATH "sudo rm /tmp/restore.tar"

if [ -n "$POST_SCRIPT" ]; then
  echo "Running post-restore shell script on remote:"
  echo "$POST_SCRIPT"
  echo "@== OUTPUT START ==@"
  ssh_cmd $REMOTE_IP $SSH_KEY_PATH "$POST_SCRIPT"
  echo "@==  OUTPUT END  ==@"
else
  echo "No post-restore shell script provided. Skipping."
fi

echo -e "\e[32m===   End of Duplicity Swift Restore   ===\e[0m"
