#!/bin/bash
#
# Script to create /etc/wtgc_version_id
#


VERSION_FILE=/etc/wtgc_version_id

echo ${IMAGE_NAME} >${VERSION_FILE}