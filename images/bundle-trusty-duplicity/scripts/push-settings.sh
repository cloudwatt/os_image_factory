#!/bin/bash

STACK_NAME=$1
SSH_KEY_PATH=$2
SETTINGS_JSON_PATH=$3

if [ ! "$STACK_NAME" ] || [ ! "$SSH_KEY_PATH" ] || [ ! "$SETTINGS_JSON_PATH" ]; then
    echo "STACK_NAME and SSH_KEY_PATH parameters and SETTINGS_JSON_PATH are mandatory"
    echo -e """\
\e[32mUSAGE:\e[0m ./send-os-cred.sh STACK_NAME SSH_KEY_PATH SETTINGS_JSON_PATH
\e[32mEXAMPLE:\e[0m ./send-os-cred.sh backup-stack ~/.ssh/my_keypair.pem \\
                                        /home/user/somedir/backup_settings.json

In the above example, \e[32m~/.ssh/my_keypair.pem\e[0m will be used to
authenticate with the stack server, and backup_settings.json will be copied to
/home/cloud/backup_settings.json and used to reconfigure the server's
backup scheduler.
Existing settings will be replaced by the new settings.
"""
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
else
  echo -e "Stack floating-IP found: \e[32m${STACK_FLOATING_IP}\e[0m"
fi

ssh "$STACK_FLOATING_IP" -l cloud -i "$SSH_KEY_PATH" "echo \"Successfully echoed stack server.\""
if [ "$?" != "0" ]; then
    echo "Could not echo from stack server."
    exit 1
fi

echo "Copying settings file to stack server..."
scp -o "IdentityFile=$SSH_KEY_PATH" "$SETTINGS_JSON_PATH" "cloud@$STACK_FLOATING_IP:/home/cloud/backup_settings.json"
echo "Reconfiguring backup schedule..."
ssh "$STACK_FLOATING_IP" -l cloud -i "$SSH_KEY_PATH" "sudo bash /etc/duplicity/configure.sh /home/cloud/backup_settings.json"
echo "Removing copied remote settings file. (No longer needed.)"
ssh "$STACK_FLOATING_IP" -l cloud -i "$SSH_KEY_PATH" "rm /home/cloud/backup_settings.json"
echo "Done."
