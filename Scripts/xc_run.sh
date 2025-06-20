#!/bin/bash
set -e
set -eo pipefail

# Get action from first argument, default to build
ACTION="${1:-build}"

# Get scheme name from second argument, default to ShopifyCheckoutSheetKit
SCHEME="${2:-ShopifyCheckoutSheetKit}"

# Validate action is either build or test
if [[ "$ACTION" != "build" && "$ACTION" != "test" ]]; then
    echo "Error: ACTION must be either 'build' or 'test', got '$ACTION'"
    exit 1
fi

if [[ -n $CURRENT_SIMULATOR_UUID ]]; then
    dest="id=$CURRENT_SIMULATOR_UUID"
else
    # Get a valid iPhone simulator ID using get_device_id.sh
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    DEVICE_ID=$("$SCRIPT_DIR/get_device_id.sh" "iPhone 16")
    dest="id=$DEVICE_ID"
fi

xcodebuild_cmd="xcodebuild $ACTION -scheme $SCHEME -sdk iphonesimulator -destination \"$dest\" -skipPackagePluginValidation"

if command -v xcbeautify >/dev/null 2>&1; then
    eval "$xcodebuild_cmd" | xcbeautify
else
    eval "$xcodebuild_cmd"
fi