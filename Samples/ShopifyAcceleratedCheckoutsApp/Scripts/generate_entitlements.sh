#!/bin/bash

set -e

CONFIG_FILE="Storefront.xcconfig"
STOREFRONT_DOMAIN=$(grep '^STOREFRONT_DOMAIN' "$CONFIG_FILE" | cut -d '=' -f2 | tr -d ' ')

TEMPLATE_FILE="ShopifyAcceleratedCheckoutsApp/ShopifyAcceleratedCheckoutsApp.entitlements.template"
OUTPUT_FILE="ShopifyAcceleratedCheckoutsApp/ShopifyAcceleratedCheckoutsApp.entitlements"

if [ -z "$STOREFRONT_DOMAIN" ]; then
  echo "Error: STOREFRONT_DOMAIN is not set in Storefront.xcconfig"
  exit 1
fi

if [ -e "$OUTPUT_FILE" ]; then
  echo "Warning: $OUTPUT_FILE already exists."
  exit 0
fi

sed "s/{STOREFRONT_DOMAIN}/$STOREFRONT_DOMAIN?mode=developer/g" "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "Success: Entitlements file generated at $OUTPUT_FILE with domain $STOREFRONT_DOMAIN"