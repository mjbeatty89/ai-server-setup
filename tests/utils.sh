#!/bin/bash

# Utility functions for testing setup.sh

setup_mocks() {
    # Create a temporary directory for mocks
    MOCK_DIR=$(mktemp -d)
    export PATH="$MOCK_DIR:$PATH"

    # Log file for mock calls
    export MOCK_LOG="$(pwd)/tests/mock_calls.log"
    rm -f "$MOCK_LOG"
    touch "$MOCK_LOG"

    # Create a generic mock script that logs arguments and returns success
    local mock_script="$MOCK_DIR/mock_generic"
    cat << 'EOF' > "$mock_script"
#!/bin/bash
cmd_name=$(basename "$0")
echo "[MOCK] $cmd_name $@" >> "$MOCK_LOG"
exit 0
EOF
    chmod +x "$mock_script"

    # List of commands to mock with generic success
    local commands=("sudo" "apt" "snap" "curl" "wget" "tee" "gpg" "usermod" "xargs" "cp" "mkdir" "chown" "add-apt-repository" "lsb_release" "dpkg")

    for cmd in "${commands[@]}"; do
        ln -sf "$mock_script" "$MOCK_DIR/$cmd"
    done

    # Special handling for commands that need specific output to stdout

    # dpkg mock override
    rm "$MOCK_DIR/dpkg"
    cat << 'EOF' > "$MOCK_DIR/dpkg"
#!/bin/bash
if [[ "$1" == "--print-architecture" ]]; then
    echo "amd64"
else
    cmd_name=$(basename "$0")
    echo "[MOCK] $cmd_name $@" >> "$MOCK_LOG"
fi
exit 0
EOF
    chmod +x "$MOCK_DIR/dpkg"

    # lsb_release mock override
    rm "$MOCK_DIR/lsb_release"
    cat << 'EOF' > "$MOCK_DIR/lsb_release"
#!/bin/bash
if [[ "$1" == "-cs" ]]; then
    echo "jammy"
else
    cmd_name=$(basename "$0")
    echo "[MOCK] $cmd_name $@" >> "$MOCK_LOG"
fi
exit 0
EOF
    chmod +x "$MOCK_DIR/lsb_release"
}

teardown_mocks() {
    if [ -d "$MOCK_DIR" ]; then
        rm -rf "$MOCK_DIR"
    fi
    # Keep log file for inspection if needed, or delete it
    # rm -f "$MOCK_LOG"
}
