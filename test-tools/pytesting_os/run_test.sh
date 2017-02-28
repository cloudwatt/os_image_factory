#!/usr/bin/env bash


# TODO: Check presence of env NOSE_IMAGE_ID and FACTORY_NETWORK_ID, NOSE_FLAVOR, NOSE_KEYPAIR
nosetests -sv

if [ "$?" != "0" ]; then
    os_test_cleaner.py
fi