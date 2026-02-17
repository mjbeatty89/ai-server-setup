#!/bin/bash

# Test: Verify setup.sh behavior when package list file is missing

# Ensure we are running from repo root
if [ ! -f "setup.sh" ]; then
    echo "Error: This test must be run from the repository root."
    exit 1
fi

# Create mock environment
MOCK_DIR=$(mktemp -d)
export PATH="$MOCK_DIR:$PATH"
export HOME=$(mktemp -d) # Use a temp HOME to protect user config

# Function for cleanup
cleanup() {
    # Restore the package list if backup exists
    if [ -f "packages/installed-packages.txt.bak" ]; then
        mv packages/installed-packages.txt.bak packages/installed-packages.txt
    fi
    # Clean up temp dirs
    rm -rf "$MOCK_DIR"
    rm -rf "$HOME"
}

# Trap cleanup on exit
trap cleanup EXIT

# Mock sudo
cat << 'EOF' > "$MOCK_DIR/sudo"
#!/bin/sh
if [ ! -t 0 ]; then
    cat > /dev/null
fi
exit 0
EOF
chmod +x "$MOCK_DIR/sudo"

# Mock curl
cat << 'EOF' > "$MOCK_DIR/curl"
#!/bin/sh
echo "mock-curl-output"
exit 0
EOF
chmod +x "$MOCK_DIR/curl"

# Mock lsb_release unconditionally
cat << 'EOF' > "$MOCK_DIR/lsb_release"
#!/bin/sh
echo "focal"
EOF
chmod +x "$MOCK_DIR/lsb_release"

# Mock dpkg unconditionally
cat << 'EOF' > "$MOCK_DIR/dpkg"
#!/bin/sh
echo "amd64"
EOF
chmod +x "$MOCK_DIR/dpkg"


echo "--- Starting Test: Missing Package List Check ---"

# Hide the package list
mv packages/installed-packages.txt packages/installed-packages.txt.bak

# Run setup.sh
output=$(echo "n" | bash setup.sh 2>&1)

# Verification
echo "$output" | grep -q "Package list not found: packages/installed-packages.txt"
grep_exit=$?

if [ $grep_exit -eq 0 ]; then
    echo "PASS: Expected error message found."
else
    echo "FAIL: Expected error message NOT found."
    echo "Output:"
    echo "$output"
    exit 1
fi

# Check if script continued execution
echo "$output" | grep -q "Installing Snap packages..."
continue_exit=$?

if [ $continue_exit -eq 0 ]; then
    echo "PASS: Script continued execution."
else
    echo "FAIL: Script stopped execution prematurely."
    exit 1
fi

echo "Test setup_package_check PASSED"
exit 0
