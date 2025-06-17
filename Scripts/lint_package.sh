#!/bin/bash

if [[ "$(uname -m)" == arm64 ]]; then
	export PATH="/opt/homebrew/bin:$PATH"
fi

if which swiftlint >/dev/null; then
	echo "🔄 Running SwiftLint: swiftlint lint --strict Samples Sources/ShopifyAcceleratedCheckouts"
	swiftlint lint --strict --quiet Samples Sources/ShopifyAcceleratedCheckouts
	LINT_STATUS=$?
	echo "SwiftLint exit status: $LINT_STATUS"
else
	echo "⚠️ WARN: SwiftLint not installed"
	echo "🔧 FIX:"
	echo "   Shopify employee? Run 'dev up'"
	echo "   Not a Shopify employee? Install via homebrew 'brew install swiftlint' / https://github.com/realm/SwiftLint"
	exit 1
fi

# Check if SwiftLint found issues
if [ $LINT_STATUS -ne 0 ]; then
	echo "❌ SwiftLint detected issues that need to be fixed."
	echo "🔧 How to fix:"
	echo "   Shopify employee? Run 'dev fix'"
	echo "   Not a Shopify employee? Run './scripts/fix_package.sh' to auto-fix issues"
	echo "   Then fix any remaining non-autofixable issues manually and try to push again"
	exit 1
fi

if which swiftformat >/dev/null; then
	echo "🔄 Running SwiftFormat..."
	swiftformat . --quiet --lint
	FORMAT_STATUS=$?
	echo "✅ SwiftFormat exit status: $FORMAT_STATUS"
else
	echo "⚠️ WARN: SwiftFormat not installed"
	echo "🔧 FIX:"
	echo "   Shopify employee? Run 'dev up'"
	echo "   Not a Shopify employee? Install via homebrew 'brew install swiftformat' / https://github.com/nicklockwood/SwiftFormat"
	exit 1
fi


if [ $FORMAT_STATUS -ne 0 ]; then
	echo "❌ SwiftFormat detected issues that need to be fixed."
	echo "🔧 How to fix:"
	echo "   Shopify employee? Run 'dev fix'"
	echo "   Not a Shopify employee? Run './scripts/fix_package.sh' to auto-fix issues"
	echo "   Then fix any remaining non-autofixable issues manually and try to push again"
	exit 1
fi