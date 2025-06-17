# Sample Project

This directory contains a sample project that implements the `ShopifyCheckoutSheetKit` library.

The project directory contains a `Storefront.xcconfig.example` file. Simply rename it to `Storefront.xcconfig` and update the contained values to match your Shopify storefront.

---

## MobileBuyIntegration

This project demonstrates how to use the [Mobile Buy SDK](https://github.com/Shopify/mobile-buy-sdk-ios) in conjunction with the `ShopifyCheckoutSheetKit` library.

To get started you will first need to generate an `entitlements` file for the app. You can do so by running the following command from the root directory.

```sh
./Scripts/setup_entitlements
```