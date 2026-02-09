#!/bin/bash
set -e

# Setup mock environment
MOCK_DIR="$(pwd)/tests/mocks"
rm -rf "$MOCK_DIR"
mkdir -p "$MOCK_DIR"

# Prepend MOCK_DIR to PATH
export PATH="$MOCK_DIR:$PATH"

# Set configuration variables for setup-disks.sh
export AI_WORKSPACE_DIR="$MOCK_DIR/ai-workspace"
export DATA_DIR="$MOCK_DIR/data"
export FSTAB_FILE="$MOCK_DIR/fstab"

# Create mock fstab
echo "# Initial fstab content" > "$FSTAB_FILE"

# Create mock sudo
cat << 'EOF' > "$MOCK_DIR/sudo"
#!/bin/bash
# If the first argument is a command flag like -E or -n, ignore it and shift
while [[ "$1" =~ ^- ]]; do
    shift
done

cmd="$1"
shift

if [[ "$cmd" == "blkid" ]]; then
    last_arg="${@: -1}"
    if [[ "$last_arg" == "/dev/nvme0n1p1" ]]; then
        echo "UUID-AI-WORKSPACE"
    elif [[ "$last_arg" == "/dev/nvme1n1p7" ]]; then
        echo "UUID-DATA"
    fi
elif [[ "$cmd" == "wipefs" || "$cmd" == "sgdisk" || "$cmd" == "mkfs.ext4" || "$cmd" == "mount" || "$cmd" == "chown" || "$cmd" == "fdisk" ]]; then
    # Do nothing for these commands
    :
elif [[ "$cmd" == "tee" ]]; then
    # Execute real tee
    tee "$@"
elif [[ "$cmd" == "cp" ]]; then
    # Execute real cp
    cp "$@"
elif [[ "$cmd" == "mkdir" ]]; then
    # Execute real mkdir
    mkdir "$@"
else
    # Fallback
    echo "Mock sudo: unhandled command: $cmd $@" >&2
fi
EOF
chmod +x "$MOCK_DIR/sudo"

# Mock lsblk
cat << 'EOF' > "$MOCK_DIR/lsblk"
#!/bin/bash
echo "NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT"
echo "nvme0n1     259:0    0 465.8G  0 disk "
echo "nvme1n1     259:1    0   3.6T  0 disk "
EOF
chmod +x "$MOCK_DIR/lsblk"

# Run setup-disks.sh twice
echo "Running setup-disks.sh first time..."
echo -e "yes\ny" | ./setup-disks.sh > /dev/null

echo "Running setup-disks.sh second time..."
echo -e "yes\ny" | ./setup-disks.sh > /dev/null

# Check for duplicate entries in the mock fstab
count=$(grep -c "UUID=UUID-AI-WORKSPACE" "$FSTAB_FILE")
echo "Entries found in fstab: $count"

if [[ "$count" -gt 1 ]]; then
    echo "FAIL: Duplicate entries found in fstab ($count)"
    cat "$FSTAB_FILE"
    exit 1
else
    echo "PASS: No duplicate entries found"
fi
