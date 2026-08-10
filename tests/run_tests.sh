#!/usr/bin/env bash
# Build and run all langchain4a unit tests.
# Usage: ./tests/run_tests.sh

set -eu

cd "$(dirname "$0")/.."

echo "=== Building tests ==="
alr exec -- gnatmake -P tests/tests.gpr 2>&1

echo ""
echo "=== Running tests ==="
alr exec -- ./tests/bin/test_main
