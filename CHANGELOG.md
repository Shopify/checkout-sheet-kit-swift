# Changelog

## 3.4.0-rc.6 - August 26, 2025

- AC: Expose CheckoutIdentifier publicly, conform Wallet & RequiredContactFields enums to String to avoid RN mapping functions, include `reason` in RenderState.error by @kieran-osgood-shopify in https://github.com/Shopify/checkout-sheet-kit-swift/pull/402
- AC: Fix: Move log inside of guard by @kieran-osgood-shopify in https://github.com/Shopify/checkout-sheet-kit-swift/pull/399

## 3.4.0-rc.5 - August 18, 2025

- [AC]: Ensure `customer` is attached to cart only when not requested in payment sheet (#385)
- [AC]: Remove wrapper enum on PayWithApplePayButton by @kieran-osgood-shopify in https://github.com/Shopify/checkout-sheet-kit-swift/pull/390
- [AC]: Add support for OSLogger by @kieran-osgood-shopify in https://github.com/Shopify/checkout-sheet-kit-swift/pull/383

## 3.4.0-rc.4 - August 14, 2025

- [AC]: Widen supported iOS versions to include iOS16 by @kieran-osgood-shopify in https://github.com/Shopify/checkout-sheet-kit-swift/pull/376

## 3.4.0-rc.3 - August 12, 2025

- Includes a fix for cart address updates in the Apple Pay sheet of Accelerated Checkouts
- Exposes a `label(label:)` modifier to customize the Apple Pay button

## 3.4.0-rc.2 - August 6, 2025

- Include missing AcceleratedCheckouts source files
- Fix issue with misconfigured `SHIPPING_LINE` in StorefrontAPI response decoding

## 3.4.0-rc.1 - August 1, 2025

- Include `ShopifyAcceleratedCheckouts` package

## 3.3.0 - July 3, 2025

- Allow customizing the close button tint for the checkout sheet.

## 3.2.0 - 20 June, 2025

- Ensure `self.delegate` is set for `CheckoutViewController` after state changes

https://github.com/Shopify/checkout-sheet-kit-swift/pull/296

## 3.1.2 - November 6, 2024

- Remove redundant code

## 3.1.1 - October 18, 2024

- Ignore "about:blank" URLs

## 3.1.0 - October 16, 2024

- Ignore cancelled redirects
- Call `checkoutDidClickLink` for deep links
- Prevent "recovery" retry flow for multipass URLs with one-time tokens
- Expose `invalidate()` function to manually clear the webview (preload) cache

## 3.0.4 - August 7, 2024

- Updates to reflect latest Web Pixel schema

## 3.0.3 - August 6, 2024

- Fixes internal instrumentation

## 3.0.2 - July 24, 2024

- Sets `allowsInlineMediaPlayback` to true on the Webview to prevent the iOS camera opening as a live broadcast.

## 3.0.1 - June 18, 2024

- Fixes an issue where web pixels events do not fire after checkout completion.

## 3.0.0 - May 20, 2024

Version `3.0.0` of the Checkout Sheet Kit ships with numerous improvements to error handling, including graceful degradation. In the event that your app receives an HTTP error on load or crashes mid-experience, the kit will implement a retry in an effort to attempt to recover.

### Error handling

```swift
func checkoutDidFail(error: ShopifyCheckoutSheetKit.CheckoutError) {
		var errorMessage: String = ""

		/// Internal Checkout SDK error
		if case .sdkError(let underlying, let recoverable) = error {
			errorMessage = "\(underlying.localizedDescription)"
		}

		/// Checkout unavailable error
		if case .checkoutUnavailable(let message, let code, let recoverable) = error {
			errorMessage = message
			switch code {
        case .clientError(let clientErrorCode):
          errorMessage = "Client Error: \(clientErrorCode)"
        case .httpError(let statusCode):
          errorMessage = "HTTP Error: \(statusCode)"
      }
		}

		/// Storefront configuration error
		if case .configurationError(let message, let code, let recoverable) = error {
			errorMessage = message
		}

		/// Checkout has expired, re-create cart to fetch a new checkout URL
		if case .checkoutExpired(let message, let code, let recoverable) = error {
			errorMessage = message
		}

		if !error.isRecoverable {
			handleUnrecoverableError(errorMessage)
		}
	}
```

### Opting out

To opt out of the recovery feature, or to opt-out of the recovery of a specific error, extend the `shouldRecoverFromError` delegate method:

```swift
class Controller: CheckoutDelegate {
  shouldRecoverFromError(error: CheckoutError) {
    // default:
    return error.isRecoverable
  }

  checkoutDidFail(error: CheckoutError) {
    // Error handling...
  }
}
```

### Caveats

In the event that the Checkout Sheet Kit has triggered the recovery experience, certain features _may_ not be available.

1. Theming may not work as intended.
2. **Web pixel lifecycle events will not fire.**
3. `checkoutDidComplete` lifecycle events will contain only an `orderId`.

## 2.0.1 - March 19, 2024

- Makes `CheckoutCompletedEvent` encodable/decodable.

## 2.0.0 - March 15, 2024

### New Features

1. The loading spinner has been replaced by a progress bar on the webview. This will result in a faster perceived load time for checkout because the SDK will no longer wait for full page load to show the DOM content.
2. Localization has been added for the sheet title. Customize this value by modifying a `shopify_checkout_sheet_title` string in your `Localizable.xcstrings` file.

```json
{
  "sourceLanguage": "en",
  "strings": {
    "shopify_checkout_sheet_title": {
      "comment": "The title of the checkout sheet.",
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Checkout"
          }
        }
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
