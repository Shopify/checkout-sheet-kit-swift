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

import Contacts
import PassKit
import XCTest

@testable import ShopifyAcceleratedCheckouts

@available(iOS 17.0, *)
class PKEncoderTests: XCTestCase {
    private var cart: () -> StorefrontAPI.Types.Cart? = { nil }

    // MARK: - Test Helpers

    private func createMockContact(
        givenName: String? = nil,
        familyName: String? = nil,
        emailAddress: String? = nil,
        phoneNumber: String? = nil,
        street: String = "",
        city: String? = nil,
        state: String? = nil,
        postalCode: String? = nil,
        country: String? = nil,
        isoCountryCode: String? = nil,
        subLocality: String? = nil
    ) -> PKContact {
        let contact = PKContact()

        if givenName != nil || familyName != nil {
            var name = PersonNameComponents()
            name.givenName = givenName
            name.familyName = familyName
            contact.name = name
        }

        contact.emailAddress = emailAddress

        if let phoneNumber {
            contact.phoneNumber = CNPhoneNumber(stringValue: phoneNumber)
        }

        let postalAddress = CNMutablePostalAddress()
        postalAddress.street = street
        postalAddress.city = city ?? ""
        postalAddress.state = state ?? ""
        postalAddress.postalCode = postalCode ?? ""
        postalAddress.country = country ?? ""
        postalAddress.isoCountryCode = isoCountryCode ?? ""
        postalAddress.subLocality = subLocality ?? ""

        contact.postalAddress = postalAddress

        return contact
    }

    private var encoder: PKEncoder {
        return PKEncoder(
            configuration: ApplePayConfigurationWrapper.testConfiguration, cart: { self.cart() }
        )
    }

    // MARK: - mapToCountryCode Tests

    func testMapToCountryCodeFromApplePay() {
        XCTAssertEqual(encoder.mapToCountryCode(code: "us"), "US")
    }

    func testMapToCountryCodeNilToDefault() {
        XCTAssertEqual(encoder.mapToCountryCode(code: nil), "ZZ")
    }

    func testMapToCountryCodeUKToGB() {
        XCTAssertEqual(encoder.mapToCountryCode(code: "UK"), "GB")
    }

    func testMapToCountryCodeJAToJP() {
        XCTAssertEqual(encoder.mapToCountryCode(code: "JA"), "JP")
    }

    // MARK: - Email and Phone Fallback Tests

    func test_email_withContactEmail_shouldReturnContactEmail() {
        // Create encoder without default customer to test contact email priority
        let configWithoutCustomer = ApplePayConfigurationWrapper.testConfiguration.copy()
        configWithoutCustomer.common.customer = nil

        let encoderWithoutCustomer = PKEncoder(configuration: configWithoutCustomer, cart: cart)

        encoderWithoutCustomer.shippingContact = .success(createMockContact(emailAddress: "contact@example.com"))

        guard let email = try? encoderWithoutCustomer.email.get() else {
            XCTFail("Expected email to be available")
            return
        }

        XCTAssertEqual(email, "contact@example.com")
    }

    func test_email_withoutContactEmailButWithCustomerEmail_shouldReturnCustomerEmail() {
        let configWithCustomer = ApplePayConfigurationWrapper.testConfiguration.copy()
        configWithCustomer.common.customer?.email = "customer@example.com"

        let encoderWithCustomer = PKEncoder(configuration: configWithCustomer, cart: cart)

        guard let email = try? encoderWithCustomer.email.get() else {
            XCTFail("Expected email to be available")
            return
        }

        XCTAssertEqual(email, "customer@example.com")
    }

    func test_email_withEmptyContactEmail_shouldFallbackToCustomerEmail() {
        let configWithCustomer = ApplePayConfigurationWrapper.testConfiguration.copy()
        configWithCustomer.common.customer?.email = "customer@example.com"

        let encoderWithCustomer = PKEncoder(configuration: configWithCustomer, cart: cart)

        encoderWithCustomer.shippingContact = .success(createMockContact(emailAddress: ""))

        guard let email = try? encoderWithCustomer.email.get() else {
            XCTFail("Expected email to be available")
            return
        }

        XCTAssertEqual(email, "customer@example.com")
    }

    func test_email_withoutContactOrCustomerEmail_shouldReturnFailure() {
        // Create encoder without default customer to test failure case
        let configWithoutCustomer = ApplePayConfigurationWrapper.testConfiguration.copy()
        configWithoutCustomer.common.customer = nil

        let encoderWithoutCustomer = PKEncoder(configuration: configWithoutCustomer, cart: cart)

        encoderWithoutCustomer.shippingContact = .success(createMockContact())

        switch encoderWithoutCustomer.email {
        case .success:
            XCTFail("Expected email to fail when no email is available")
        case let .failure(error):
            guard case let .invariant(expected) = error else {
                XCTFail("Expected invariant error but got: \(error)")
                return
            }
            XCTAssertEqual(expected, "email")
        }
    }

