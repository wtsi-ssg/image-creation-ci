#!/bin/bash -eux
echo hello
export
cat << EOF > /tmp/edit_sudo_ubuntu.sh
sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=adm' /etc/sudoers
sed -i -e 's/%adm ALL=(ALL) ALL/%adm ALL=NOPASSWD:ALL/g' /etc/sudoers
EOF
chmod 755 /tmp/edit_sudo_ubuntu.sh
if [ "$USER" == "ubuntu" ] ; then
 echo ubuntu | sudo -E -S bash /edit_sudo_ubuntu.sh
fi
true
