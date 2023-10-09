# Mobile Checkout SDK - iOS

**Mobile Checkout SDK for iOS** is a Swift Package library that enables iOS apps to present a Shopify checkout flow to a prospective buyer. The presented experience is a fully-featured checkout that respects merchant configuration (settings, branding, etc), executes installed extensions, ..., and provides idiomatic defaults such as support for light and dark mode, in addition to developer APIs and interfaces to easily initiate and manage the lifecycle of a checkout session. Check out our developer blog to [learn how Mobile Checkout SDK is built](TODO).

### Requirements
- Swift 5.7+
- iOS SDK 13.0+

### Getting Started
The SDK is an open-source [Swift Package library](https://www.swift.org/package-manager/). As a quick start, see [sample projects](Samples/README.md) or use one of the following ways to integrate SDK into your project:

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

Once the SDK has been added as a dependency, you can import the library:

```swift
import ShopifyCheckout
```

To present a checkout to the buyer your application must first obtain a checkout URL. The most common way is to use the [Storefront GraphQL API](https://shopify.dev/docs/api/storefront) to assemble a cart (via `cartCreate` and related update mutations) and query the [checkoutUrl](https://shopify.dev/docs/api/storefront/2023-10/objects/Cart#field-cart-checkouturl). You can use any GQL client to accomplish this and we recommend Shopify [Mobile Buy SDK for iOS](https://github.com/Shopify/mobile-buy-sdk-ios) to simplify the development workflow:

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

The `checkoutURL` object is a standard web checkout URL that can be opened in any browser. To present a native checkout sheet in your iOS application, all we have to do is provide the `checkoutUrl`, alongside optional runtime configuration settings, to the `present(checkout:)` function provided by the SDK:

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

### Configuration

The SDK provides a way to customize the presented checkout experience via the `ShopifyCheckout.configuration` object.

#### `colorScheme`
By default, the SDK will match the user's device color appearance. This behavior can be customized via `colorScheme` property:

```swift
// [Default] Automatically toggle idiomatic light and dark themes based on device preference (`UITraitCollection`)
ShopifyCheckout.configuration.colorScheme = .automatic

// Force idiomatic light color scheme
ShopifyCheckout.configuration.colorScheme = .light

// Force idiomatic dark color scheme
ShopifyCheckout.configuration.colorScheme = .dark

// Force web theme, as rendered by mobile browser
ShopifyCheckout.configuration.colorScheme = .web
```

#### `spinnerColor`
If the checkout session is not ready and being initialized, a loading spinner is shown and can be customized via `spinnerColor` property:

```swift
// Use a custom UI color
ShopifyCheckout.configuration.spinnerColor = UIColor(red: 0.09, green: 0.45, blue: 0.69, alpha: 1.00)

// Use a system color
ShopifyCheckout.configuration.spinnerColor = .systemBlue
```
_Note: use preloading to optimize and deliver an instant buyer experience._

### Preloading
Initializing a checkout session requires communicating with Shopify servers and, depending on the network weather and the quality of the buyer's connection, can result in significant waiting time for the buyer. To help optimize and deliver the best experience the SDK provides a preloading hint that allows app developers to signal and initialize the checkout session in the background and ahead of time.

Preloading is an advanced feature and is disabled by default, to enable:
```swift
ShopifyCheckout.configure {
  $0.preloading.enabled = true // defaults to false
}
```

Once enabled, preloading a checkout is as simple as:
```swift
ShopifyCheckout.preload(checkout: checkoutURL)
```

**Important considerations:**
1. Initiating preload results in background network requests and additional CPU/memory utilization for the client, and should be used when there is a high likelihood that the buyer will soon request to checkout.
2. Preloaded checkout session reflects the cart contents at the time when `preload` is called: if the cart is updated after `preload` is called, the application needs to call `preload` again to reflect the updated checkout session.
3. Calling `preload(checkout:)` is a hint, not a guarantee: the library may debounce or ignore calls to this API depending on various conditions; the preload may not complete before `presentCheckout` is called, in which case the buyer may still see a spinner while the checkout session is finalized.


### Monitoring the lifecycle of a checkout session
You can use the `ShopifyCheckoutDelegate` protocol to register callbacks for key lifecycle events during the checkout session:

```swift
extension MyViewController: ShopifyCheckoutDelegate {
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

	/// Unavailable error: checkout cannot be initiated or completed, e.g. due to network or server-side error
        /// You can inspect and log the provided message to identify the problem.
	case checkoutUnavailable(message: String)

	/// Expired error: checkout session associated with provided checkoutUrl is no longer available.
        /// You can inspect and log the provided message to identify the problem, and use this as a signal
        /// to request a new checkoutUrl session or build a new cart.
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

### Integrating identity & customer accounts
Buyer-aware checkout experience reduces friction and increases conversion. Depending on the context of the buyer (guest or signed-in), knowledge of buyer preferences, or account/identity system, the application can use one of the following methods to initialize personalized and contextualized buyer experience.

#### Cart: buyer bag, identity, and preferences
In addition to specifying the line items, the Cart can include buyer identity (name, email, address, etc), and delivery and payment preferences: see [guide]([url](https://shopify.dev/docs/custom-storefronts/building-with-the-storefront-api/cart/manage)). Included information will be used to present pre-filled and pre-selected choices to the buyer within checkout.

#### Multipass
[Shopify Plus](https://help.shopify.com/en/manual/intro-to-shopify/pricing-plans/plans-features/shopify-plus-plan) merchants using [Classic Customer Accounts](https://help.shopify.com/en/manual/customers/customer-accounts/classic-customer-accounts) can use [Multipass](https://shopify.dev/docs/api/multipass) ([API documentation](https://shopify.dev/docs/api/multipass)) to integrate external identity system and initialize a buyer-aware checkout session. 

```json
{
  "email": "<Customer's email address>",
  "created_at": "<Current timestamp in ISO8601 encoding>",
  "remote_ip": "<Client IP address>",
  "return_to": "<Checkout URL obtained from Storefront API>",
  ...
}
```

1. Follow the [Multipass documentation](https://shopify.dev/docs/api/multipass) to create a multipass URL and set `return_to` to be the obtained `checkoutUrl`
2. Provide the multipass URL to `present(checkout:)`

_Note: above JSON omits useful customer attributes that should be provided where possible and encryption and signing should be done server-side to ensure multipass keys are kept secret._

#### Shop Pay 
To initialize accelerated Shop Pay checkout, the cart can set a [walletPreference]([url](https://shopify.dev/docs/api/storefront/2023-10/objects/CartBuyerIdentity#field-cartbuyeridentity-walletpreferences)) to 'SHOP_PAY'. The sign-in state of the buyer is app-local and the buyer will be prompted to sign in to their Shop account on first checkout, and their sign-in state will be remembered for future checkout sessions.

#### Customer Account API
We are working on a library to provide buyer sign-in and authentication powered by the [new Customer Account API](https://www.shopify.com/partners/blog/introducing-customer-account-api-for-headless-stores)—stay tuned.

---

### Contributing
We welcome code contributions, feature requests, and reporting of issues. Please see [guidelines and instructions](.github/CONTRIBUTING.md).
