# Apple Pay Shipping Country Restriction Implementation Plan

## Problem Statement

Merchants may have Apple Pay-specific shipping address limitations that are separate from their general shipping capabilities. For example:

- A merchant ships globally but their Apple Pay integration only supports US addresses due to tax calculation or fulfillment system limitations
- When a non-US address is selected in Apple Pay, the `cartDeliveryAddressesAdd` mutation succeeds but `deliveryGroups` returns empty
- Currently, we can only show generic "Shipping unavailable" errors instead of specific guidance

## Solution Overview

Add a configuration flag that allows merchants to specify which countries are supported for Apple Pay shipping addresses. When users select an unsupported country, they receive immediate, specific error feedback directing them to use standard checkout.

## Implementation Details

### 1. Configuration Changes

#### 1.1 Update `ApplePayConfiguration` Class

**File**: `Sources/ShopifyAcceleratedCheckouts/Wallets/ApplePay/ApplePayConfiguration.swift`

Add new property:

```swift
/// Countries supported for Apple Pay shipping addresses.
/// - Set of ISO 3166-1 alpha-2 country codes (e.g., "US", "CA", "GB")
/// - nil or empty = all countries allowed (backwards compatible)
/// - Separate from merchant's general shipping capabilities
public let supportedShippingCountries: Set<String>?
```

Update initializer:

```swift
public init(
    merchantIdentifier: String,
    contactFields: [RequiredContactFields],
    supportedShippingCountries: Set<String>? = nil  // Default nil for backwards compatibility
) {
    self.merchantIdentifier = merchantIdentifier
    self.contactFields = contactFields
    self.supportedShippingCountries = supportedShippingCountries
}
```

Update copy initializer:

```swift
package required init(copy: ApplePayConfiguration) {
    merchantIdentifier = copy.merchantIdentifier
    contactFields = copy.contactFields
    supportedShippingCountries = copy.supportedShippingCountries
}
```

#### 1.2 Update `ApplePayConfigurationWrapper`

**File**: Same file (lines 90-110)

No changes needed - the wrapper will automatically pass through the new property since it holds a reference to `ApplePayConfiguration`.

### 2. Country Validation Implementation

#### 2.1 Add Country Code Normalization Helper

**File**: `Sources/ShopifyAcceleratedCheckouts/Wallets/ApplePay/ApplePayAuthorizationDelegate/ApplePayAuthorizationDelegate+Helpers.swift` (new file)

```swift
@available(iOS 16.0, *)
extension ApplePayAuthorizationDelegate {
    /// Normalizes country codes to handle variations between different systems
    /// - Parameter code: Country code to normalize
    /// - Returns: Normalized ISO 3166-1 alpha-2 country code
    static func normalizeCountryCode(_ code: String?) -> String? {
        guard let code = code?.uppercased() else { return nil }

        // Handle common variations
        switch code {
        case "GB", "UK": return "GB"  // UK is sometimes used but GB is ISO standard
        default: return code
        }
    }
}
```

#### 2.2 Update `didSelectShippingContact` Delegate Method

**File**: `Sources/ShopifyAcceleratedCheckouts/Wallets/ApplePay/ApplePayAuthorizationDelegate/ApplePayAuthorizationDelegate+Controller.swift`

Update the method (lines 33-71) to add country validation:

```swift
func paymentAuthorizationController(
    _: PKPaymentAuthorizationController,
    didSelectShippingContact contact: PKContact
) async -> PKPaymentRequestShippingContactUpdate {
    pkEncoder.shippingContact = .success(contact)

    // Clear selected shipping method to prevent stale identifier errors
    pkEncoder.selectedShippingMethod = nil
    pkDecoder.selectedShippingMethod = nil

    // ADDED: Validate country if restrictions are configured
    if let supportedCountries = configuration.applePay.supportedShippingCountries,
       !supportedCountries.isEmpty {

        let contactCountry = ApplePayAuthorizationDelegate.normalizeCountryCode(
            contact.postalAddress?.isoCountryCode
        )

        // Check if country is supported
        if let country = contactCountry,
           !supportedCountries.contains(country) {

            let error = PKPaymentRequest.paymentShippingAddressUnserviceableError(
                withLocalizedDescription: "This country is not supported in Apple Pay. Please use checkout instead."
            )

            return pkDecoder.paymentRequestShippingContactUpdate(errors: [error])
        }
    }

    do {
        // ... existing code continues ...
    } catch {
        // ... existing error handling ...
    }
}
```

### 3. Error Message Updates

#### 3.1 Update ValidationErrors

**File**: `Sources/ShopifyAcceleratedCheckouts/Wallets/ApplePay/ApplePayAuthorizationDelegate/ApplePayAuthorizationDelegate+Errors.swift`

Add new error factory for country restrictions:

```swift
static var shippingCountryNotSupported: Error {
    PKPaymentRequest.paymentShippingAddressUnserviceableError(
        withLocalizedDescription: "This country is not supported in Apple Pay. Please use checkout instead."
    )
}
```

### 4. Sample App Updates

#### 4.1 Update Sample Configuration

**File**: `Samples/ShopifyAcceleratedCheckoutsApp/ShopifyAcceleratedCheckoutsApp/CheckoutViewController.swift`

```swift
let applePayConfig = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
    merchantIdentifier: "merchant.com.example",
    contactFields: [.email],
    supportedShippingCountries: ["US"]  // Example restriction
)
```

Add UI to toggle country restrictions for testing.

### 6. Considerations & Edge Cases

1. **Country Code Formats**

   - Handle ISO 3166-1 alpha-2 (2-letter codes)
   - Normalize common variations (UK/GB)
   - Case-insensitive comparison

2. **Performance**

   - Use Set for O(1) lookup
   - Minimize repeated validations

3. **Backwards Compatibility**

   - nil/empty = allow all (current behavior)
   - Existing integrations unaffected
   - Clear migration path

## Appendix: Example Configuration

### US-Only Merchant

```swift
let applePayConfig = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
    merchantIdentifier: "merchant.com.example",
    contactFields: [.email],
    supportedShippingCountries: ["US"]
)
```

### North America Merchant

```swift
let applePayConfig = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
    merchantIdentifier: "merchant.com.example",
    contactFields: [.email],
    supportedShippingCountries: ["US", "CA", "MX"]
)
```

### Global Merchant (No Restrictions)

```swift
let applePayConfig = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
    merchantIdentifier: "merchant.com.example",
    contactFields: [.email]
    // supportedShippingCountries omitted = all countries allowed
)
```
