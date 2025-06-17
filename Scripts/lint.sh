#!/bin/bash

# Determine mode based on arguments
MODE="check"
if [[ "$1" == "--fix" || "$1" == "-f" ]]; then
    MODE="fix"
fi

if [[ "$(uname -m)" == arm64 ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

# SwiftLint
if which swiftlint >/dev/null; then
    if [[ "$MODE" == "fix" ]]; then
        echo "🔄 Running SwiftLint in fix mode..."
        swiftlint lint --fix --quiet Sources/ShopifyCheckoutSheetKit Tests/ShopifyCheckoutSheetKitTests Samples
    else
        echo "🔄 Running SwiftLint in check mode: swiftlint lint --strict Sources/ShopifyCheckoutSheetKit Tests/ShopifyCheckoutSheetKitTests Samples"
        swiftlint lint --strict --quiet Sources/ShopifyCheckoutSheetKit Tests/ShopifyCheckoutSheetKitTests Samples
    fi
    LINT_STATUS=$?
    echo "✅ SwiftLint exit status: $LINT_STATUS"
else
    echo "⚠️ WARN: SwiftLint not installed"
    echo "🔧 FIX:"
    echo "   Shopify employee? Run 'dev up'"
    echo "   Not a Shopify employee? Install via homebrew 'brew install swiftlint' / https://github.com/realm/SwiftLint"
    exit 1
fi

# Check if SwiftLint found issues in check mode
if [[ "$MODE" == "check" && $LINT_STATUS -ne 0 ]]; then
    echo "❌ SwiftLint detected issues that need to be fixed."
    echo "🔧 How to fix:"
    echo "   Shopify employee? Run 'dev fix'"
    echo "   Not a Shopify employee? Run './Scripts/lint.sh --fix' to auto-fix issues"
    echo "   Then fix any remaining non-autofixable issues manually and try to push again"
    exit 1
fi

# SwiftFormat
if which swiftformat >/dev/null; then
    if [[ "$MODE" == "fix" ]]; then
        echo "🔄 Running SwiftFormat in fix mode..."
        swiftformat . --quiet
    else
        echo "🔄 Running SwiftFormat in check mode..."
        swiftformat . --quiet --lint
    fi
    FORMAT_STATUS=$?
    echo "✅ SwiftFormat exit status: $FORMAT_STATUS"
else
    echo "⚠️ WARN: SwiftFormat not installed"
    echo "🔧 FIX:"
    echo "   Shopify employee? Run 'dev up'"
    echo "   Not a Shopify employee? Install via homebrew 'brew install swiftformat' / https://github.com/nicklockwood/SwiftFormat"
    exit 1
fi

# Check if SwiftFormat found issues in check mode
if [[ "$MODE" == "check" && $FORMAT_STATUS -ne 0 ]]; then
    echo "❌ SwiftFormat detected issues that need to be fixed."
    echo "🔧 How to fix:"
    echo "   Shopify employee? Run 'dev fix'"
    echo "   Not a Shopify employee? Run './Scripts/lint.sh --fix' to auto-fix issues"
    echo "   Then fix any remaining non-autofixable issues manually and try to push again"
    exit 1
fi

# Success message
if [[ "$MODE" == "fix" ]]; then
    echo "✅ Linting and formatting fixes applied successfully!"
else
    echo "✅ All linting and formatting checks passed!"
fi 