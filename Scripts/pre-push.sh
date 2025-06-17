#!/bin/bash

# Run all scripts in parallel
echo "🔄 Running all checks in parallel..."

# Create temp files for each process output
LINT_LOG=$(mktemp)
TEST_LOG=$(mktemp)
BUILD_LOG=$(mktemp)

# Cleanup function
cleanup() {
	rm -f "$LINT_LOG" "$TEST_LOG" "$BUILD_LOG"
}
trap cleanup EXIT

# Run scripts in parallel, capturing all output
scripts/lint.sh > "$LINT_LOG" 2>&1 &
LINT_PID=$!

scripts/test_package.sh > "$TEST_LOG" 2>&1 &
TEST_PID=$!

scripts/build_sample_app.sh > "$BUILD_LOG" 2>&1 &
BUILD_PID=$!

# Wait for all processes and capture their exit codes
wait $LINT_PID
LINT_EXIT=$?
if [ $LINT_EXIT -eq 0 ]; then
	echo "✅ Linting completed successfully"
fi

wait $TEST_PID
TEST_EXIT=$?
if [ $TEST_EXIT -eq 0 ]; then
	echo "✅ Tests completed successfully"
fi

wait $BUILD_PID
BUILD_EXIT=$?
if [ $BUILD_EXIT -eq 0 ]; then
	echo "✅ Sample app build completed successfully"
fi

# Check results and report failures
FAILED=0
FAILURE_MSGS=()

if [ $LINT_EXIT -ne 0 ]; then
	FAILED=1
	FAILURE_MSGS+=("❌ Linting failed")
fi

if [ $TEST_EXIT -ne 0 ]; then
	FAILED=1
	FAILURE_MSGS+=("❌ Tests failed")
fi

if [ $BUILD_EXIT -ne 0 ]; then
	FAILED=1
	FAILURE_MSGS+=("❌ Sample app build failed")
fi

# Report results
if [ $FAILED -eq 1 ]; then
	echo ""
	echo "❌ Some checks failed:"
	for msg in "${FAILURE_MSGS[@]}"; do
		echo "  $msg"
	done
	echo ""
	
	# Show output for failed processes only
	if [ $LINT_EXIT -ne 0 ]; then
		echo "=== LINT OUTPUT ==="
		cat "$LINT_LOG"
		echo ""
	fi
	
	if [ $TEST_EXIT -ne 0 ]; then
		echo "=== TEST OUTPUT ==="
		cat "$TEST_LOG"
		echo ""
	fi
	
	if [ $BUILD_EXIT -ne 0 ]; then
		echo "=== BUILD OUTPUT ==="
		cat "$BUILD_LOG"
		echo ""
	fi
	
	echo "Please fix the issues before pushing."
	exit 1
else
	echo "🚀 All checks passed, continuing with push..."
	exit 0
fi
