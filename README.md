# Shopify Checkout Sheet Kit - Swift

[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](https://github.com/Shopify/checkout-sheet-kit-swift/blob/main/LICENSE) [![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-2ebb4e.svg?style=flat)](https://swift.org/package-manager/) ![Tests](https://github.com/shopify/checkout-sheet-kit-swift/actions/workflows/test-sdk.yml/badge.svg?branch=main) ![image](https://github.com/Shopify/checkout-sheet-kit-swift/assets/2034704/fae4e6e4-0e83-44ab-b65a-c2bceca1afc3)


**Shopify Checkout Sheet Kit** is a Swift Package library that enables Swift apps to provide the world’s highest converting, customizable, one-page checkout within the app. The presented experience is a fully-featured checkout that preserves all of the store customizations: Checkout UI extensions, Functions, branding, and more. It also provides platform idiomatic defaults such as support for light and dark mode, and convenient developer APIs to embed, customize, and follow the lifecycle of the checkout experience. Check out our blog to [learn how and why we built the Checkout Sheet Kit](https://www.shopify.com/partners/blog/mobile-checkout-sdks-for-ios-and-android).

### Requirements

- Swift 5.7+
- iOS SDK 13.0+
- The SDK is not compatible with checkout.liquid. The Shopify Store must be migrated for extensibility

### Getting Started

The SDK is an open-source [Swift Package library](https://www.swift.org/package-manager/). As a quick start, see [sample projects](Samples/README.md) or use one of the following ways to integrate the SDK into your project:

#### Package.swift

```swift
dependencies: [
  .package(url: "https://github.com/Shopify/checkout-sheet-kit-swift", from: "0.10")
]
```

#### Xcode

1. Open your Xcode project
2. Navigate to `File` > `Add Package Dependencies...`
3. Enter `https://github.com/Shopify/checkout-sheet-kit-swift` into the search box
4. Click `Add Package`

For more details on managing Swift Package dependencies in Xcode, please see [Apple's documentation](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app).

#### CocoaPods

```ruby
pod "ShopifyCheckoutSheetKit", "~> 0.10"
```

For more information on CocoaPods, please see their [getting started guide](https://guides.cocoapods.org/using/getting-started.html).

### Basic Usage

Once the SDK has been added as a dependency, you can import the library:

```swift
import ShopifyCheckoutSheetKit
```

To present a checkout to the buyer, your application must first obtain a checkout URL. The most common way is to use the [Storefront GraphQL API](https://shopify.dev/docs/api/storefront) to assemble a cart (via `cartCreate` and related update mutations) and query the [checkoutUrl](https://shopify.dev/docs/api/storefront/2023-10/objects/Cart#field-cart-checkouturl). You can use any GraphQL client to accomplish this and we recommend Shopify's [Mobile Buy SDK for iOS](https://github.com/Shopify/mobile-buy-sdk-ios) to simplify the development workflow:

```swift
import Buy

let client = Graph.Client(
  shopDomain: "yourshop.myshopify.com",
  apiKey: "<storefront access token>"
)

let query = Storefront.buildQuery { $0
  .cart(id: "myCartId") { $0
    .checkoutUrl()
  }
}

let task = client.queryGraphWith(query) { response, error in
  let checkoutURL = response?.cart.checkoutUrl
}
task.resume()
```

The `checkoutURL` object is a standard web checkout URL that can be opened in any browser. To present a native checkout sheet in your application, provide the `checkoutURL` alongside optional runtime configuration settings to the `present(checkout:)` function provided by the SDK:

```swift
import UIKit
import ShopifyCheckoutSheetKit

class MyViewController: UIViewController {
  func presentCheckout() {
    let checkoutURL: URL = // from cart object
    ShopifyCheckoutSheetKit.present(checkout: checkoutURL, from: self, delegate: self)
  }
}
```

Alternatively, with SwiftUI:

```swift
import SwiftUI

struct ContentView: View {
    @State private var isPresented = false
    let url: URL
    let delegate: CheckoutDelegate?

    var body: some View {
        Button("Checkout") {
            self.isPresented = true
        }
        .sheet(isPresented: $isPresented) {
            CheckoutViewControllerRepresentable(url: url, delegate: delegate)
        }
    }
}
```

To help optimize and deliver the best experience the SDK also provides a [preloading API](#preloading) that can be used to initialize the checkout session ahead of time.

### Configuration

The SDK provides a way to customize the presented checkout experience via the `ShopifyCheckoutSheetKit.configuration` object.

#### `colorScheme`

By default, the SDK will match the user's device color appearance. This behavior can be customized via the `colorScheme` property:

```swift
// [Default] Automatically toggle idiomatic light and dark themes based on device preference (`UITraitCollection`)
ShopifyCheckoutSheetKit.configuration.colorScheme = .automatic

// Force idiomatic light color scheme
ShopifyCheckoutSheetKit.configuration.colorScheme = .light

// Force idiomatic dark color scheme
ShopifyCheckoutSheetKit.configuration.colorScheme = .dark

// Force web theme, as rendered by a mobile browser
ShopifyCheckoutSheetKit.configuration.colorScheme = .web
```

#### `spinnerColor`

If the checkout session is not ready and being initialized, a loading spinner is shown and can be customized via the `spinnerColor` property:

```swift
// Use a custom UI color
ShopifyCheckoutSheetKit.configuration.spinnerColor = UIColor(red: 0.09, green: 0.45, blue: 0.69, alpha: 1.00)

// Use a system color
ShopifyCheckoutSheetKit.configuration.spinnerColor = .systemBlue
```

_Note: use preloading to optimize and deliver an instant buyer experience._

#### `backgroundColor`

While the checkout session is being initialized, the background color of the view can be customized via the `backgroundColor` property:

```swift
// Use a custom UI color
ShopifyCheckoutSheetKit.configuration.backgroundColor = UIColor(red: 0.09, green: 0.45, blue: 0.69, alpha: 1.00)

// Use a system color
ShopifyCheckoutSheetKit.configuration.backgroundColor = .systemBackground
```

### Preloading

Initializing a checkout session requires communicating with Shopify servers and, depending on the network weather and the quality of the buyer's connection, can result in undesirable wait time for the buyer. To help optimize and deliver the best experience, the SDK provides a preloading hint that allows app developers to signal and initialize the checkout session in the background and ahead of time.

Preloading is an advanced feature that can be toggled via a runtime flag:

```swift
ShopifyCheckoutSheetKit.configure {
  $0.preloading.enabled = false // defaults to true
}
```

When enabled, preloading a checkout is as simple as:

```swift
ShopifyCheckoutSheetKit.preload(checkout: checkoutURL)
```

Setting enabled to `false` will cause all calls to the `preload` function to be ignored. This allows the appliaction to selectively toggle preloading behavior as a remote feature flag or dynamically in response to client conditions — e.g. when data saver functionality is enabled by the user.

```
ShopifyCheckoutSheetKit.preloading.enabled = false
ShopifyCheckoutSheetKit.preload(checkout: checkoutURL) // no-op
```

#### Lifecycle management for preloaded checkout

Preloading renders a checkout in a background webview, which is brought to foreground when `ShopifyCheckoutSheetKit.present()` is called. The content of preloaded checkout reflects the state of cart when `preload()` was initially called. If the cart is mutated after `preload()` is called, the application is responsible for invalidating the preloaded checkout to ensure that up-to-date checkout content is displayed to the buyer:

1. To update preloaded contents: call `preload()` once again
2. To invalidate/disable preloaded content: toggle `ShopifyCheckoutSheetKit.preloading.enabled`

The library will automatically invalidate/abort preload under following conditions:

* Request results in network error or non 2XX server response code
* Once the checkout is successfuly completed, as indicated by the server response
* When `ShopifyCheckoutSheetKit.Configuration` object is updated by the application (e.g., theming changes)

A preloaded checkout *is not* automatically invalidated when checkout sheet is closed. For example, if buyer loads the checkout and then exits, the preloaded checkout is retained and should be updated when cart contents change.

#### Additional considerations for preloaded checkout

1. Preloading is a hint, not a guarantee: the library may debounce or ignore calls depending on various conditions; the preload may not complete before `present(checkout:)` is called, in which case the buyer may still see a spinner while the checkout session is finalized.
1. Preloading results in background network requests and additional CPU/memory utilization for the client and should be used responsibly. For example, conditionally based on state of the client and when there is a high likelihood that the buyer will soon request to checkout.


### Monitoring the lifecycle of a checkout session

You can use the `ShopifyCheckoutSheetKitDelegate` protocol to register callbacks for key lifecycle events during the checkout session:

```swift
extension MyViewController: ShopifyCheckoutSheetKitDelegate {
  func checkoutDidComplete() {
    // Called when the checkout was completed successfully by the buyer.
    // Use this to update UI, reset cart state, etc.
  }

  func checkoutDidCancel() {
    // Called when the checkout was canceled by the buyer.
    // Use this to call `dismiss(animated:)`, etc.
  }

  func checkoutDidFail(error: CheckoutError) {
    // Called when the checkout encountered an error and has been aborted. The callback
    // provides a `CheckoutError` enum, with one of the following values:

	/// Internal error: exception within the Checkout SDK code
	/// You can inspect and log the Erorr and stacktrace to identify the problem.
	case sdkError(underlying: Swift.Error)

	/// Issued when the provided checkout URL results in an error related to shop being on checkout.liquid.
	/// The SDK only supports stores migrated for extensibility.
	case checkoutLiquidNotMigrated(message: String)

	/// Unavailable error: checkout cannot be initiated or completed, e.g. due to network or server-side error
        /// The provided message describes the error and may be logged and presented to the buyer.
	case checkoutUnavailable(message: String)

	/// Expired error: checkout session associated with provided checkoutURL is no longer available.
        /// The provided message describes the error and may be logged and presented to the buyer.
	case checkoutExpired(message: String)
  }

  func checkoutDidClickLink(url: URL) {
    // Called when the buyer clicks a link within the checkout experience:
    //  - email address (`mailto:`),
    //  - telephone number (`tel:`),
    //  - web (`http:`)
    // and is being directed outside the application.
  }

  // Issued when the Checkout has emit a standard or custom Web Pixel event.
  // Note that the event must be handled by the consuming app, and will not be sent from inside the checkout.
  // See below for more information.
  func checkoutDidEmitWebPixelEvent(event: PixelEvent) {
    switch event {
      case .standardEvent(let standardEvent):
        recordAnalyticsEvent(standardEvent)
      case .customEvent(let customEvent):
        recordAnalyticsEvent(customEvent)
    }
  }
}
```

#### Integrating with Web Pixels, monitoring behavioral data

App developers can use [lifecycle events](#monitoring-the-lifecycle-of-a-checkout-session) to monitor and log the status of a checkout session. 

**To safeguard user privacy, Web Pixel events will not be dispatched from within the Checkout webview.** Instead, these events will be relayed back to your application through the checkoutDidEmitWebPixelEvent delegate hook. The responsibility then falls on the application developer to ensure adherence to Apple privacy protocols before disseminating these events to third-party providers.

Here's how you might intercept these events and relay them to a third party provider:

```swift
class MyViewController: UIViewController {
  private func sendEventToAnalytics(event: StandardEvent) {
    // Send standard event to third-party providers
  }

  private func sendEventToAnalytics(event: CustomEvent) {
    // Send custom event to third-party providers
  }

  private func recordAnalyticsEvent(standardEvent: StandardEvent) {
    if hasPermissionToCaptureEvents() {
      sendEventToAnalytics(event: standardEvent)
    }
  }

  private func recordAnalyticsEvent(customEvent: CustomEvent) {
    if hasPermissionToCaptureEvents() {
      sendEventToAnalytics(event: CustomEvent)
    }
  }
}

extension MyViewController: ShopifyCheckoutSheetKitDelegate {
  func checkoutDidEmitWebPixelEvent(event: PixelEvent) {
    switch event {
      case .standardEvent(let standardEvent):
        recordAnalyticsEvent(standardEvent: standardEvent)
      case .customEvent(let customEvent):
        recordAnalyticsEvent(customEvent: customEvent)
    }
  }
}
```

**Note that you will likely need to augment these events with customer/session information derived from app state.**

_Also note that the `customData` attribute of CustomPixelEvent can take on any shape. As such, this attribute will be returned as a String. Client applications should define a custom data type and deserialize the `customData` string into that type._

### Integrating identity & customer accounts

Buyer-aware checkout experience reduces friction and increases conversion. Depending on the context of the buyer (guest or signed-in), knowledge of buyer preferences, or account/identity system, the application can use one of the following methods to initialize a personalized and contextualized buyer experience.

#### Cart: buyer bag, identity, and preferences

In addition to specifying the line items, the Cart can include buyer identity (name, email, address, etc.), and delivery and payment preferences: see [guide](<[url](https://shopify.dev/docs/custom-storefronts/building-with-the-storefront-api/cart/manage)>). Included information will be used to present pre-filled and pre-selected choices to the buyer within checkout.

#### Multipass

[Shopify Plus](https://help.shopify.com/en/manual/intro-to-shopify/pricing-plans/plans-features/shopify-plus-plan) merchants using [Classic Customer Accounts](https://help.shopify.com/en/manual/customers/customer-accounts/classic-customer-accounts) can use [Multipass](https://shopify.dev/docs/api/multipass) ([API documentation](https://shopify.dev/docs/api/multipass)) to integrate an external identity system and initialize a buyer-aware checkout session.

```json
{
  "email": "<Customer's email address>",
  "created_at": "<Current timestamp in ISO8601 encoding>",
  "remote_ip": "<Client IP address>",
  "return_to": "<Checkout URL obtained from Storefront API>",
  ...
}
```

1. Follow the [Multipass documentation](https://shopify.dev/docs/api/multipass) to create a Multipass URL and set `return_to` to be the obtained `checkoutUrl`
2. Provide the Multipass URL to `present(checkout:)`

_Note: the above JSON omits useful customer attributes that should be provided where possible and encryption and signing should be done server-side to ensure Multipass keys are kept secret._

#### Shop Pay

To initialize accelerated Shop Pay checkout, the cart can set a [walletPreference](https://shopify.dev/docs/api/storefront/latest/mutations/cartBuyerIdentityUpdate#field-cartbuyeridentityinput-walletpreferences) to 'shop_pay'. The sign-in state of the buyer is app-local. The buyer will be prompted to sign in to their Shop account on their first checkout, and their sign-in state will be remembered for future checkout sessions.

#### Customer Account API

We are working on a library to provide buyer sign-in and authentication powered by the [new Customer Account API](https://www.shopify.com/partners/blog/introducing-customer-account-api-for-headless-stores)—stay tuned.

---

### Contributing

We welcome code contributions, feature requests, and reporting of issues. Please see [guidelines and instructions](.github/CONTRIBUTING.md).

### License

Checkout Sheet Kit is provided under an [MIT License](LICENSE).

