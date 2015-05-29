#!/bin/bash -eux

echo "==> Cleaning up dnf cache of metadata and packages to save space"
dnf -y clean all

rm -rf /tmp/*

echo "==> Zeroing out empty area to save space in the final image"
# Zero out the free space to save space in the final image.  Contiguous
# zeroed space compresses down to nothing.
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