    func test_phoneNumber_withContactPhone_shouldReturnContactPhone() {
        // Create encoder without default customer to test contact phone priority
        let configWithoutCustomer = ApplePayConfigurationWrapper.testConfiguration.copy()
        configWithoutCustomer.common.customer = nil

        let encoderWithoutCustomer = PKEncoder(configuration: configWithoutCustomer, cart: cart)

        encoderWithoutCustomer.shippingContact = .success(createMockContact(phoneNumber: "+1234567890"))

        guard let phoneNumber = try? encoderWithoutCustomer.phoneNumber.get() else {
            XCTFail("Expected phoneNumber to be available")
            return
        }

        XCTAssertEqual(phoneNumber, "+1234567890")
    }

    func test_phoneNumber_withoutContactPhoneButWithCustomerPhone_shouldReturnCustomerPhone() {
        let configWithCustomer = ApplePayConfigurationWrapper.testConfiguration.copy()
        configWithCustomer.common.customer?.email = nil
        configWithCustomer.common.customer?.phoneNumber = "+0987654321"

        let encoderWithCustomer = PKEncoder(configuration: configWithCustomer, cart: cart)

        guard let phoneNumber = try? encoderWithCustomer.phoneNumber.get() else {
            XCTFail("Expected phoneNumber to be available")
            return
        }

        XCTAssertEqual(phoneNumber, "+0987654321")
    }

    func test_phoneNumber_withEmptyContactPhone_shouldFallbackToCustomerPhone() {
        let configWithCustomer = ApplePayConfigurationWrapper.testConfiguration.copy()
        configWithCustomer.common.customer?.email = nil
        configWithCustomer.common.customer?.phoneNumber = "+0987654321"

        let encoderWithCustomer = PKEncoder(configuration: configWithCustomer, cart: cart)

        encoderWithCustomer.shippingContact = .success(createMockContact(phoneNumber: ""))

        guard let phoneNumber = try? encoderWithCustomer.phoneNumber.get() else {
            XCTFail("Expected phoneNumber to be available")
            return
        }

        XCTAssertEqual(phoneNumber, "+0987654321")
    }

    func test_phoneNumber_withoutContactOrCustomerPhone_shouldReturnFailure() {
        // Create encoder without default customer to test failure case
        let configWithoutCustomer = ApplePayConfigurationWrapper.testConfiguration.copy()
        configWithoutCustomer.common.customer = nil

        let encoderWithoutCustomer = PKEncoder(configuration: configWithoutCustomer, cart: cart)

        encoderWithoutCustomer.shippingContact = .success(createMockContact())

        switch encoderWithoutCustomer.phoneNumber {
        case .success:
            XCTFail("Expected phoneNumber to fail when no phone is available")
        case let .failure(error):
            guard case let .invariant(expected) = error else {
                XCTFail("Expected invariant error but got: \(error)")
                return
            }
            XCTAssertEqual(expected, "phoneNumber")
        }
    }

    func test_email_withContactEmailPriority_shouldPreferContactOverCustomer() {
        let configWithCustomer = ApplePayConfigurationWrapper.testConfiguration.copy()
        configWithCustomer.common.customer?.email = "customer@example.com"
        configWithCustomer.common.customer?.phoneNumber = nil

        let encoderWithCustomer = PKEncoder(configuration: configWithCustomer, cart: cart)

        let contact = createMockContact(emailAddress: "contact@example.com")
        encoderWithCustomer.shippingContact = .success(contact)

        guard let email = try? encoderWithCustomer.email.get() else {
            XCTFail("Expected email to be available")
            return
        }

        XCTAssertEqual(
            email, "contact@example.com", "Should prefer contact email over customer email"
        )
    }

    func test_phoneNumber_withContactPhonePriority_shouldPreferContactOverCustomer() {
        let configWithCustomer = ApplePayConfigurationWrapper.testConfiguration.copy()
        configWithCustomer.common.customer?.email = nil
        configWithCustomer.common.customer?.phoneNumber = "+0987654321"

        let encoderWithCustomer = PKEncoder(configuration: configWithCustomer, cart: cart)

        let contact = createMockContact(phoneNumber: "+1234567890")
        encoderWithCustomer.shippingContact = .success(contact)

        guard let phoneNumber = try? encoderWithCustomer.phoneNumber.get() else {
            XCTFail("Expected phoneNumber to be available")
            return
        }

        XCTAssertEqual(
            phoneNumber, "+1234567890", "Should prefer contact phone over customer phone"
        )
    }

    func testMapToCountryCodeUSTerritory() {
        let territoryCodes = ["AS", "GU", "MP", "PR", "VI"]
        for territoryCode in territoryCodes {
            XCTAssertEqual(encoder.mapToCountryCode(code: territoryCode), "US")
        }
    }

    func testMapToCountryCodeEmptyToDefault() {
        XCTAssertEqual(encoder.mapToCountryCode(code: ""), "ZZ")
    }

    func testMapToCountryCodeUnknownUnchanged() {
        let unknownCode = "XY"

        // Verify this code doesn't exist in either dictionary to ensure we're testing unknown case
        XCTAssertNil(encoder.getValue(code: unknownCode))

        XCTAssertEqual(encoder.mapToCountryCode(code: unknownCode), unknownCode)
    }

