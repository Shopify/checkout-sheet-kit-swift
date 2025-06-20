#!/bin/bash

# Check if device type was provided
if [ $# -lt 1 ]; then
  echo "Usage: $0 <device_type> [model_keywords...]"
  echo "Example: $0 iPhone 16"
  echo "Example: $0 iPad Pro"
  echo "Example: $0 iPad Pro 11-inch"
  exit 1
fi

DEVICE_TYPE="$1"
shift

# Join the remaining arguments to build a search pattern
SEARCH=""
if [ $# -gt 0 ]; then
  SEARCH="$*"
fi

# List all devices and filter
if [ -n "$SEARCH" ]; then
  # Create a search string with spaces to match exact model (case insensitive)
  DEVICES=$(xcrun simctl list devices | grep -i "$DEVICE_TYPE")
  
  # Use grep to find lines containing all search terms (case insensitive)
  for term in $SEARCH; do
    DEVICES=$(echo "$DEVICES" | grep -i "$term")
  done
  
  # Get the first matching device
  DEVICE_ID=$(echo "$DEVICES" | head -1 | sed -E 's/.*\(([A-Z0-9-]+)\).*/\1/')
else
  # If no model specified, get the first device of the type (case insensitive)
  DEVICE_ID=$(xcrun simctl list devices | grep -i "$DEVICE_TYPE" | head -1 | sed -E 's/.*\(([A-Z0-9-]+)\).*/\1/')
fi

# Check if identifier was found
if [ -z "$DEVICE_ID" ]; then
  echo "Device not found: $DEVICE_TYPE $SEARCH"
  exit 1
fi

echo "$DEVICE_ID"