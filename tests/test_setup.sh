#!/bin/bash

# Test script for setup.sh
# Usage: ./tests/test_setup.sh

# Determine script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$DIR")"

# Include utilities
source "$DIR/utils.sh"

# Clean up any previous test runs
rm -f "$DIR/mock_calls.log"

# Define test results file
TEST_RESULTS="$DIR/test_results.txt"
echo "Test Results:" > "$TEST_RESULTS"

pass() {
    echo -e "PASS: $1" | tee -a "$TEST_RESULTS"
}

fail() {
    echo -e "FAIL: $1" | tee -a "$TEST_RESULTS"
    echo "  Expected: $2" | tee -a "$TEST_RESULTS"
    echo "  Actual: $3" | tee -a "$TEST_RESULTS"
    exit 1
}

test_root_user_check() {
    echo "Running test_root_user_check..."
    setup_mocks

    # Run setup.sh with TEST_EUID=0
    # Capture stderr and stdout
    # Run from project root
    cd "$PROJECT_ROOT"
    OUTPUT=$(TEST_EUID=0 ./setup.sh 2>&1)
    EXIT_CODE=$?

    teardown_mocks

    # Check exit code
    if [ $EXIT_CODE -ne 1 ]; then
        fail "Root user check should exit with 1" "1" "$EXIT_CODE"
    fi

    # Check error message
    if ! echo "$OUTPUT" | grep -q "This script should not be run as root!"; then
        fail "Root user check should print error message" "This script should not be run as root!" "$OUTPUT"
    fi

    pass "test_root_user_check passed"
}

test_normal_user_check() {
    echo "Running test_normal_user_check..."
    setup_mocks

    # Run setup.sh with normal user (default EUID)
    # We pipe 'n' to answer the prompt for NVIDIA drivers
    # Mocking essential commands to allow script to proceed

    cd "$PROJECT_ROOT"
    OUTPUT=$(echo "n" | TEST_EUID=1000 ./setup.sh 2>&1)
    EXIT_CODE=$?

    teardown_mocks

    # Check exit code
    if [ $EXIT_CODE -ne 0 ]; then
        fail "Normal user check should exit with 0 (success) given mocked environment" "0" "$EXIT_CODE - Output: $OUTPUT"
    fi

    # Check that root error message is NOT present
    if echo "$OUTPUT" | grep -q "This script should not be run as root!"; then
        fail "Normal user check should NOT print root error message" "No error" "$OUTPUT"
    fi

    pass "test_normal_user_check passed"
}

# Run tests
test_root_user_check
test_normal_user_check

echo "All tests passed!"
rm -f "$TEST_RESULTS"