    func testMapToCountryCodeLowercaseToUppercase() {
        let unknownCode = "ca"
        XCTAssertNil(encoder.getValue(code: unknownCode))
        XCTAssertEqual(encoder.mapToCountryCode(code: unknownCode), "CA")
    }

    // MARK: - Address Mapping Tests

    func testDoesNotPadIncompletePostalCodes() throws {
        let contact = createMockContact(
            street: "33 New Montgomery St\n750",
            city: "San Francisco",
            state: "CA",
            postalCode: "A1A",
            country: "Canada",
            isoCountryCode: "CA"
        )

        let result = encoder.pkContactToAddress(contact: contact)

        let address = try result.get()

        XCTAssertEqual(address.zip, "A1A")
    }

    func testHongKongAddressHandling() throws {
        let contact = createMockContact(
            city: "Central",
            postalCode: "Hong Kong",
            country: "Hong Kong",
            isoCountryCode: "HK"
        )

        let result = encoder.pkContactToAddress(contact: contact)

        let address = try result.get()
        XCTAssertEqual(address.city, "Central")
        XCTAssertEqual(address.province, "Hong Kong")
        XCTAssertEqual(address.country, "HK")
        XCTAssertNil(address.zip)
    }

    func testFallbackToSubLocalityForProvince() throws {
        let contact = createMockContact(
            city: "Murbah",
            country: "United Arab Emirates",
            isoCountryCode: "AE",
            subLocality: "Fujairah"
        )

        let result = encoder.pkContactToAddress(contact: contact)

        let address = try result.get()
        XCTAssertEqual(address.city, "Murbah")
        XCTAssertEqual(address.province, "Fujairah")
        XCTAssertEqual(address.country, "AE")
    }

    func testUSTerritoriesMapping() throws {
        let territoryCodes = ["AS", "GU", "MP", "PR", "VI"]
        for territoryCode in territoryCodes {
            let contact = createMockContact(
                postalCode: "00000",
                country: territoryCode,
                isoCountryCode: territoryCode
            )

            let result = encoder.pkContactToAddress(contact: contact)

            let address = try result.get()

            XCTAssertEqual(address.province, territoryCode)
            XCTAssertEqual(address.country, "US")
        }
    }

    func testMapsPartialContactToAddress() throws {
        let contact = createMockContact(
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "United States",
            isoCountryCode: "US"
        )

        let result = encoder.pkContactToAddress(contact: contact)

        let address = try result.get()

        XCTAssertNil(address.firstName)
        XCTAssertNil(address.lastName)
        XCTAssertNil(address.address1)
        XCTAssertNil(address.address2)
        XCTAssertEqual(address.city, "San Francisco")
        XCTAssertEqual(address.zip, "94105")
        XCTAssertEqual(address.province, "CA")
        XCTAssertEqual(address.country, "US")
        XCTAssertNil(address.phone)
    }

    func testMapsFullContactToAddress() throws {
        let contact = createMockContact(
            givenName: "Rick",
            familyName: "Sanchez",
            emailAddress: "test@shopify.com",
            phoneNumber: "7781234567",
            street: "33 New Montgomery St\n750",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "United States",
            isoCountryCode: "US"
        )

        let result = encoder.pkContactToAddress(contact: contact)

        let address = try result.get()

        XCTAssertEqual(address.firstName, "Rick")
        XCTAssertEqual(address.lastName, "Sanchez")
        XCTAssertEqual(address.address1, "33 New Montgomery St")
        XCTAssertEqual(address.address2, "750")
        XCTAssertEqual(address.city, "San Francisco")
        XCTAssertEqual(address.zip, "94105")
        XCTAssertEqual(address.province, "CA")
        XCTAssertEqual(address.country, "US")
        XCTAssertEqual(address.phone, "7781234567")
    }

    func testUsesGivenNameAsLastNameWhenFamilyNameMissing() throws {
        let contact = createMockContact(
            givenName: "bob",
            familyName: ""
        )

        let result = encoder.pkContactToAddress(contact: contact)

        let address = try result.get()

        XCTAssertEqual(address.firstName, "bob")
        XCTAssertEqual(address.lastName, "bob")
        XCTAssertNil(address.address1)
        XCTAssertNil(address.address2)
        XCTAssertEqual(address.city, "")
        XCTAssertEqual(address.zip, "")
        XCTAssertNil(address.province)
        XCTAssertEqual(address.country, "ZZ")
        XCTAssertNil(address.phone)
    }

    func testReturnsErrorForNilContact() {
        let result = encoder.pkContactToAddress(contact: nil)

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        XCTAssertTrue(error.toString().contains("postalAddress"))
    }

    func testReturnsErrorForContactWithoutPostalAddress() {
        let contact = PKContact()
        // contact.postalAddress is nil by default

        let result = encoder.pkContactToAddress(contact: contact)

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        XCTAssertTrue(error.toString().contains("postalAddress"))
    }

