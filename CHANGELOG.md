# Changelog

## 2.0.0 - February 13, 2024

### New Features

1. The loading spinner has been replaced by a progress bar on the webview. This will result in a faster perceived load time for checkout because the SDK will no longer wait for full page load to show the DOM content.
2. Localization has been added for the sheet title. Customize this value by modifying a `shopify_checkout_sheet_title` string in your `Localizable.xcstrings` file.

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "shopify_checkout_sheet_title" : {
      "comment" : "The title of the checkout sheet.",
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Checkout"
          }
        },
      }
    }
  }
}

```

### Breaking Changes

1. The `checkoutDidComplete` delegate method now returns a completed event object, containing details about the order:

```swift
checkoutDidComplete(event: ShopifyCheckoutSheetKit.CheckoutCompletedEvent) {
  print(event.orderDetails.id)
}
```

2. `spinnerColor` has been replaced by `tintColor`:

```diff
- ShopifyCheckoutSheetKit.configuration.spinnerColor = .systemBlue
+ ShopifyCheckoutSheetKit.configuration.tintColor = .systemBlue
```

### Deprecations

1. `CheckoutViewController.Representable()` for SwiftUI has been deprecated. Please use `CheckoutSheet(checkout:)` now instead.

```diff
.sheet(isPresented: $isShowingCheckout, onDismiss: didDismiss) {
-  CheckoutViewController.Representable(checkout: $checkoutURL, delegate: eventHandler)
-    .onReceive(eventHandler.$didCancel, perform: { didCancel in
-      if didCancel {
-        isShowingCheckout = false
-      }
-    })
+  CheckoutSheet(checkout: $checkoutURL)
+    .title("Custom title")
+    .colorScheme(.automatic)
+    .backgroundColor(.black)
+    .tintColor(.systemBlue)
+    .onCancel {
+       isShowingCheckout = false
+    }
+    .onComplete { }
+    .onPixelEvent { }
+    .onFail { }
+    .onLinkClick { }
}
```

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
