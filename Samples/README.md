# Sample Project

This directory contains a sample project that implements the `ShopifyCheckoutSheetKit` library.

The project directory contains a `Storefront.xcconfig.example` file. Simply rename it to `Storefront.xcconfig` and update the contained values to match your Shopify storefront.

---

## MobileBuyIntegration

This project demonstrates how to use the [Mobile Buy SDK](https://github.com/Shopify/mobile-buy-sdk-ios) in conjunction with the `ShopifyCheckoutSheetKit` library.

### Getting Started

1. Copy the example config file:
```sh
cp Samples/MobileBuyIntegration/Storefront.xcconfig.example Samples/MobileBuyIntegration/Storefront.xcconfig
```
2. Fill in `STOREFRONT_DOMAIN` and other keys in `Storefront.xcconfig` with your store values.
3. Build & run — entitlements are auto-generated via a build PreAction (no manual script step needed).

### Troubleshooting

If the build PreAction fails, Xcode will show **"exited with status code 1"**. Click that line to open the build log — the script output at the bottom will indicate the issue.

| Build Log Output | Cause | Fix |
|------------------|-------|-----|
| `grep: Storefront.xcconfig: No such file or directory` | `Storefront.xcconfig` file is missing | Copy `.xcconfig.example` to `Storefront.xcconfig` and fill in values |
| `Error: STOREFRONT_DOMAIN is not set in Storefront.xcconfig` | `Storefront.xcconfig` exists but `STOREFRONT_DOMAIN` is blank | Set your store's domain in the config |
| Associated domains not working at runtime | Domain value is incorrect | Verify domain matches your Shopify store (no `https://` prefix) |

---

## ShopifyAcceleratedCheckoutsApp

This project demonstrates integrating Shopify's Accelerated Checkouts, an all in one solution to accelerated checkouts via Apple Pay and Shop Pay. 

To get started:

1. Copy the settings file:
```sh
cp Samples/ShopifyAcceleratedCheckouts/Storefront.xcconfig.example Samples/ShopifyAcceleratedCheckouts/Storefront.xcconfig
```
2. Modify each of the keys in `Storefront.xcconfig` to match the value in your store settings.