    func testHandlesMultipleAddressLines() throws {
        let contact = createMockContact(
            street: "Line 1\nLine 2\nLine 3",
            city: "Test City",
            isoCountryCode: "US"
        )

        let result = encoder.pkContactToAddress(contact: contact)
        let address = try result.get()

        XCTAssertEqual(address.address1, "Line 1")
        XCTAssertEqual(address.address2, "Line 2")
        // Third line and beyond are ignored
    }

    func testHandlesSingleAddressLine() throws {
        let contact = createMockContact(
            street: "Single Line",
            city: "Test City",
            isoCountryCode: "US"
        )

        let result = encoder.pkContactToAddress(contact: contact)
        let address = try result.get()

        XCTAssertEqual(address.address1, "Single Line")
        XCTAssertNil(address.address2)
    }

    func testHandlesEmptyAddressLines() throws {
        let contact = createMockContact(
            street: "",
            city: "Test City",
            isoCountryCode: "US"
        )

        let result = encoder.pkContactToAddress(contact: contact)
        let address = try result.get()

        XCTAssertNil(address.address1)
        XCTAssertNil(address.address2)
    }

    func testFallsBackToSubLocalityWhenStateEmpty() throws {
        let contact = createMockContact(
            city: "Test City",
            state: "",
            isoCountryCode: "AE",
            subLocality: "Test Sublocality"
        )

        let result = encoder.pkContactToAddress(contact: contact)
        let address = try result.get()

        XCTAssertEqual(address.province, "Test Sublocality")
    }

    func testPrefersStateOverSubLocality() throws {
        let contact = createMockContact(
            city: "Test City",
            state: "Test State",
            isoCountryCode: "US",
            subLocality: "Test Sublocality"
        )

        let result = encoder.pkContactToAddress(contact: contact)
        let address = try result.get()

        XCTAssertEqual(address.province, "Test State")
    }

    func testHandlesUSTerritoriesInCountryField() throws {
        let contact = createMockContact(
            city: "San Juan",
            postalCode: "00900",
            country: "PR",
            isoCountryCode: "PR"
        )

        let result = encoder.pkContactToAddress(contact: contact)
        let address = try result.get()

        XCTAssertEqual(address.country, "US")
        XCTAssertEqual(address.province, "PR")
    }

    func testHandlesNamesWithBothNil() throws {
        let contact = createMockContact(
            givenName: nil,
            familyName: nil,
            city: "Test City",
            isoCountryCode: "US"
        )

        let result = encoder.pkContactToAddress(contact: contact)
        let address = try result.get()

        XCTAssertNil(address.firstName)
        XCTAssertNil(address.lastName)
    }

    func testHandlesEmptyFamilyName() throws {
        let contact = createMockContact(
            givenName: "John",
            familyName: "",
            city: "Test City",
            isoCountryCode: "US"
        )

        let result = encoder.pkContactToAddress(contact: contact)
        let address = try result.get()

        XCTAssertEqual(address.firstName, "John")
        XCTAssertEqual(address.lastName, "John")
    }

    // MARK: - billingPostalAddress Tests

    //
    // Testing Strategy for billingPostalAddress:
    // - Tests comprehensive error handling for all failure paths
    // - Tests success flow via billingContact (using setValue workaround)
    // - Cannot easily test selectedPaymentMethod fallback due to PassKit read-only properties
    // - Core address conversion logic is thoroughly tested via existing pkContactToAddress tests

    func testBillingPostalAddressReturnsErrorWhenNoBillingContactOrPaymentMethod() {
        let testEncoder = encoder

        let result = testEncoder.billingPostalAddress

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        XCTAssertTrue(error.toString().contains("selectedPaymentMethod"))
    }

    func testBillingPostalAddressReturnsErrorWhenPaymentIsNil() {
        let testEncoder = encoder
        testEncoder.payment = nil
        testEncoder.selectedPaymentMethod = nil

        let result = testEncoder.billingPostalAddress

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        XCTAssertTrue(error.toString().contains("selectedPaymentMethod"))
    }

    func testBillingPostalAddressReturnsErrorWhenPaymentHasNoBillingContact() {
        let testEncoder = encoder
        let payment = PKPayment()
        testEncoder.payment = payment
        testEncoder.selectedPaymentMethod = nil

        let result = testEncoder.billingPostalAddress

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        XCTAssertTrue(error.toString().contains("selectedPaymentMethod"))
    }

    func testBillingPostalAddressReturnsErrorWhenSelectedPaymentMethodIsNil() {
        let testEncoder = encoder
        testEncoder.payment = nil
        testEncoder.selectedPaymentMethod = nil

        let result = testEncoder.billingPostalAddress

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        XCTAssertTrue(error.toString().contains("selectedPaymentMethod"))
    }

    func testBillingPostalAddressHandlesComplexNestedNilCases() {
        let testEncoder = encoder

        let mockPaymentMethod = PKPaymentMethod()
        testEncoder.selectedPaymentMethod = mockPaymentMethod

        let result = testEncoder.billingPostalAddress

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        XCTAssertTrue(error.toString().contains("selectedPaymentMethod"))
    }

