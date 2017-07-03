#!/usr/bin/env bash
fe=$(echo $2 | tr '[:upper:]' '[:lower:]')

if [ $fe = true ] ; then

cd os_fe/$1/
sh build_fe.sh


else

cd os/$1/
sh build.sh


fi