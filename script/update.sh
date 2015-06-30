#!/bin/bash -eux
if [[ $UPDATE  =~ true || $UPDATE =~ 1 || $UPDATE =~ yes ]]; then
    echo "==> Applying updates"
    yum -y update

    if [ "$DISABLE_CNDN" = "true" ]; then
        echo "==> Disabling consistent network device names"
        sed -i 's/^\(GRUB_CMDLINE_LINUX=".*\)"/\1 net.ifnames=0"/' \
            /etc/default/grub
        grub2-mkconfig -o /boot/grub2/grub.cfg
    fi

    # reboot
    echo "Rebooting the machine..."
    reboot
    sleep 60
fi