    func testBillingPostalAddressSuccessViaBillingContact() throws {
        let testEncoder = encoder

        let billingContact = createMockContact(
            street: "789 Billing Street\nUnit 456",
            city: "Billing City",
            state: "NY",
            postalCode: "10001",
            country: "United States",
            isoCountryCode: "US"
        )

        let payment = PKPayment()
        // Note: PKPayment.billingContact is read-only, so we use setValue(forKey:) to set it for testing.
        // This is a workaround since PassKit objects can only be properly populated by the actual
        // Apple Pay system during real payment flows.
        payment.setValue(billingContact, forKey: "billingContact")
        testEncoder.payment = payment

        let result = testEncoder.billingPostalAddress
        let address = try result.get()

        // Testing limitation: PKPayment doesn't preserve all contact properties when set via setValue.
        // Name properties (firstName, lastName) are lost during the PKPayment round-trip, but postal
        // address properties (street, city, state, zip, country) are correctly preserved.
        XCTAssertEqual(address.address1, "789 Billing Street")
        XCTAssertEqual(address.address2, "Unit 456")
        XCTAssertEqual(address.city, "Billing City")
        XCTAssertEqual(address.province, "NY")
        XCTAssertEqual(address.zip, "10001")
        XCTAssertEqual(address.country, "US")
    }

    // MARK: - cartID Tests

    func test_cartID_withValidCart_shouldReturnCartID() throws {
        let mockCart = StorefrontAPI.Cart.testCart
        let testEncoder = PKEncoder(configuration: ApplePayConfigurationWrapper.testConfiguration, cart: { mockCart })

        let result = testEncoder.cartID
        let cartID = try result.get()

        XCTAssertEqual(cartID, mockCart.id)
    }

    func test_cartID_withNilCart_shouldReturnFailure() {
        let testEncoder = PKEncoder(configuration: ApplePayConfigurationWrapper.testConfiguration, cart: { nil })

        let result = testEncoder.cartID

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        guard case let .invariant(expected) = error else {
            XCTFail("Expected invariant error but got: \(error)")
            return
        }
        XCTAssertEqual(expected, "cart")
    }

    // MARK: - selectedDeliveryOptionHandle Tests

    func test_selectedDeliveryOptionHandle_withValidShippingMethod_shouldReturnHandle() throws {
        let testEncoder = encoder
        let shippingMethod = PKShippingMethod()
        shippingMethod.setValue("test-delivery-option-123", forKey: "identifier")
        testEncoder.selectedShippingMethod = shippingMethod

        let result = testEncoder.selectedDeliveryOptionHandle
        let handle = try result.get()

        XCTAssertEqual(handle.rawValue, "test-delivery-option-123")
    }

    func test_selectedDeliveryOptionHandle_withNilShippingMethod_shouldReturnFailure() {
        let testEncoder = encoder
        testEncoder.selectedShippingMethod = nil

        let result = testEncoder.selectedDeliveryOptionHandle

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        guard case let .invariant(expected) = error else {
            XCTFail("Expected invariant error but got: \(error)")
            return
        }
        XCTAssertEqual(expected, "shippingMethod")
    }

    func test_selectedDeliveryOptionHandle_withNilIdentifier_shouldReturnFailure() {
        let testEncoder = encoder
        let shippingMethod = PKShippingMethod()
        testEncoder.selectedShippingMethod = shippingMethod

        let result = testEncoder.selectedDeliveryOptionHandle

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        guard case let .invariant(expected) = error else {
            XCTFail("Expected invariant error but got: \(error)")
            return
        }
        XCTAssertEqual(expected, "shippingMethodID")
    }

    // MARK: - deliveryGroupID Tests

    func test_deliveryGroupID_withNilCart_shouldReturnFailure() {
        let testEncoder = PKEncoder(configuration: ApplePayConfigurationWrapper.testConfiguration, cart: { nil })
        let shippingMethod = PKShippingMethod()
        shippingMethod.setValue("test-delivery-option-123", forKey: "identifier")
        testEncoder.selectedShippingMethod = shippingMethod

        let result = testEncoder.deliveryGroupID

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        guard case let .invariant(expected) = error else {
            XCTFail("Expected invariant error but got: \(error)")
            return
        }
        XCTAssertEqual(expected, "cart")
    }

    func test_deliveryGroupID_withNilSelectedShippingMethod_shouldReturnFailure() {
        let mockCart = StorefrontAPI.Cart.testCart
        let testEncoder = PKEncoder(configuration: ApplePayConfigurationWrapper.testConfiguration, cart: { mockCart })
        testEncoder.selectedShippingMethod = nil

        let result = testEncoder.deliveryGroupID

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        guard case let .invariant(expected) = error else {
            XCTFail("Expected invariant error but got: \(error)")
            return
        }
        XCTAssertEqual(expected, "selectedShippingMethodId")
    }

    func test_deliveryGroupID_withInvalidDeliveryOptionHandle_shouldReturnFailure() {
        let mockCart = StorefrontAPI.Cart.testCart
        let testEncoder = PKEncoder(configuration: ApplePayConfigurationWrapper.testConfiguration, cart: { mockCart })
        let shippingMethod = PKShippingMethod()
        shippingMethod.setValue("invalid-delivery-option", forKey: "identifier")
        testEncoder.selectedShippingMethod = shippingMethod

        let result = testEncoder.deliveryGroupID

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        guard case let .invariant(expected) = error else {
            XCTFail("Expected invariant error but got: \(error)")
            return
        }
        XCTAssertEqual(expected, "deliveryGroupID")
    }

