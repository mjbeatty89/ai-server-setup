#!/bin/bash
set -e

# Mock UUIDs
UUID_AI="mock-uuid-ai"
UUID_DATA="mock-uuid-data"
FSTAB="fstab.tmp"
YELLOW='\033[1;33m'
NC='\033[0m'

# Cleanup function
cleanup() {
    rm -f "$FSTAB"
}
trap cleanup EXIT

# Initialize fstab
echo "# Default fstab" > "$FSTAB"
echo "UUID=original-root / ext4 defaults 0 1" >> "$FSTAB"

echo "Initial content:"
cat "$FSTAB"
echo "----------------"

# Function simulating the fix logic
run_fix_logic() {
    echo "Running fix logic..."

    # Check if the header comment exists
    if ! grep -q "AI Server Storage Configuration" "$FSTAB"; then
        echo "" | tee -a "$FSTAB"
        echo "# AI Server Storage Configuration" | tee -a "$FSTAB"
    fi

    # Check for /ai-workspace
    if grep -q "[[:space:]]/ai-workspace[[:space:]]" "$FSTAB"; then
        echo "Warning: /ai-workspace already in $FSTAB. Skipping append."
    else
        echo "UUID=$UUID_AI /ai-workspace ext4 defaults,noatime,errors=remount-ro 0 2" | tee -a "$FSTAB"
    fi

    if [[ ! -z "$UUID_DATA" ]]; then
        # Check for /data
        if grep -q "[[:space:]]/data[[:space:]]" "$FSTAB"; then
            echo "Warning: /data already in $FSTAB. Skipping append."
        else
            echo "UUID=$UUID_DATA /data ext4 defaults,noatime,errors=remount-ro 0 2" | tee -a "$FSTAB"
        fi
    fi
}

# Run 1: Should append
run_fix_logic

# Verify content
echo "Content after Run 1:"
cat "$FSTAB"
echo "----------------"

if grep -q "UUID=$UUID_AI /ai-workspace" "$FSTAB"; then
    echo "SUCCESS: AI entry found."
else
    echo "FAILURE: AI entry missing."
    exit 1
fi

if grep -q "UUID=$UUID_DATA /data" "$FSTAB"; then
    echo "SUCCESS: Data entry found."
else
    echo "FAILURE: Data entry missing."
    exit 1
fi

# Run 2: Should NOT append (idempotency check)
# Change UUIDs to simulate new run with different UUIDs (worst case)
UUID_AI="new-uuid-ai"
UUID_DATA="new-uuid-data"

run_fix_logic

# Verify content
echo "Content after Run 2:"
cat "$FSTAB"
echo "----------------"

# Should still have OLD UUIDs, not new ones (skipped)
if grep -q "UUID=mock-uuid-ai /ai-workspace" "$FSTAB"; then
    echo "SUCCESS: Old AI entry preserved."
else
    echo "FAILURE: Old AI entry lost."
    exit 1
fi

if grep -q "UUID=new-uuid-ai /ai-workspace" "$FSTAB"; then
    echo "FAILURE: Duplicate AI entry added!"
    exit 1
else
    echo "SUCCESS: No duplicate AI entry."
fi

# Count occurrences of /ai-workspace
COUNT=$(grep -c "/ai-workspace" "$FSTAB")
if [[ "$COUNT" -eq 1 ]]; then
    echo "SUCCESS: Only 1 entry for /ai-workspace."
else
    echo "FAILURE: Found $COUNT entries for /ai-workspace."
    exit 1
fi

echo "All tests passed!"
