#!/bin/bash
set -e

echo "Testing Git Installation Check in init-github.sh..."

TEMP_LOG=$(mktemp)

cleanup() {
    rm -f "$TEMP_LOG"
    rm -f tests/run_test.sh
}
trap cleanup EXIT

cat << 'WRAPPER' > tests/run_test.sh
#!/bin/bash

export TEMP_LOG="$1"

# Mock 'command' builtin
command() {
    if [[ "$1" == "-v" && "$2" == "git" ]]; then
        echo "mock_command_git_check_failed" >> "$TEMP_LOG"
        return 1
    fi
    builtin command "$@"
}

# Mock 'sudo'
sudo() {
    echo "sudo $@" >> "$TEMP_LOG"
}

# Mock 'read'
read() {
    local var_name="${@: -1}"
    eval "$var_name=mocked_value"
}

# Mock 'git'
git() {
    echo "git $@" >> "$TEMP_LOG"
}

# Source the target script
source ./init-github.sh > /dev/null 2>&1
WRAPPER
chmod +x tests/run_test.sh

./tests/run_test.sh "$TEMP_LOG" || true

echo "Test Results:"
cat "$TEMP_LOG"

if grep -q "sudo apt install -y git" "$TEMP_LOG"; then
    echo "SUCCESS: Git installation was triggered."
else
    echo "FAILURE: Git installation was NOT triggered."
    exit 1
fi

echo "All tests passed!"