    func test_deliveryGroupID_withValidData_shouldReturnGroupID() throws {
        let mockCart = StorefrontAPI.Cart.testCart
        let testEncoder = PKEncoder(configuration: ApplePayConfigurationWrapper.testConfiguration, cart: { mockCart })
        let shippingMethod = PKShippingMethod()
        shippingMethod.setValue("standard-shipping", forKey: "identifier")
        testEncoder.selectedShippingMethod = shippingMethod

        let result = testEncoder.deliveryGroupID
        let groupID = try result.get()

        XCTAssertEqual(groupID.rawValue, "gid://shopify/CartDeliveryGroup/1")
    }

    // MARK: - billingContact Tests

    func test_billingContact_withValidPayment_shouldReturnContact() throws {
        let testEncoder = encoder
        let payment = PKPayment()
        let billingContact = createMockContact(emailAddress: "billing@test.com")
        payment.setValue(billingContact, forKey: "billingContact")
        testEncoder.payment = payment

        let result = testEncoder.billingContact
        let contact = try result.get()

        XCTAssertEqual(contact.emailAddress, "billing@test.com")
    }

    func test_billingContact_withNilPayment_shouldReturnFailure() {
        let testEncoder = encoder
        testEncoder.payment = nil

        let result = testEncoder.billingContact

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        guard case let .invariant(expected) = error else {
            XCTFail("Expected invariant error but got: \(error)")
            return
        }
        XCTAssertEqual(expected, "payment")
    }

    // MARK: - shippingContact Tests

    func test_shippingContact_withPaymentShippingContact_shouldReturnPaymentContact() throws {
        let testEncoder = encoder
        let payment = PKPayment()
        let shippingContact = createMockContact(emailAddress: "shipping@test.com")
        payment.setValue(shippingContact, forKey: "shippingContact")
        testEncoder.payment = payment

        let result = testEncoder.shippingContact
        let contact = try result.get()

        XCTAssertEqual(contact.emailAddress, "shipping@test.com")
    }

    func test_shippingContact_withSelectedShippingContact_shouldReturnSelectedContact() throws {
        let testEncoder = encoder
        testEncoder.payment = nil
        let selectedContact = createMockContact(emailAddress: "selected@test.com")
        testEncoder.shippingContact = .success(selectedContact)

        let result = testEncoder.shippingContact
        let contact = try result.get()

        XCTAssertEqual(contact.emailAddress, "selected@test.com")
    }

    func test_shippingContact_withNilPaymentAndFailedSelectedContact_shouldReturnFailure() {
        let testEncoder = encoder
        testEncoder.payment = nil
        testEncoder.shippingContact = .failure(.invariant(expected: "test"))

        let result = testEncoder.shippingContact

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        guard case let .invariant(expected) = error else {
            XCTFail("Expected invariant error but got: \(error)")
            return
        }
        XCTAssertEqual(expected, "payment")
    }

    func test_shippingContact_setter_shouldUpdateSelectedShippingContact() throws {
        let testEncoder = encoder
        let contact = createMockContact(emailAddress: "setter@test.com")

        testEncoder.shippingContact = .success(contact)

        let result = testEncoder.shippingContact
        let retrievedContact = try result.get()

        XCTAssertEqual(retrievedContact.emailAddress, "setter@test.com")
    }

    // MARK: - lastDigits Tests

    func test_lastDigits_withValidPayment_shouldReturnLastDigits() throws {
        let testEncoder = encoder
        let payment = PKPayment()
        let token = PKPaymentToken()
        let paymentMethod = PKPaymentMethod()
        paymentMethod.setValue("•••• 1234", forKey: "displayName")
        token.setValue(paymentMethod, forKey: "paymentMethod")
        payment.setValue(token, forKey: "token")
        testEncoder.payment = payment

        let result = testEncoder.lastDigits
        let digits = try result.get()

        XCTAssertEqual(digits, "1234")
    }

    func test_lastDigits_withNilPayment_shouldReturnFailure() {
        let testEncoder = encoder
        testEncoder.payment = nil

        let result = testEncoder.lastDigits

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        guard case let .invariant(expected) = error else {
            XCTFail("Expected invariant error but got: \(error)")
            return
        }
        XCTAssertEqual(expected, "payment")
    }

    func test_lastDigits_withNilDisplayName_shouldReturnFailure() {
        let testEncoder = encoder
        let payment = PKPayment()
        let token = PKPaymentToken()
        let paymentMethod = PKPaymentMethod()
        token.setValue(paymentMethod, forKey: "paymentMethod")
        payment.setValue(token, forKey: "token")
        testEncoder.payment = payment

        let result = testEncoder.lastDigits

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        guard case let .invariant(expected) = error else {
            XCTFail("Expected invariant error but got: \(error)")
            return
        }
        XCTAssertEqual(expected, "displayName")
    }

