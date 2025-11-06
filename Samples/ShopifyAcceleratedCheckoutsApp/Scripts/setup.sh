#!/bin/bash

set -e

# Setup Storefront.xcconfig if needed
CONFIG_FILE="Storefront.xcconfig"
EXAMPLE_FILE="Storefront.xcconfig.example"

if [ ! -f "$CONFIG_FILE" ]; then
  if [ -f "$EXAMPLE_FILE" ]; then
    cp "$EXAMPLE_FILE" "$CONFIG_FILE"
    echo "✅ Created $CONFIG_FILE from example. Please update it with your store settings."
  else
    echo "❌ Error: Neither $CONFIG_FILE nor $EXAMPLE_FILE found"
    exit 1
  fi
fi

# Read the storefront domain
STOREFRONT_DOMAIN=$(grep '^STOREFRONT_DOMAIN' "$CONFIG_FILE" | cut -d '=' -f2 | tr -d ' ')

TEMPLATE_FILE="ShopifyAcceleratedCheckoutsApp/ShopifyAcceleratedCheckoutsApp.entitlements.template"
OUTPUT_FILE="ShopifyAcceleratedCheckoutsApp/ShopifyAcceleratedCheckoutsApp.entitlements"

if [ -z "$STOREFRONT_DOMAIN" ]; then
  echo "⚠️  Warning: STOREFRONT_DOMAIN is not set in Storefront.xcconfig"
  echo "   Please update $CONFIG_FILE with your store settings."
  exit 1
fi

# Generate entitlements if they don't exist
if [ -e "$OUTPUT_FILE" ]; then
  echo "ℹ️  Entitlements file already exists at $OUTPUT_FILE"
  exit 0
fi

sed "s/{STOREFRONT_DOMAIN}/$STOREFRONT_DOMAIN?mode=developer/g" "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "✅ Entitlements file generated at $OUTPUT_FILE with domain $STOREFRONT_DOMAIN"