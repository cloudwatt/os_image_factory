#!/bin/bash

STACK_NAME=$1
SSH_KEY_PATH=$2

if [ ! "$STACK_NAME" ] || [ ! "$SSH_KEY_PATH" ]; then
    echo "STACK_NAME and SSH_KEY_PATH to connect with SSH to server are mandatory."
    echo -e """\
\e[32mUSAGE:\e[0m ./send-os-cred.sh STACK_NAME SSH_KEY_PATH

Back up both of Duplicity's GnuPG keys (signing and encryption)
to two files in your current directory.
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

source <(ssh "$STACK_FLOATING_IP" -l cloud -i "$SSH_KEY_PATH" "sudo cat /etc/duplicity/dup_vars.sh")
ssh "$STACK_FLOATING_IP" -l cloud -i "$SSH_KEY_PATH" "sudo gpg --export-secret-keys -a $SIGN_KEY"    > signing.asc
ssh "$STACK_FLOATING_IP" -l cloud -i "$SSH_KEY_PATH" "sudo gpg --export-secret-keys -a $ENCRYPT_KEY" > encryption.asc
