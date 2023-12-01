# Shopify Checkout Kit - Swift

[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](https://github.com/Shopify/checkout-kit-swift/blob/main/LICENSE) [![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-2ebb4e.svg?style=flat)](https://swift.org/package-manager/) ![Tests](https://github.com/shopify/checkout-kit-swift/actions/workflows/test-sdk.yml/badge.svg?branch=main)

![image](https://github.com/Shopify/checkout-kit-swift/assets/2034704/77912f52-4fca-45ee-92ec-5094ed50313d)


**Shopify Checkout Kit** is a Swift Package library, part of [Shopify's Native SDKs](https://shopify.dev/docs/custom-storefronts/mobile-apps), that enables Swift apps to provide the world’s highest converting, customizable, one-page checkout within the app. The presented experience is a fully-featured checkout that preserves all of the store customizations: Checkout UI extensions, Functions, branding, and more. It also provides platform idiomatic defaults such as support for light and dark mode, and convenient developer APIs to embed, customize, and follow the lifecycle of the checkout experience. Check out our blog to [learn how and why we built Checkout Kit](https://www.shopify.com/partners/blog/mobile-checkout-sdks-for-ios-and-android).

### Requirements

- Swift 5.7+
- iOS SDK 13.0+
- The SDK is not compatible with checkout.liquid. The Shopify Store must be migrated for extensibility

### Getting Started

The SDK is an open-source [Swift Package library](https://www.swift.org/package-manager/). As a quick start, see [sample projects](Samples/README.md) or use one of the following ways to integrate the SDK into your project:

#### Package.swift

```swift
dependencies: [
  .package(url: "https://github.com/Shopify/checkout-kit-swift", from: "0.7.0")
]
```

#### Xcode

1. Open your Xcode project
2. Navigate to `File` > `Add Package Dependencies...`
3. Enter `https://github.com/Shopify/checkout-kit-swift` into the search box
4. Click `Add Package`

For more details on managing Swift Package dependencies in Xcode, please see [Apple's documentation](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app).

#### CocoaPods

```ruby
pod "ShopifyCheckoutKit", "~> 0.7"
```

For more information on CocoaPods, please see their [getting started guide](https://guides.cocoapods.org/using/getting-started.html).

### Basic Usage

Once the SDK has been added as a dependency, you can import the library:

```swift
import ShopifyCheckoutKit
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
import ShopifyCheckoutKit

class MyViewController: UIViewController {
  func presentCheckout() {
    let checkoutURL: URL = // from cart object
    ShopifyCheckoutKit.present(checkout: checkoutURL, from: self, delegate: self)
  }
}
```

To help optimize and deliver the best experience the SDK also provides a [preloading API](#preloading) that can be used to initialize the checkout session in the background and ahead of time.

### Configuration

The SDK provides a way to customize the presented checkout experience via the `ShopifyCheckoutKit.configuration` object.

#### `colorScheme`

By default, the SDK will match the user's device color appearance. This behavior can be customized via the `colorScheme` property:

```swift
// [Default] Automatically toggle idiomatic light and dark themes based on device preference (`UITraitCollection`)
ShopifyCheckoutKit.configuration.colorScheme = .automatic

// Force idiomatic light color scheme
ShopifyCheckoutKit.configuration.colorScheme = .light

// Force idiomatic dark color scheme
ShopifyCheckoutKit.configuration.colorScheme = .dark

// Force web theme, as rendered by a mobile browser
ShopifyCheckoutKit.configuration.colorScheme = .web
```

#### `spinnerColor`

If the checkout session is not ready and being initialized, a loading spinner is shown and can be customized via the `spinnerColor` property:

```swift
// Use a custom UI color
ShopifyCheckoutKit.configuration.spinnerColor = UIColor(red: 0.09, green: 0.45, blue: 0.69, alpha: 1.00)

// Use a system color
ShopifyCheckoutKit.configuration.spinnerColor = .systemBlue
```

_Note: use preloading to optimize and deliver an instant buyer experience._

#### `backgroundColor`

While the checkout session is being initialized, the background color of the view can be customized via the `backgroundColor` property:

```swift
// Use a custom UI color
ShopifyCheckoutKit.configuration.backgroundColor = UIColor(red: 0.09, green: 0.45, blue: 0.69, alpha: 1.00)

// Use a system color
ShopifyCheckoutKit.configuration.backgroundColor = .systemBackground
```

### Preloading

Initializing a checkout session requires communicating with Shopify servers and, depending on the network weather and the quality of the buyer's connection, can result in undesirable waiting time for the buyer. To help optimize and deliver the best experience, the SDK provides a preloading hint that allows app developers to signal and initialize the checkout session in the background and ahead of time.

Preloading is an advanced feature that can be disabled via a runtime flag:

```swift
ShopifyCheckoutKit.configure {
  $0.preloading.enabled = false // defaults to true
}
```

Once enabled, preloading a checkout is as simple as:

```swift
ShopifyCheckoutKit.preload(checkout: checkoutURL)
```

**Important considerations:**

1. Initiating preload results in background network requests and additional CPU/memory utilization for the client, and should be used when there is a high likelihood that the buyer will soon request to checkout—e.g. when the buyer navigates to the cart overview or a similar app-specific experience.
2. A preloaded checkout session reflects the cart contents at the time when `preload` is called. If the cart is updated after `preload` is called, the application needs to call `preload` again to reflect the updated checkout session.
3. Calling `preload(checkout:)` is a hint, not a guarantee: the library may debounce or ignore calls to this API depending on various conditions; the preload may not complete before `present(checkout:)` is called, in which case the buyer may still see a spinner while the checkout session is finalized.

### Monitoring the lifecycle of a checkout session

You can use the `ShopifyCheckoutKitDelegate` protocol to register callbacks for key lifecycle events during the checkout session:

```swift
extension MyViewController: ShopifyCheckoutKitDelegate {
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
}
```

#### Integrating with Web Pixels, monitoring behavioral data

App developers can use [lifecycle events](#monitoring-the-lifecycle-of-a-checkout-session) to monitor and log the status of a checkout session. Web Pixel events are currently not executed within rendered checkout. Support for customer events and behavioral analytics is under development and will be available prior to the general availability of SDK.

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

Checkout Kit is provided under an [MIT License](LICENSE).
