#!/bin/bash -eux
echo hello
export
#sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=adm' /etc/sudoers
#sed -i -e 's/%adm ALL=(ALL) ALL/%adm ALL=NOPASSWD:ALL/g' /etc/sudoers
true
