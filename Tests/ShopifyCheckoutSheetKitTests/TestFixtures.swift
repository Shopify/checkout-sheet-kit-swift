/*
 MIT License

 Copyright 2023 - Present, Shopify Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

@testable import ShopifyCheckoutSheetKit

// MARK: - Cart Fixtures

// Test fixtures for creating test data with sensible defaults.
// Customize only the fields you need for your test.

/**
 Creates a test Cart instance with sensible defaults.

 Example:
 ```swift
 let cart = createTestCart(
     id: "custom-cart-id",
     totalAmount: "99.99"
 )
 ```
 */
func createTestCart(
    id: String = "gid://shopify/Cart/test-cart-123",
    subtotalAmount: String = "10.00",
    totalAmount: String = "10.00",
    currencyCode: String = "USD",
    email: String? = nil
) -> Cart {
    Cart(
        id: id,
        lines: [],
        cost: CartCost(
            subtotalAmount: Money(amount: subtotalAmount, currencyCode: currencyCode),
            totalAmount: Money(amount: totalAmount, currencyCode: currencyCode)
        ),
        buyerIdentity: CartBuyerIdentity(
            email: email,
            phone: nil,
            customer: nil,
            countryCode: "US"
        ),
        deliveryGroups: [],
        discountCodes: [],
        appliedGiftCards: [],
        discountAllocations: [],
        delivery: CartDelivery(addresses: [])
    )
}

/**
 Creates a test OrderConfirmation instance with sensible defaults.

 Example:
 ```swift
 let confirmation = createTestOrderConfirmation(orderId: "order-123")
 ```
 */
func createTestOrderConfirmation(
    orderId: String = "gid://shopify/Order/test-order-123",
    orderNumber: String? = nil,
    isFirstOrder: Bool = false,
    url: String? = nil
) -> OrderConfirmation {
    OrderConfirmation(
        url: url,
        order: OrderConfirmation.Order(id: orderId),
        number: orderNumber,
        isFirstOrder: isFirstOrder
    )
}

// MARK: - Event Fixtures

/**
 Creates a test CheckoutStartEvent instance with sensible defaults.

 Example:
 ```swift
 let event = createTestCheckoutStartEvent(
     cart: createTestCart(totalAmount: "50.00")
 )
 ```
 */
func createTestCheckoutStartEvent(
    cart: Cart? = nil
) -> CheckoutStartEvent {
    CheckoutStartEvent(cart: cart ?? createTestCart())
}

/**
 Creates a test CheckoutCompleteEvent instance with sensible defaults.

 Example:
 ```swift
 let event = createTestCheckoutCompleteEvent(
     orderConfirmation: createTestOrderConfirmation(orderId: "order-456"),
     cart: createTestCart(totalAmount: "100.00")
 )
 ```
 */
func createTestCheckoutCompleteEvent(
    cart: Cart? = nil,
    orderConfirmation: OrderConfirmation? = nil
) -> CheckoutCompleteEvent {
    CheckoutCompleteEvent(
        orderConfirmation: orderConfirmation ?? createTestOrderConfirmation(),
        cart: cart ?? createTestCart()
    )
}

// MARK: - JSON Fixtures

/**
 Creates a JSON string for a test cart with sensible defaults.

 Example:
 ```swift
 let json = createTestCartJSON(id: "cart-456", totalAmount: "75.00")
 ```
 */
func createTestCartJSON(
    id: String = "gid://shopify/Cart/test-cart-123",
    subtotalAmount: String = "10.00",
    totalAmount: String = "10.00",
    currencyCode: String = "USD",
    email: String? = "test@example.com"
) -> String {
    """
    {
        "id": "\(id)",
        "lines": [],
        "cost": {
            "subtotalAmount": {
                "amount": "\(subtotalAmount)",
                "currencyCode": "\(currencyCode)"
            },
            "totalAmount": {
                "amount": "\(totalAmount)",
                "currencyCode": "\(currencyCode)"
            }
        },
        "buyerIdentity": {
            "email": \(email.map { "\"\($0)\"" } ?? "null"),
            "phone": null,
            "customer": null,
            "countryCode": "US"
        },
        "deliveryGroups": [],
        "discountCodes": [],
        "appliedGiftCards": [],
        "discountAllocations": [],
        "delivery": {
            "addresses": []
        }
    }
    """
}

/**
 Creates a JSON-RPC message string for checkout.start with sensible defaults.

 Example:
 ```swift
 let json = createCheckoutStartJSON(cartId: "cart-789")
 ```
 */
func createCheckoutStartJSON(
    cartId: String = "gid://shopify/Cart/test-cart-123",
    totalAmount: String = "10.00"
) -> String {
    """
    {
        "jsonrpc": "2.0",
        "method": "checkout.start",
        "params": {
            "cart": \(createTestCartJSON(id: cartId, totalAmount: totalAmount))
        }
    }
    """
}

/**
 Creates a JSON-RPC message string for checkout.complete with sensible defaults.

 Example:
 ```swift
 let json = createCheckoutCompleteJSON(orderId: "order-456")
 ```
 */
func createCheckoutCompleteJSON(
    orderId: String = "gid://shopify/Order/test-order-123",
    cartId: String = "gid://shopify/Cart/test-cart-123"
) -> String {
    """
    {
        "jsonrpc": "2.0",
        "method": "checkout.complete",
        "params": {
            "orderConfirmation": {
                "url": null,
                "order": {
                    "id": "\(orderId)"
                },
                "number": null,
                "isFirstOrder": false
            },
            "cart": \(createTestCartJSON(id: cartId))
        }
    }
    """
}
