import Contacts
import PassKit
import XCTest

@testable import ShopifyAcceleratedCheckouts

class PKEncoderTests: XCTestCase {
    private var cart: () -> Api.Types.Cart? = { nil }


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
        return PKEncoder(configuration: ApplePayConfigurationWrapper.testConfiguration, cart: { self.cart() })
    }


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
}
