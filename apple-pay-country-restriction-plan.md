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

## Enhanced Implementation Plan

### 📋 Overview

Implement configurable country restrictions for Apple Pay shipping addresses to handle merchant-specific limitations while maintaining backward compatibility.

### 🎯 Implementation Steps

#### Phase 1: Core Configuration (ApplePayConfiguration.swift)

1. **Add `supportedShippingCountries` property** to `ApplePayConfiguration` class

   - Type: `Set<String>?` for O(1) lookup performance
   - Default: `nil` (all countries allowed - backward compatible)
   - Store ISO 3166-1 alpha-2 country codes

2. **Update initializer** with new parameter (default nil)

3. **Update copy initializer** in `ApplePayConfiguration`

4. **No changes needed** to `ApplePayConfigurationWrapper` (automatically passes through)

#### Phase 2: Country Validation Logic

1. **Leverage existing country code infrastructure** in PKEncoder

   - Use existing `mapToCountryCode()` for normalization
   - Reuse `US_TERRITORY_COUNTRY_CODES` and `FallbackCountryCodes` mappings

2. **Update `didSelectShippingContact` method** in ApplePayAuthorizationDelegate+Controller.swift:

   - Add validation after line 41 (after clearing selected shipping method)
   - Use PKEncoder's existing country normalization
   - Return specific error for unsupported countries

3. **Create localized error message** in ValidationErrors:
   ```swift
   static var shippingCountryNotSupported: Error {
       PKPaymentRequest.paymentShippingAddressUnserviceableError(
           withLocalizedDescription: "Shipping to this country is not available through Apple Pay. Please use standard checkout."
       )
   }
   ```

#### Phase 3: Testing Strategy

1. **Unit Tests** for ApplePayAuthorizationDelegateControllerTests:

   - Test country validation with restrictions enabled
   - Test backward compatibility (nil/empty set)
   - Test US territory handling
   - Test error message presentation
   - Test state preservation on country change

2. **Test Cases**:
   - `test_didSelectShippingContact_withSupportedCountry_shouldProceed`
   - `test_didSelectShippingContact_withUnsupportedCountry_shouldShowError`
   - `test_didSelectShippingContact_withNoRestrictions_shouldAllowAll`
   - `test_didSelectShippingContact_withUSTerritory_shouldNormalizeCorrectly`

#### Phase 4: Sample App Updates

1. **Update CheckoutViewController** with example configuration
2. **Add toggle UI** for testing different country restriction scenarios
3. **Document configuration examples** in sample app

#### Phase 5: Documentation & Analytics

1. **API Documentation**:

   - Add comprehensive documentation to `supportedShippingCountries` property
   - Include examples for common merchant scenarios

2. **Migration Guide**:

   - Document that existing integrations are unaffected (nil = all countries)
   - Provide clear upgrade path examples

3. **Analytics Tracking** (future consideration):
   - Log when users encounter country restrictions
   - Track fallback to standard checkout

### 🔍 Key Implementation Details

#### Country Code Normalization

- Leverage existing PKEncoder's `mapToCountryCode()` method
- Handles US territories (PR, VI, GU, MP, AS, UM) correctly
- Maps fallback codes (e.g., UK → GB, ZZ for unknown)

#### Error Handling

- Use existing `ValidationErrors` structure
- Maintain consistent error presentation with other validation errors
- Clear, actionable error messages directing to standard checkout

#### Performance Considerations

- Use `Set<String>` for O(1) country lookup
- Validation occurs only once per address selection
- No additional API calls required

### 🧪 Testing Approach

1. Run tests with: `DEV_NO_AUTO_UPDATE=1 /opt/dev/bin/dev test Tests/ShopifyAcceleratedCheckoutsTests/Wallets/ApplePay/ApplePayAuthorizationDelegate/ApplePayAuthorizationDelegateControllerTests.swift`
2. Type check with: `DEV_NO_AUTO_UPDATE=1 /opt/dev/bin/dev type-check Sources/ShopifyAcceleratedCheckouts/Wallets/ApplePay/ApplePayConfiguration.swift`

### 🚀 Rollout Strategy

1. **Phase 1**: Deploy configuration changes (backward compatible)
2. **Phase 2**: Enable for test merchants
3. **Phase 3**: Gradual rollout with monitoring
4. **Phase 4**: Full release with documentation

### ✅ Success Criteria

- Zero impact on existing integrations
- Clear error messaging for restricted countries
- Comprehensive test coverage
- Performance within existing SLAs
- Smooth merchant adoption path
