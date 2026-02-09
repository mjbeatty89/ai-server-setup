#!/bin/bash
# Verify fix for ignored package installation errors

# Ensure we are running from root
if [[ ! -f "setup.sh" ]]; then
    echo "Please run from repository root"
    exit 1
fi

# Setup mocks
MOCKS_DIR="$(pwd)/tests/mocks"
export PATH="$MOCKS_DIR:$PATH"

# Arguments:
# $1: Expected outcome (SUCCESS or FAIL)
# $2: Whether to simulate APT failure (1 or 0)

EXPECTED_OUTCOME="$1"
SIMULATE_FAILURE="$2"

if [[ -z "$EXPECTED_OUTCOME" || -z "$SIMULATE_FAILURE" ]]; then
    echo "Usage: $0 [SUCCESS|FAIL] [0|1]"
    echo "  SUCCESS: Expect setup.sh to exit with 0"
    echo "  FAIL: Expect setup.sh to exit with non-zero"
    echo "  0: Do not simulate APT failure"
    echo "  1: Simulate APT failure in batch install"
    exit 1
fi

export FAIL_APT_BATCH="$SIMULATE_FAILURE"

echo "Running setup.sh with FAIL_APT_BATCH=$FAIL_APT_BATCH, expecting $EXPECTED_OUTCOME..."

# Use "n" to answer NVIDIA prompt
# Capture output to log file
echo "n" | ./setup.sh > setup_output.log 2>&1
EXIT_CODE=$?

echo "setup.sh exited with $EXIT_CODE"

if [[ "$EXPECTED_OUTCOME" == "SUCCESS" ]]; then
    if [[ "$EXIT_CODE" -eq 0 ]]; then
        echo "VERIFICATION PASSED: setup.sh succeeded as expected."
        exit 0
    else
        echo "VERIFICATION FAILED: setup.sh failed but was expected to succeed."
        echo "Last 20 lines of output:"
        tail -n 20 setup_output.log
        exit 1
    fi
elif [[ "$EXPECTED_OUTCOME" == "FAIL" ]]; then
    if [[ "$EXIT_CODE" -ne 0 ]]; then
        echo "VERIFICATION PASSED: setup.sh failed as expected."
        exit 0
    else
        echo "VERIFICATION FAILED: setup.sh succeeded but was expected to fail."
        exit 1
    fi
else
    echo "Unknown expected outcome: $EXPECTED_OUTCOME"
    exit 1
fi
