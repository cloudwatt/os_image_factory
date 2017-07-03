#!/bin/bash

STACK_NAME=$1
SSH_KEY_PATH=$2
shift 2

if [ ! "$STACK_NAME" ] || [ ! "$SSH_KEY_PATH" ] || [ ! "$@" ]; then
    echo "STACK_NAME and SSH_KEY_PATH parameters and at least one NEW_SSH_KEY are mandatory"
    echo -e """\
\e[32mUSAGE:\e[0m ./send-os-cred.sh STACK_NAME SSH_KEY_PATH NEW_SSH_KEY [NEW_SSH_KEY ...]
\e[32mEXAMPLE:\e[0m ./send-os-cred.sh backup-stack ~/.ssh/my_keypair.pem \\
                                        \$HOME/Downloads/some_key.pem \\
                                        /home/user/other_key.pub

In the above example, \e[32m~/.ssh/my_keypair.pem\e[0m will be used to authenticate
with the stack server, and the keys \e[32msome_key.pem\e[0m and \e[32mother_key.pub\e[0m will
be added to that server's \e[32m/root/.ssh/\e[0m directory for duplicity to use.
Existing keys with the same name will be replaced by the new keys.
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

# Add each new ssh key one by one
echo "Copying keys to stack server"
for SSH_KEY in "$@"; do
  if [ ! -r "$SSH_KEY" ]; then
    echo -e " - Key \e[32m${SSH_KEY}\e[0m does not exist or could not be read. Skipping..."
  else
    SSH_KEY_BASENAME=`basename "$SSH_KEY"`
    echo -e " - Copying \e[32m${SSH_KEY}\e[0m to remote \e[32m/root/.ssh/${SSH_KEY_BASENAME}\e[0m"
    ssh "$STACK_FLOATING_IP" -l cloud -i "$SSH_KEY_PATH" "sudo mkdir -p /home/cloud/.ssh"
    scp -o "IdentityFile=$SSH_KEY_PATH" "$SSH_KEY" "cloud@$STACK_FLOATING_IP:/home/cloud/.ssh/$SSH_KEY_BASENAME"
    ssh "$STACK_FLOATING_IP" -l cloud -i "$SSH_KEY_PATH" "sudo mkdir -p /root/.ssh"
    ssh "$STACK_FLOATING_IP" -l cloud -i "$SSH_KEY_PATH" "sudo mv \"/home/cloud/.ssh/${SSH_KEY_BASENAME}\" \"/root/.ssh/${SSH_KEY_BASENAME}\""
  fi
done
