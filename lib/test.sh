#!/usr/bin/env bash

source functions.sh

TOKEN=$(get_token)

image_id=1785fab9-c9ee-4132-88ab-751e5125acbb

delete_image $TOKEN $image_id

