#!/bin/sh

IMG_UBUNTU_TRUSTY="ae3082cb-fac1-46b1-97aa-507aaa8f184f"
SELF_PATH=`dirname "$0"`

# bundle-build.sh BASENAME CW_BUNDLE_ID BUNDLE_PATH SRC_IMG IMG_OS
bash "$SELF_PATH/../bundle-build.sh" "bundle-trusty-lamp" "LAMP" "bundle-trusty-lamp" "$IMG_UBUNTU_TRUSTY" "Ubuntu"
