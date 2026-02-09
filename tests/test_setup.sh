#!/bin/bash

# Ensure we are running from the repository root
if [ ! -f "setup.sh" ]; then
    echo "Error: setup.sh not found. Please run this test from the repository root."
    exit 1
fi

# Source the setup script to load functions and variables
# Suppress the initial banner output during sourcing to keep test output clean
source ./setup.sh > /dev/null

# Test print_status
echo "Testing print_status..."
TEST_MSG="Hello World"
OUTPUT=$(print_status "$TEST_MSG")

# Construct expected output using the same variables
EXPECTED=$(echo -e "${YELLOW}[*]${NC} $TEST_MSG")

if [ "$OUTPUT" == "$EXPECTED" ]; then
    echo "✅ print_status test passed"
else
    echo "❌ print_status test failed"
    echo "Expected: '$EXPECTED'"
    echo "Got:      '$OUTPUT'"
    exit 1
fi
