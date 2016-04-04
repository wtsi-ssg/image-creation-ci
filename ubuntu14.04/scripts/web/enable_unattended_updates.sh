##----------------------------------------------------------------------
## web/enable_unattended_updates.sh
##----------------------------------------------------------------------

## Enable automatic updates

echo 'Unattended-Upgrade::Allowed-Origins {'        >  /etc/apt/apt.conf.d/51my-unattended-upgrades
echo '  "${distro_id}:${distro_codename}-updates";' >> /etc/apt/apt.conf.d/51my-unattended-upgrades
echo '];'                                           >> /etc/apt/apt.conf.d/51my-unattended-upgrades
