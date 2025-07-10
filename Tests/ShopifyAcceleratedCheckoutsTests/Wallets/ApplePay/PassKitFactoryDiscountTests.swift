import XCTest

@testable import ShopifyAcceleratedCheckouts

// TODO: These tests need to be rewritten to work with the new struct-based StorefrontAPI.
// The previous implementation used init(fields:) which doesn't exist on structs.
// Creating complex nested Cart objects requires proper struct initialization with all required fields.
/*
 class PassKitFactoryDiscountTests: XCTestCase {
     var factory: PassKitFactory!

     override func setUp() {
         super.setUp()
         factory = PassKitFactory.shared
     }

     override func tearDown() {
         factory = nil
         super.tearDown()
     }

     func testShouldReturnLineItemDiscountAllocations() throws {
         // Create a cart with line items that have discount allocations
         let cart = try createCart(
             lineItemDiscounts: [
                 ("test-code-1", 10.0),
                 ("test-code-2", 20.0)
             ],
             cartDiscounts: [],
             discountCodes: [],
             currencyCode: "USD"
         )

         let result = try factory.createDiscountAllocations(cart: cart)

         XCTAssertEqual(result.count, 2)
         XCTAssertEqual(result[0].code, "test-code-1")
         XCTAssertEqual(result[0].amount, 10.0)
         XCTAssertEqual(result[0].currencyCode, "USD")
         XCTAssertEqual(result[1].code, "test-code-2")
         XCTAssertEqual(result[1].amount, 20.0)
         XCTAssertEqual(result[1].currencyCode, "USD")
     }

     func testShouldReturnCartDiscountAllocations() throws {
         // Create a cart with cart-level discount allocations
         let cart = try createCart(
             lineItemDiscounts: [],
             cartDiscounts: [
                 ("test-code-1", 10.0),
                 ("test-code-2", 20.0)
             ],
             discountCodes: [],
             currencyCode: "USD"
         )

         let result = try factory.createDiscountAllocations(cart: cart)

         XCTAssertEqual(result.count, 2)
         XCTAssertEqual(result[0].code, "test-code-1")
         XCTAssertEqual(result[0].amount, 10.0)
         XCTAssertEqual(result[0].currencyCode, "USD")
         XCTAssertEqual(result[1].code, "test-code-2")
         XCTAssertEqual(result[1].amount, 20.0)
         XCTAssertEqual(result[1].currencyCode, "USD")
     }

     func testShouldIncludeApplicableDiscountCodesAsZeroAmount() throws {
         // Create a cart with applicable discount codes not in allocations
         let cart = try createCart(
             lineItemDiscounts: [],
             cartDiscounts: [],
             discountCodes: [
                 ("test-code-1", true),
                 ("test-code-2", false) // Not applicable
             ],
             currencyCode: "USD"
         )

         let result = try factory.createDiscountAllocations(cart: cart)

         // Should only include applicable discount codes
         XCTAssertEqual(result.count, 1)
         XCTAssertEqual(result[0].code, "test-code-1")
         XCTAssertEqual(result[0].amount, 0)
         XCTAssertEqual(result[0].currencyCode, "USD")
     }

     func testShouldNotDuplicateAlreadyAccountedDiscountCodes() throws {
         // Create a cart where some discount codes are already in allocations
         let cart = try createCart(
             lineItemDiscounts: [("test-code-1", 10.0)],
             cartDiscounts: [("test-code-2", 10.0)],
             discountCodes: [
                 ("test-code-1", true), // Already in line items
                 ("test-code-2", true), // Already in cart allocations
                 ("test-code-3", true) // Not accounted for yet
             ],
             currencyCode: "USD"
         )

         let result = try factory.createDiscountAllocations(cart: cart)

         // Result should be: shipping (test-code-3 with 0), cart (test-code-2), line (test-code-1)
         XCTAssertEqual(result.count, 3)

         // First should be the unaccounted shipping discount
         XCTAssertEqual(result[0].code, "test-code-3")
         XCTAssertEqual(result[0].amount, 0)

         XCTAssertEqual(result[1].code, "test-code-2")
         XCTAssertEqual(result[1].amount, 10.0)

         XCTAssertEqual(result[2].code, "test-code-1")
         XCTAssertEqual(result[2].amount, 10.0)
     }

     func testShouldReturnDiscountsInCorrectOrder() throws {
         let cart = try createCart(
             lineItemDiscounts: [("test-code-1", 10.0)],
             cartDiscounts: [("test-code-3", 10.0)],
             discountCodes: [("test-code-2", true)],
             currencyCode: "USD"
         )

         let result = try factory.createDiscountAllocations(cart: cart)

         XCTAssertEqual(result.count, 3)

         // Shipping discount first (zero amount)
         XCTAssertEqual(result[0].code, "test-code-2")
         XCTAssertEqual(result[0].amount, 0)

         // Cart discount second
         XCTAssertEqual(result[1].code, "test-code-3")
         XCTAssertEqual(result[1].amount, 10.0)

         // Product discount last
         XCTAssertEqual(result[2].code, "test-code-1")
         XCTAssertEqual(result[2].amount, 10.0)
     }

     func testThrowsErrorForNilCart() {
         XCTAssertThrowsError(try factory.createDiscountAllocations(cart: nil)) { error in
             guard let shopifyError = error as? ShopifyAcceleratedCheckouts.Error else {
                 XCTFail("Expected ShopifyAcceleratedCheckouts.Error")
                 return
             }
             XCTAssertEqual(shopifyError.toString(), "cart is nil.")
         }
     }

     func testHandlesEmptyCart() throws {
         let cart = try createCart(
             lineItemDiscounts: [],
             cartDiscounts: [],
             discountCodes: [],
             currencyCode: "CAD"
         )

         let result = try factory.createDiscountAllocations(cart: cart)
         XCTAssertTrue(result.isEmpty)
     }

     func testHandlesMultipleCurrencies() throws {
         // Create cart with mixed currency codes
         let cartFields: [String: Any] = [
             "id": "cart123",
             "checkoutUrl": "https://example.com/checkout",
             "lines": [
                 "nodes": [
                     [
                         "__typename": "CartLine",
                         "id": "line1",
                         "quantity": 1,
                         "merchandise": createProductVariant(),
                         "cost": [
                             "totalAmount": ["amount": "100.00", "currencyCode": "USD"]
                         ],
                         "discountAllocations": [
                             createCartCodeDiscountAllocation(code: "USD-CODE", amount: 5.0, currencyCode: "USD")
                         ]
                     ] as [String: Any]
                 ]
             ],
             "cost": [
                 "totalAmount": ["amount": "100.00", "currencyCode": "EUR"],
                 "subtotalAmount": ["amount": "100.00", "currencyCode": "EUR"],
                 "totalTaxAmount": ["amount": "0.00", "currencyCode": "EUR"]
             ],
             "discountCodes": [
                 ["code": "EUR-CODE", "applicable": true]
             ],
             "discountAllocations": [],
             "totalQuantity": 1,
             "deliveryGroups": ["nodes": []],
             "buyerIdentity": ["email": "test@example.com"],
             "delivery": createDeliveryInfo()
         ]

         let cart = try Storefront.Cart(fields: cartFields)
         let result = try factory.createDiscountAllocations(cart: cart)

         XCTAssertEqual(result.count, 2)

         // Shipping discount with cart currency
         XCTAssertEqual(result[0].code, "EUR-CODE")
         XCTAssertEqual(result[0].currencyCode, "EUR")
         XCTAssertEqual(result[0].amount, 0)

         // Line item discount with its own currency
         XCTAssertEqual(result[1].code, "USD-CODE")
         XCTAssertEqual(result[1].currencyCode, "USD")
         XCTAssertEqual(result[1].amount, 5.0)
     }

     func testHandlesAutomaticDiscounts() throws {
         let cartFields: [String: Any] = [
             "id": "cart123",
             "checkoutUrl": "https://example.com/checkout",
             "lines": [
                 "nodes": [
                     [
                         "__typename": "CartLine",
                         "id": "line1",
                         "quantity": 1,
                         "merchandise": createProductVariant(),
                         "cost": [
                             "totalAmount": ["amount": "100.00", "currencyCode": "USD"]
                         ],
                         "discountAllocations": [
                             createCartAutomaticDiscountAllocation(title: "10% Off", amount: 10.0, currencyCode: "USD")
                         ]
                     ] as [String: Any]
                 ]
             ],
             "cost": createCost(),
             "discountCodes": [],
             "discountAllocations": [
                 createCartAutomaticDiscountAllocation(title: "Free Shipping", amount: 5.0, currencyCode: "USD")
             ],
             "totalQuantity": 1,
             "deliveryGroups": ["nodes": []],
             "buyerIdentity": ["email": "test@example.com"],
             "delivery": createDeliveryInfo()
         ]

         let cart = try Storefront.Cart(fields: cartFields)
         let result = try factory.createDiscountAllocations(cart: cart)

         XCTAssertEqual(result.count, 2)

         // Cart automatic discount
         XCTAssertNil(result[0].code)
         XCTAssertEqual(result[0].amount, 5.0)

         // Line item automatic discount
         XCTAssertNil(result[1].code)
         XCTAssertEqual(result[1].amount, 10.0)
     }

     func testHandlesLargeNumberOfDiscounts() throws {
         var lineItemDiscounts: [(String, Double)] = []
         var cartDiscounts: [(String, Double)] = []
         var discountCodes: [(String, Bool)] = []

         // Create 10 of each type
         for i in 1 ... 10 {
             lineItemDiscounts.append(("line-code-\(i)", Double(i)))
             cartDiscounts.append(("cart-code-\(i)", Double(i * 2)))
             discountCodes.append(("shipping-code-\(i)", true))
         }

         let cart = try createCart(
             lineItemDiscounts: lineItemDiscounts,
             cartDiscounts: cartDiscounts,
             discountCodes: discountCodes,
             currencyCode: "USD"
         )

         let result = try factory.createDiscountAllocations(cart: cart)

         // Should have 30 total: 10 shipping + 10 cart + 10 line
         XCTAssertEqual(result.count, 30)

         // Verify order: shipping first (0 amounts), then cart, then line items
         for i in 0 ..< 10 {
             XCTAssertEqual(result[i].amount, 0) // Shipping discounts
         }
         for i in 10 ..< 20 {
             XCTAssertGreaterThan(result[i].amount, 0) // Cart discounts
         }
         for i in 20 ..< 30 {
             XCTAssertGreaterThan(result[i].amount, 0) // Line discounts
         }
     }

     private func createCart(
         lineItemDiscounts: [(code: String, amount: Double)],
         cartDiscounts: [(code: String, amount: Double)],
         discountCodes: [(code: String, applicable: Bool)],
         currencyCode: String
     ) throws -> StorefrontAPI.Cart {
         var lineNodes: [[String: Any]] = []

         // Create line items with discounts
         if !lineItemDiscounts.isEmpty {
             for (index, discount) in lineItemDiscounts.enumerated() {
                 let lineItem: [String: Any] = [
                     "__typename": "CartLine",
                     "id": "line\(index)",
                     "quantity": 1,
                     "merchandise": createProductVariant(),
                     "cost": [
                         "totalAmount": ["amount": "100.00", "currencyCode": currencyCode]
                     ],
                     "discountAllocations": [
                         createCartCodeDiscountAllocation(
                             code: discount.code,
                             amount: discount.amount,
                             currencyCode: currencyCode
                         )
                     ]
                 ]
                 lineNodes.append(lineItem)
             }
         } else {
             // Add at least one line without discounts
             lineNodes.append([
                 "__typename": "CartLine",
                 "id": "line1",
                 "quantity": 1,
                 "merchandise": createProductVariant(),
                 "cost": [
                     "totalAmount": ["amount": "100.00", "currencyCode": currencyCode]
                 ],
                 "discountAllocations": []
             ])
         }

         // Create cart discount allocations
         let cartDiscountAllocations = cartDiscounts.map { discount in
             createCartCodeDiscountAllocation(
                 code: discount.code,
                 amount: discount.amount,
                 currencyCode: currencyCode
             )
         }

         // Create discount codes
         let discountCodeNodes = discountCodes.map { discountCode in
             ["code": discountCode.code, "applicable": discountCode.applicable] as [String: Any]
         }

         let cartFields: [String: Any] = [
             "id": "cart123",
             "checkoutUrl": "https://example.com/checkout",
             "lines": ["nodes": lineNodes],
             "cost": [
                 "totalAmount": ["amount": "100.00", "currencyCode": currencyCode],
                 "subtotalAmount": ["amount": "100.00", "currencyCode": currencyCode],
                 "totalTaxAmount": ["amount": "0.00", "currencyCode": currencyCode]
             ],
             "discountCodes": discountCodeNodes,
             "discountAllocations": cartDiscountAllocations,
             "totalQuantity": 1,
             "deliveryGroups": ["nodes": []],
             "buyerIdentity": ["email": "test@example.com"],
             "delivery": createDeliveryInfo()
         ]

         return try Storefront.Cart(fields: cartFields)
     }

     private func createProductVariant() -> [String: Any] {
         return [
             "__typename": "ProductVariant",
             "id": "variant123",
             "title": "Test Product",
             "price": ["amount": "100.00", "currencyCode": "USD"],
             "product": [
                 "title": "Test Product",
                 "vendor": "Test Vendor",
                 "featuredImage": ["url": "https://example.com/image.jpg"]
             ]
         ]
     }

     private func createCartCodeDiscountAllocation(
         code: String,
         amount: Double,
         currencyCode: String
     ) -> [String: Any] {
         return [
             "__typename": "CartCodeDiscountAllocation",
             "code": code,
             "discountedAmount": [
                 "amount": "\(amount)",
                 "currencyCode": currencyCode
             ],
             "targetType": "LINE_ITEM",
             "discountApplication": [
                 "allocationMethod": "ACROSS",
                 "targetSelection": "ALL",
                 "targetType": "LINE_ITEM",
                 "value": [
                     "__typename": "MoneyV2",
                     "amount": "\(amount)",
                     "currencyCode": currencyCode
                 ]
             ]
         ]
     }

     private func createCartAutomaticDiscountAllocation(
         title: String,
         amount: Double,
         currencyCode: String
     ) -> [String: Any] {
         return [
             "__typename": "CartAutomaticDiscountAllocation",
             "title": title,
             "discountedAmount": [
                 "amount": "\(amount)",
                 "currencyCode": currencyCode
             ],
             "targetType": "LINE_ITEM",
             "discountApplication": [
                 "allocationMethod": "ACROSS",
                 "targetSelection": "ALL",
                 "targetType": "LINE_ITEM",
                 "value": [
                     "__typename": "MoneyV2",
                     "amount": "\(amount)",
                     "currencyCode": currencyCode
                 ]
             ]
         ]
     }

     private func createDeliveryInfo() -> [String: Any] {
         return [
             "addresses": [
                 [
                     "selected": true,
                     "address": [
                         "__typename": "CartDeliveryAddress",
                         "address1": "123 Test St",
                         "city": "Test City",
                         "countryCode": "US",
                         "firstName": "Test",
                         "lastName": "User",
                         "zip": "12345"
                     ]
                 ]
             ]
         ]
     }

     private func createCost() -> [String: Any] {
         return [
             "totalAmount": ["amount": "100.00", "currencyCode": "USD"],
             "subtotalAmount": ["amount": "100.00", "currencyCode": "USD"],
             "totalTaxAmount": ["amount": "0.00", "currencyCode": "USD"]
         ]
     }
 }
 */
