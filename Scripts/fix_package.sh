#!/bin/bash

if [[ "$(uname -m)" == arm64 ]]; then
	export PATH="/opt/homebrew/bin:$PATH"
fi

if which swiftlint >/dev/null; then
	echo "🔄 Running SwiftLint: swiftlint lint --strict Samples Sources/ShopifyAcceleratedCheckouts"
	swiftlint lint --fix --quiet Samples Sources/ShopifyAcceleratedCheckouts
	LINT_STATUS=$?
	echo "✅ SwiftLint exit status: $LINT_STATUS"
else
	echo "⚠️ WARN: SwiftLint not installed"
	echo "🔧 FIX: Run $(dev up)"
	echo "Or, install via homebrew $(brew install swiftlint) / https://github.com/realm/SwiftLint"
	exit 1
fi

if which swiftformat >/dev/null; then
	echo "🔄 Running SwiftFormat..."
	swiftformat . --quiet
	FORMAT_STATUS=$?
	echo "✅ SwiftFormat exit status: $FORMAT_STATUS"
else
	echo "⚠️ WARN: SwiftFormat not installed"
	echo "🔧 FIX: Run $(dev up)"
	echo "Or, install via homebrew $(brew install swiftformat) / https://github.com/nicklockwood/SwiftFormat"
	exit 1
fi