    // MARK: - billingAddress Tests

    func test_billingAddress_withValidBillingContact_shouldReturnAddress() throws {
        let testEncoder = encoder
        let payment = PKPayment()
        let billingContact = createMockContact(
            street: "123 Billing St",
            city: "Billing City",
            state: "CA",
            postalCode: "90210",
            isoCountryCode: "US"
        )
        payment.setValue(billingContact, forKey: "billingContact")
        testEncoder.payment = payment

        let result = testEncoder.billingAddress
        let address = try result.get()

        XCTAssertEqual(address.address1, "123 Billing St")
        XCTAssertEqual(address.city, "Billing City")
        XCTAssertEqual(address.province, "CA")
        XCTAssertEqual(address.zip, "90210")
        XCTAssertEqual(address.country, "US")
    }

    func test_billingAddress_withFailedBillingContact_shouldReturnFailure() {
        let testEncoder = encoder
        testEncoder.payment = nil

        let result = testEncoder.billingAddress

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        guard case let .invariant(expected) = error else {
            XCTFail("Expected invariant error but got: \(error)")
            return
        }
        XCTAssertEqual(expected, "billingContact")
    }

    // MARK: - shippingAddress Tests

    func test_shippingAddress_withValidShippingContact_shouldReturnAddress() throws {
        let testEncoder = encoder
        let payment = PKPayment()
        let shippingContact = createMockContact(
            street: "456 Shipping Ave",
            city: "Shipping Town",
            state: "NY",
            postalCode: "10001",
            isoCountryCode: "US"
        )
        payment.setValue(shippingContact, forKey: "shippingContact")
        testEncoder.payment = payment

        let result = testEncoder.shippingAddress
        let address = try result.get()

        XCTAssertEqual(address.address1, "456 Shipping Ave")
        XCTAssertEqual(address.city, "Shipping Town")
        XCTAssertEqual(address.province, "NY")
        XCTAssertEqual(address.zip, "10001")
        XCTAssertEqual(address.country, "US")
    }

    func test_shippingAddress_withFailedShippingContact_shouldReturnFailure() {
        let testEncoder = encoder
        testEncoder.payment = nil

        let result = testEncoder.shippingAddress

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        guard case let .invariant(expected) = error else {
            XCTFail("Expected invariant error but got: \(error)")
            return
        }
        XCTAssertEqual(expected, "shippingContact")
    }

    // MARK: - totalAmount Tests

    func test_totalAmount_withValidCart_shouldReturnAmount() throws {
        let mockCart = StorefrontAPI.Cart.testCart
        let testEncoder = PKEncoder(configuration: ApplePayConfigurationWrapper.testConfiguration, cart: { mockCart })

        let result = testEncoder.totalAmount
        let amount = try result.get()

        XCTAssertEqual(amount.amount, mockCart.cost.totalAmount.amount)
        XCTAssertEqual(amount.currencyCode, mockCart.cost.totalAmount.currencyCode)
    }

    func test_totalAmount_withNilCart_shouldReturnFailure() {
        let testEncoder = PKEncoder(configuration: ApplePayConfigurationWrapper.testConfiguration, cart: { nil })

        let result = testEncoder.totalAmount

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        guard case let .invariant(expected) = error else {
            XCTFail("Expected invariant error but got: \(error)")
            return
        }
        XCTAssertEqual(expected, "cart")
    }

    // MARK: - applePayPayment Tests

    func test_applePayPayment_withNilPayment_shouldReturnFailure() {
        let testEncoder = encoder
        testEncoder.payment = nil

        let result = testEncoder.applePayPayment

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        guard case let .invariant(expected) = error else {
            XCTFail("Expected invariant error but got: \(error)")
            return
        }
        XCTAssertEqual(expected, "payment")
    }

    func test_applePayPayment_withInvalidPaymentData_shouldReturnFailure() {
        let testEncoder = encoder
        let payment = PKPayment()
        let token = PKPaymentToken()
        // Set invalid payment data that will fail JSON decoding
        token.setValue(Data(), forKey: "paymentData")
        payment.setValue(token, forKey: "token")
        testEncoder.payment = payment

        let result = testEncoder.applePayPayment

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        guard case let .invariant(expected) = error else {
            XCTFail("Expected invariant error but got: \(error)")
            return
        }
        XCTAssertEqual(expected, "paymentData")
    }

    func test_applePayPayment_withFailedBillingAddress_shouldReturnFailure() {
        let testEncoder = encoder
        // Set up payment without billing contact to make billingAddress fail
        testEncoder.payment = nil

        let result = testEncoder.applePayPayment

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        guard case let .invariant(expected) = error else {
            XCTFail("Expected invariant error but got: \(error)")
            return
        }
        XCTAssertEqual(expected, "payment")
    }

