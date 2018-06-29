#!/bin/bash -eux

SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}

if [[ $PACKER_BUILDER_TYPE =~ virtualbox ]]; then
    echo "==> Installing VirtualBox guest additions"
    # Some of these packages should already have been installed in the kickstart
    dnf -y install kernel-headers-"$(uname -r)" kernel-devel-"$(uname -r)" gcc make perl
    # Need to set the KERN_DIR in Fedora 26 through 28 or the VBox additions will not install
    /usr/libexec/system-python -mplatform | grep -qi "fedora-2[678]" && echo "Fedora 26, 27 or 28 detected" && \
    KERN_DIR=/usr/src/kernels/"$(uname -r)" && export KERN_DIR
    VBOX_VERSION=$(cat $SSH_USER_HOME/.vbox_version)
    mount -o loop $SSH_USER_HOME/VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
    sh /mnt/VBoxLinuxAdditions.run --nox11
    umount /mnt
    rm -rf $SSH_USER_HOME/VBoxGuestAdditions_$VBOX_VERSION.iso
    rm -f $SSH_USER_HOME/.vbox_version
fi
