#!/bin/bash -eux

if [[ $PACKER_BUILDER_TYPE =~ virtualbox ]]; then
    echo "==> Installing VirtualBox guest additions"
    # Assume that we've installed all the prerequisites:
    # kernel-headers-$(uname -r) kernel-devel-$(uname -r) gcc make perl
    # from the install media via ks.cfg
    # Except on Fedora 22 (which uses dnf)
    if [ "${PKG_MGR}" == "dnf" ]; then
        ${PKG_MGR} -y install kernel-headers-$(uname -r) kernel-devel-$(uname -r) gcc make perl
    fi

    VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
    mount -o loop /home/vagrant/VBoxGuestAdditions_${VBOX_VERSION}.iso /mnt
    sh /mnt/VBoxLinuxAdditions.run --nox11
    umount /mnt
    rm -rf /home/vagrant/VBoxGuestAdditions_${VBOX_VERSION}.iso
    rm -f /home/vagrant/.vbox_version

    echo "==> Removing packages needed for building guest tools"
    ${PKG_MGR} -y remove gcc cpp kernel-devel kernel-headers perl
fi
