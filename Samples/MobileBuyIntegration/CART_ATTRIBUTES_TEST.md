# Cart Attributes Test - Mobile SDK Issue Reproduction

## Overview

This implementation adds cart attributes support to the MobileBuyIntegration sample app to reproduce the issue where cart attributes are lost when using the mobile SDK (Checkout Sheet Kit) for checkout.

## Issue Summary

- **Problem**: Cart attributes are missing from orders completed through mobile SDK checkouts
- **Root Cause**: The mobile SDK doesn't handle cart attributes in its negotiation flow
- **Impact**: ALL mobile app checkouts lose cart attributes, regardless of payment method

## Changes Made

### 1. Cart Creation with Attributes

- Modified `StorefrontInputFactory.createCartInput()` to automatically add test cart attributes:
  - `checkout_ship_date`: "05/22/2025"
  - `grow_zone`: "10b"
  - `test_attribute`: "mobile_sdk_test"
  - `Tapcart`: "1"
  - `source`: "MobileBuyIntegration"
- Also adds a cart note: "Test order with cart attributes from MobileBuyIntegration sample app"

### 2. Cart Attributes Mutations

- Added `performCartAttributesUpdate()` method to update attributes after cart creation
- Added `performCartNoteUpdate()` method to update cart note

### 3. Cart Fragment Updates

- Updated `cartManagerFragment()` to query note and attributes fields
- This allows the app to display current cart attributes

### 4. UI Enhancements

- Added collapsible "Cart Attributes" section in CartView
- Displays current cart note and all attributes
- Shows green background for attributes, blue for note
- Shows warning if no attributes are present

### 5. Comprehensive Logging

- Added logging throughout the cart lifecycle:
  - Cart creation
  - Cart updates (lines add/update)
  - Checkout preload
  - Checkout presentation
  - Checkout completion
- Logs use emojis for easy visual tracking:
  - 🛒 for CartView logs
  - ⚠️ for warnings about missing attributes

## How to Test

### 1. Build and Run

```bash
# Open the sample app in Xcode
open Samples/MobileBuyIntegration/MobileBuyIntegration.xcodeproj

# Build and run on simulator or device
```

### 2. Create a Cart

1. Launch the app
2. Add any product to cart
3. Navigate to cart view

### 3. Verify Attributes Are Present

1. In the cart view, tap "Cart Attributes" to expand
2. You should see:
   - Cart note displayed in blue
   - 5 cart attributes displayed in green
   - Each attribute showing key and value

### 4. Complete Checkout

1. Tap "Check out" button
2. Watch the console logs - you'll see:
   - Cart attributes listed before checkout
   - Checkout URL being presented
   - Warning about attributes being lost after completion

### 5. Verify Issue

After checkout completes:

- Check the order in Shopify Admin
- The cart attributes will be MISSING from the order
- This confirms the mobile SDK issue

## Console Output Example

```
🛒 [CartView] Checkout button pressed
🛒 [CartView] Cart ID: Z2NwLXVzLWVhc3QxOjAxSlhBSFFROERWODdaSE5DTUtUSFJBSEY4
🛒 [CartView] Cart has 5 attributes:
🛒 [CartView]   - checkout_ship_date: 05/22/2025
🛒 [CartView]   - grow_zone: 10b
🛒 [CartView]   - test_attribute: mobile_sdk_test
🛒 [CartView]   - Tapcart: 1
🛒 [CartView]   - source: MobileBuyIntegration
🛒 [CartView] Cart note: Test order with cart attributes...

[CheckoutController] Presenting checkout with URL: https://...
[CheckoutController] Cart has 5 attributes before checkout
[CheckoutDelegate] Checkout completed. Order ID: ...
[CheckoutDelegate] ⚠️ Cart attributes were likely lost during mobile SDK checkout process
[CheckoutDelegate] ⚠️ This is the known issue where mobile SDK doesn't preserve cart attributes
```

## Expected vs Actual Results

### Expected (Web Checkout)

- Cart attributes are preserved in the final order
- Attributes visible in Shopify Admin

### Actual (Mobile SDK Checkout)

- Cart attributes are LOST during checkout
- Attributes NOT visible in Shopify Admin
- Confirms the issue described in the investigation

## Technical Details

### Files Modified

1. `StorefrontClient.swift` - Added attributes to cart creation
2. `CartManager.swift` - Added attribute update methods and logging
3. `Extensions/Storefront.swift` - Added note/attributes to cart fragment
4. `Views/CartView.swift` - Added UI to display attributes
5. `ViewControllers/CheckoutController.swift` - Added checkout logging

### Key Finding

The issue occurs because:

1. Cart attributes ARE correctly set via Storefront API
2. Attributes ARE present in the cart before checkout
3. Attributes ARE LOST when checkout completes through mobile SDK
4. The mobile SDK's `BuyerProposalDetailsFragment` lacks note/customAttributes fields
5. The mobile SDK's `useSubmitPayment` hook doesn't handle cart attributes

## Next Steps for Fix

1. Update `BuyerProposalDetailsFragment` to include note/customAttributes
2. Modify mobile SDK's `useSubmitPayment` to preserve attributes
3. Ensure attributes flow through the entire checkout negotiation
