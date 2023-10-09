# Mobile Checkout SDK - iOS

The **Mobile Checkout SDK for iOS** is a Swift Package library that allows iOS apps to easily present a Shopify checkout flow to a prospective buyer.

### Requirements

- Swift 5.7+
- iOS SDK 13.0+

### Getting Started

The **Mobile Checkout SDK for iOS** is published as an open source, [Swift Package library](https://www.swift.org/package-manager/). There are two ways to add the dependency, depending on your consuming project:

#### Package.swift

```swift
dependencies: [
  .package(url: "https://github.com/Shopify-Partners/mobile-checkout-sdk-ios", from: "0.1.0")
]
```

#### Xcode

1. Open your Xcode project
2. Navigate to `File` > `Add Packages...`
3. Enter `https://github.com/Shopify-Partners/mobile-checkout-sdk-ios` into the search box
4. Click `Add Package`

For more details on managing Swift Package dependencies in Xcode, please see [Apple's documentation](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app).

### Basic Usage

Once the package has been added as a dependency, you can import the library.

```swift
import ShopifyCheckout
```

The library is designed to be used in conjunction with the [Storefront GraphQL API](https://shopify.dev/docs/api/storefront). Shopify provides the [Mobile Buy SDK for iOS](https://github.com/Shopify/mobile-buy-sdk-ios) which can be used to communicate with the API, however, you are also able to bring your own implementation if you choose.

Before you can present a checkout to the buyer, you must first retrieve a checkout URL. Currently, we only support checkout URLs retrieved via the [`Cart` endpoint in the Storefront GraphQL API](https://shopify.dev/docs/custom-storefronts/building-with-the-storefront-api/cart/manage).

If you are using the Mobile Buy SDK, you can do something similar to this:

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

Once you have a checkout URL object, you can present a checkout experience to the buyer using the `present(checkout:)` function.

```swift
import UIKit
import ShopifyCheckout

class MyViewController: UIViewController {
  func presentCheckout() {
    let checkoutURL: URL = // from cart object
    ShopifyCheckout.present(checkout: checkoutURL, from: self, delegate: self)
  }
}
```

We also provide a `ShopifyCheckoutDelegate` protocol which you can use to be notified of lifecycle events during checkout.

```swift
extension MyViewController: ShopifyCheckoutDelegate {
  func checkoutDidComplete() {
    // Called when the checkout was completed successfully by the buyer. Use this as an opportunity to reset any cart state.
  }

  func checkoutDidCancel() {
    // The buyer cancelled the checkout. You should use this to call `dismiss(animated:)`.
  }

  func checkoutDidFail(error: CheckoutError) {
    // The buyer encountered an error during checkout.
    
    // CheckoutError is an enum with the following possible values: 
    
	/// Issued when an internal error within Shopify Checkout SDK
	/// In event of an sdkError you could use the stacktrace to inform you of how to proceed,
	/// if the issue persists, it is recommended to open a bug report in http://github.com/Shopify/mobile-checkout-sdk-ios
	case sdkError(underlying: Swift.Error)


	/// Issued when checkout has encountered a unrecoverable error (for example server side error)
	/// if the issue persists, it is recommended to open a bug report in http://github.com/Shopify/mobile-checkout-sdk-ios
	case checkoutUnavailable(message: String)

	/// Issued when checkout is no longer available and will no longer be available with the checkout url supplied.
	/// This may happen when the user has paused on checkout for a long period (hours) and then attempted to proceed again with the same checkout url
	/// In event of checkoutExpired, a new checkout url will need to be generated
	case checkoutExpired(message: String)
  }

  func checkoutDidClickLink(url: URL) {
    // Called when the buyer clicked a link e.g email address or telephone number via `mailto:` or `tel:` or `http` links directed outside the application.
  }
}
```

### Preloading

The checkout experience is complex and can be costly to load, especially on mobile cellular networks. Therefore, we provide the ability for consuming apps to hint to the library that checkout may be presented soon and should preload in the background. This is a feature
that needs to be enabled in the ShopifyChecout configuration

```swift
ShopifyCheckout.configure {
  $0.preloading.enabled = true // defaults to false
}

```swift
ShopifyCheckout.preload(checkout: url)
```

**It is important to note a few things when utilizing preloading:**

1. Once you call `preload(checkout:)` for a given URL, you **must** call it again if the matching cart's contents ever changes. Failure to do so may result in an out of date checkout being presented.
2. Calling `preload(checkout:)` should be considered a hint and not a guarantee. The library may debounce or ignore calls to this API depending on various conditions.

### Configuration

The library provides a way to customize the checkout experience via the `ShopifyCheckout.configuration` object.

#### `colorScheme`

When checkout is presented, the look and feel can be configured using the `colorScheme` property. By default, it will match the user's device appearance. For example:

```swift
// Automatically switch between light and dark themes based on device preference (`UITraitCollection`)
ShopifyCheckout.configuration.colorScheme = .automatic

// Always force an idiomatic, light color scheme
ShopifyCheckout.configuration.colorScheme = .light

// Always force an idiomatic, dark color scheme
ShopifyCheckout.configuration.colorScheme = .dark

// Match the look and feel of checkout via a desktop or mobile browser.
ShopifyCheckout.configuration.colorScheme = .web
```

#### `spinnerColor`

The loading spinner shown when checkout is presented can be modified through the `spinnerColor` property on the configuration object:

```swift
// Use a custom UI color
ShopifyCheckout.configuration.spinnerColor = UIColor(red: 0.09, green: 0.45, blue: 0.69, alpha: 1.00)

// Use a system color
ShopifyCheckout.configuration.spinnerColor = .systemBlue
```

### Customer Accounts

An authenticated checkout experience reduces friction and increases conversion. A complete customer authentication solution is currently being designed. Until then [Shopify Plus](https://help.shopify.com/en/manual/intro-to-shopify/pricing-plans/plans-features/shopify-plus-plan) merchants using [Classic Customer Accounts](https://help.shopify.com/en/manual/customers/customer-accounts/classic-customer-accounts) can use [Multipass](https://shopify.dev/docs/api/multipass).

#### Multipass

Follow the [Multipass documentation](https://shopify.dev/docs/api/multipass) to create a multipass URL. The `'return_to'` attribute in the customer information JSON should be set to the checkout URL obtained from the Storefront API, e.g:

```json
{
  "email": "<Customer's email address>",
  "created_at": "<Current timestamp in ISO8601 encoding>",
  "remote_ip": "<Client IP address>",
  "return_to": "<Checkout URL obtained from Storefront API>",
  ...
}
```

The resulting multipass URL should then be submitted to `ShopifyCheckout.present()`. When the WebView is presented, multipass authentication will complete before redirecting the authenticated customer to checkout.

##### Notes

- The JSON above omits useful customer attributes that should be provided where possible,
- Encryption and signing should be done server-side to ensure multipass keys can be kept secret.

### Sample Projects

We provide sample projects in this repository which demonstrate integrating the package in various ways. For more information, see [`Samples/README.md`](Samples/README.md).

### Contributing

The filing of issues, feature requests, and code contributions via pull requests are welcome. For more details on how to contribute to this repository, please see [CONTRIBUTING.md](.github/CONTRIBUTING.md).
