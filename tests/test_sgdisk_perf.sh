#!/bin/bash

# Create a test image
dd if=/dev/zero of=test_disk.img bs=1M count=100 2>/dev/null

echo "Creating partitions..."
sgdisk -o test_disk.img >/dev/null
sgdisk -n 1:0:+10M test_disk.img >/dev/null
sgdisk -n 2:0:+10M test_disk.img >/dev/null
sgdisk -n 3:0:+10M test_disk.img >/dev/null
sgdisk -n 4:0:+10M test_disk.img >/dev/null

echo "Timing separate deletions..."
time {
    sgdisk -d 2 test_disk.img >/dev/null
    sgdisk -d 3 test_disk.img >/dev/null
    sgdisk -d 4 test_disk.img >/dev/null
}

echo "Recreating partitions..."
sgdisk -n 2:0:+10M test_disk.img >/dev/null
sgdisk -n 3:0:+10M test_disk.img >/dev/null
sgdisk -n 4:0:+10M test_disk.img >/dev/null

echo "Timing combined deletion..."
time {
    sgdisk -d 2 -d 3 -d 4 test_disk.img >/dev/null
}

rm test_disk.img
