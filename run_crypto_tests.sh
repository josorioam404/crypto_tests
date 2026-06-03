#!/bin/bash

# run_crypto_tests.sh
# Master runner for security test suite

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

echo "=============================================="
echo "    Adopti Security & Crypto Test Suite       "
echo "=============================================="
echo ""

# Make sure scripts are executable
chmod +x "$SCRIPT_DIR/test_ssl.sh"
chmod +x "$SCRIPT_DIR/test_rate_limiting.sh"

"$SCRIPT_DIR/test_ssl.sh"
"$SCRIPT_DIR/test_rate_limiting.sh"

echo "=============================================="
echo "    Security Test Suite Execution Complete    "
echo "=============================================="
