 #!/usr/bin/env bash

set -e

if [ ! -f "./samples/MobileBuyIntegration/Storefront.xcconfig" ]; then
  echo """
    Error: Your project is missing a Storefront.xcconfig file.

    Replace the STOREFRONT_DOMAIN and STOREFRONT_ACCESS_TOKEN environment variables in \"samples/MobileBuyIntegration/Storefront.xcconfig.example\" and rename the file to \"Storefront.xcconfig\" to get started.

    If you don't have a Shopify app setup, go to https://admin.shopify.com/settings/apps/development to configure an application for your storefront which will give you access to the Storefront API.
  """
  exit 1;
fi
