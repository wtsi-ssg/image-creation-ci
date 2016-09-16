#!/bin/bash
#
# Script to create /etc/wtgc_version_id
#


VERSION_FILE=/etc/wtgc_version_id
echo $image >${VERSION_FILE}
