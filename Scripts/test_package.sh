#!/usr/bin/env bash

set -ex
set -eo pipefail

# Get scheme name from first argument, default to ShopifyAcceleratedCheckouts
SCHEME="${1:-ShopifyAcceleratedCheckouts}"

if [[ -n $CURRENT_SIMULATOR_UUID ]]; then
	dest="id=$CURRENT_SIMULATOR_UUID"
else
	# Get a valid iPhone simulator ID using get_device_id.sh
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	DEVICE_ID=$("$SCRIPT_DIR/get_device_id.sh" "iPhone 16")
	dest="id=$DEVICE_ID"
fi

xcodebuild_cmd="xcodebuild test -scheme $SCHEME -sdk iphonesimulator -destination \"$dest\" -skipPackagePluginValidation"

if command -v xcbeautify >/dev/null 2>&1; then
	eval "$xcodebuild_cmd" | xcbeautify
else
	eval "$xcodebuild_cmd"
fi
