# Changelog

## 2.0.0 - February 13, 2024

TODO

## 1.0.2 - March 5, 2024

Fixes an issue with strongly held references to old Webview instances.

## 1.0.1 - January 31, 2024

Bumps the package version.

## 1.0.0 - January 31, 2024

ShopifyCheckoutSheetKit is now generally available for
[Swift](https://github.com/Shopify/checkout-sheet-kit-swift),
[Android](https://github.com/Shopify/checkout-sheet-kit-android) and
[React Native](https://github.com/Shopify/checkout-sheet-kit-react-native) -
providing the world's highest converting, customizable, one-page checkout.

## 0.10.1 - January 26, 2024

- Clean Web Pixel types - #120 (@markmur)

## 0.10.0 - January 26, 2024

- Expose Web Pixel events via new `checkoutDidEmitWebPixelEvent` hook - #101, #103, #105, #107, #112 (@josemiguel-alvarez, @kiftio , @markmur)
- Send `Sec-Purpose: prefetch` header to identify preload requests - #109 (@kiftio)
- Improve caching of preloaded checkout views - #97, #102, #110 (@cianBuckley)
- Improve UX for loading spinner - #111 (@markmur)

## 0.9.0 - January 10, 2023

- **Breaking:** The Shopify Checkout Kit has been rebranded to the Shopify Checkout Sheet Kit for Swift. To match this new name, the package has been renamed to `ShopifyCheckoutSheetKit`.

## 0.8.1 - December 20, 2023

Emit a presented message to checkout when the checkout sheet is raised as groundwork for supporting analytics / pixel events.

## 0.8.0 - December 18, 2023

- Adds support for SwiftUI
- `CheckoutViewController`` is now public for SwiftUI compatibility and to support UI modification requests
- Telemetry improvements
- Improved documentation

## 0.7.0 - November 20, 2023

- Adds support for CocoaPods.

## 0.6.0 - November 14, 2023

- **Breaking:** The Mobile Checkout SDK has been rebranded to the Shopify Checkout Kit for Swift. To match this new name, the package has been renamed to `ShopifyCheckoutKit`.