    func test_applePayPayment_withFailedLastDigits_shouldReturnFailure() {
        let testEncoder = encoder
        let payment = PKPayment()
        let token = PKPaymentToken()
        let paymentMethod = PKPaymentMethod()
        // Set displayName to nil to make lastDigits fail
        paymentMethod.setValue(nil, forKey: "displayName")
        token.setValue(paymentMethod, forKey: "paymentMethod")
        payment.setValue(token, forKey: "token")

        // Set up billing contact to pass billingAddress check
        let billingContact = createMockContact(
            street: "123 Test St",
            city: "Test City",
            state: "CA",
            postalCode: "90210",
            isoCountryCode: "US"
        )
        payment.setValue(billingContact, forKey: "billingContact")

        // Create valid JSON payment data to pass paymentData check
        let validPaymentData = """
        {
            "header": {
                "ephemeralPublicKey": "test-key",
                "publicKeyHash": "test-hash",
                "transactionId": "test-transaction"
            },
            "data": "test-data",
            "signature": "test-signature",
            "version": "EC_v1"
        }
        """.data(using: .utf8)!
        token.setValue(validPaymentData, forKey: "paymentData")

        testEncoder.payment = payment

        let result = testEncoder.applePayPayment

        guard case let .failure(error) = result else {
            XCTFail("Expected failure but got success")
            return
        }
        guard case let .invariant(expected) = error else {
            XCTFail("Expected invariant error but got: \(error)")
            return
        }
        XCTAssertEqual(expected, "lastDigits")
    }

    func test_applePayPayment_withValidData_shouldReturnApplePayPayment() throws {
        let testEncoder = encoder
        let payment = PKPayment()
        let token = PKPaymentToken()
        let paymentMethod = PKPaymentMethod()

        // Set up valid payment method with displayName for lastDigits
        paymentMethod.setValue("•••• 1234", forKey: "displayName")
        token.setValue(paymentMethod, forKey: "paymentMethod")
        payment.setValue(token, forKey: "token")

        // Set up billing contact for billingAddress
        let billingContact = createMockContact(
            givenName: "John",
            familyName: "Doe",
            street: "123 Apple Street",
            city: "Cupertino",
            state: "CA",
            postalCode: "95014",
            isoCountryCode: "US"
        )
        payment.setValue(billingContact, forKey: "billingContact")

        // Create valid JSON payment data
        let validPaymentData = """
        {
            "header": {
                "ephemeralPublicKey": "BFz948MTG3OQ0Q7PyL1SvZzFZ7jd8+yV1CJ5cXEk8mbfw7XxuTHyGvYM2e1cMqo45Z+1wBTTgc8aNYj5Qhg2SWY=",
                "publicKeyHash": "Xzgh8wOJfBa2YHKhOGjdl3hdvvdyq2/Pq1IHTCzF6Mc=",
                "transactionId": "31323334353637"
            },
            "data": "nZqvl0G6G3M7YY7WEKKGZmMXDyOFKiw45b2MgYg6W0TM",
            "signature": "MIAGCSqGSIb3DQEHAqCAMIACAQExDzANBglghkgBZQMEAgEFADCABgkqhkiG9w0BBwGggCSABIIC7TCCAukwggJkAgEAMIIB8TCCAR0CAQAwXDBNMQ==",
            "version": "EC_v1"
        }
        """.data(using: .utf8)!
        token.setValue(validPaymentData, forKey: "paymentData")

        testEncoder.payment = payment

        let result = testEncoder.applePayPayment
        let applePayPayment = try result.get()

        // Verify the returned ApplePayPayment object
        XCTAssertEqual(applePayPayment.billingAddress.firstName, "John")
        XCTAssertEqual(applePayPayment.billingAddress.lastName, "Doe")
        XCTAssertEqual(applePayPayment.billingAddress.address1, "123 Apple Street")
        XCTAssertEqual(applePayPayment.billingAddress.city, "Cupertino")
        XCTAssertEqual(applePayPayment.billingAddress.province, "CA")
        XCTAssertEqual(applePayPayment.billingAddress.zip, "95014")
        XCTAssertEqual(applePayPayment.billingAddress.country, "US")

        XCTAssertEqual(applePayPayment.ephemeralPublicKey, "BFz948MTG3OQ0Q7PyL1SvZzFZ7jd8+yV1CJ5cXEk8mbfw7XxuTHyGvYM2e1cMqo45Z+1wBTTgc8aNYj5Qhg2SWY=")
        XCTAssertEqual(applePayPayment.publicKeyHash, "Xzgh8wOJfBa2YHKhOGjdl3hdvvdyq2/Pq1IHTCzF6Mc=")
        XCTAssertEqual(applePayPayment.transactionId, "31323334353637")
        XCTAssertEqual(applePayPayment.data, "nZqvl0G6G3M7YY7WEKKGZmMXDyOFKiw45b2MgYg6W0TM")
        XCTAssertTrue(applePayPayment.signature.hasPrefix("MIAGCSqGSIb3DQEHAqCAMIACAQExDzANBglghkgBZQMEAgEFADCABgkqhkiG9w0BBwGggCSABIIC7TCCAukwggJkAgEAMIIB8TCCAR0CAQAwXDBNMQ=="))
        XCTAssertEqual(applePayPayment.version, "EC_v1")
        XCTAssertEqual(applePayPayment.lastDigits, "1234")
    }
}
