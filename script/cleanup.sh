#!/bin/bash -eux

echo "==> Cleaning up yum cache of metadata and packages to save space"
yum -y clean all

rm -rf /tmp/*

echo "==> Zeroing out empty area to save space in the final image"
# Zero out the free space to save space in the final image.  Contiguous
# zeroed space compresses down to nothing.
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
