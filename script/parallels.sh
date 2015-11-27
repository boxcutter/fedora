#!/bin/bash -eux

if [[ $PACKER_BUILDER_TYPE =~ parallels ]]; then
    echo "==> Installing Parallels tools"

    mount -o loop /home/vagrant/prl-tools-lin.iso /mnt
    /mnt/install --install-unattended-with-deps
    umount /mnt
    rm -rf /home/vagrant/prl-tools-lin.iso
    rm -f /home/vagrant/.prlctl_version

    echo "==> Removing packages needed for building guest tools"
    ${PKG_MGR} -y remove gcc cpp kernel-devel kernel-headers perl
fi
