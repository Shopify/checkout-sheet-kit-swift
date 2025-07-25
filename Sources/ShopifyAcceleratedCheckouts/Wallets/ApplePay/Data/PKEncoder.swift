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

import PassKit

/// Encodes PassKit -> Storefront
@available(iOS 17.0, *)
class PKEncoder {
    var cart: () -> StorefrontAPI.Types.Cart?
    /// Set during `didSelectShippingMethod`
    var selectedShippingMethod: PKShippingMethod?
    /// Set during `didSelectPaymentMethod`
    /// billingAddress is only set for the default card
    /// If user changes card the billingContact is nil'd out
    var selectedPaymentMethod: PKPaymentMethod?
    /// Set during `didAuthorizePayment`
    var payment: PKPayment?
    var paymentData: PaymentData?
    private var selectedShippingContact: Result<PKContact, ShopifyAcceleratedCheckouts.Error> =
        .failure(
            .invariant(expected: "shippingContact")
        )
    var configuration: ApplePayConfigurationWrapper

    init(
        configuration: ApplePayConfigurationWrapper,
        cart: @escaping () -> StorefrontAPI.Types.Cart?
    ) {
        self.configuration = configuration
        self.cart = cart
    }

    /// Since Apple Pay includes US Territories as country codes,
    /// these are remapped as zoneCodes and the countryCode set to `CountryCode.Us` in mapToAddress().
    /// Returning the US Territory string here ensures we reach that logic.
    static let US_TERRITORY_COUNTRY_CODES: [String: String] = [
        "AS": "US",
        "GU": "US",
        "MP": "US",
        "PR": "US",
        "VI": "US"
    ]

    /// Provides valid, corresponding CountryCode for known but invalid country codes
    /// See https://github.com/Shopify/checkout-web/pull/28334
    static let FallbackCountryCodes: [String: String] = [
        "UK": "GB",
        "JA": "JP",
        "US": "US"
    ]

    // MARK: Identifiers

    var cartID: Result<StorefrontAPI.Types.ID, ShopifyAcceleratedCheckouts.Error> {
        guard let cartID = cart()?.id else {
            return .failure(.invariant(expected: "cart"))
        }
        return .success(cartID)
    }

    var selectedDeliveryOptionHandle:
        Result<StorefrontAPI.Types.ID, ShopifyAcceleratedCheckouts.Error>
    {
        guard let selectedShippingMethod else {
            return .failure(.invariant(expected: "shippingMethod"))
        }
        /// The deliveryOptionHandle is set as the shippingMethodIdentifier in PKDecoder.swift
        guard let identifier = selectedShippingMethod.identifier else {
            return .failure(.invariant(expected: "shippingMethodID"))
        }
        return .success(StorefrontAPI.Types.ID(identifier))
    }

    var deliveryGroupID: Result<StorefrontAPI.Types.ID, ShopifyAcceleratedCheckouts.Error> {
        guard let cart = cart() else {
            return .failure(.invariant(expected: "cart"))
        }
        guard let selectedShippingMethodId = try? selectedDeliveryOptionHandle.get() else {
            return .failure(.invariant(expected: "shippingMethodID"))
        }
        guard
            let deliveryGroupID = PassKitFactory.shared.getDeliveryOptionHandle(
                groups: cart.deliveryGroups.nodes,
                by: selectedShippingMethodId
            )
        else {
            return .failure(.invariant(expected: "shippingMethodID"))
        }
        return .success(deliveryGroupID)
    }

    // MARK: Contacts

    private func mapCNPostalAddressToAddress(
        address: CNPostalAddress
    ) -> Result<StorefrontAPI.Address, ShopifyAcceleratedCheckouts.Error> {
        let contact = cnPostalAddressToPkContact(address: address)
        guard let address = try? pkContactToAddress(contact: contact).get() else {
            return .failure(.invariant(expected: "address.pkContactToAddress"))
        }
        return .success(address)
    }

    /// Returns `isoCountryCode` from `didAuthorizePayment` PKPaymentRequest.billingContact
    /// Otherwise falls back to the `didSelectPaymentMethod` PKPaymentMethod.billingContact
    var billingPostalAddress: Result<StorefrontAPI.Address, ShopifyAcceleratedCheckouts.Error> {
        if let billingContact = try? billingContact.get(),
           let billingPostalAddress = billingContact.postalAddress
        {
            return mapCNPostalAddressToAddress(address: billingPostalAddress)
        }

        guard
            let selectedBillingPostalAddress =
            selectedPaymentMethod?.billingAddress?.postalAddresses.first?.value
        else {
            return .failure(.invariant(expected: "selectedPaymentMethod"))
        }

        return mapCNPostalAddressToAddress(address: selectedBillingPostalAddress)
    }

    var billingContact: Result<PKContact, ShopifyAcceleratedCheckouts.Error> {
        guard let billingContact = payment?.billingContact else {
            return .failure(.invariant(expected: "payment"))
        }
        return .success(billingContact)
    }

    var shippingContact: Result<PKContact, ShopifyAcceleratedCheckouts.Error> {
        get {
            if let shippingContact = payment?.shippingContact {
                return .success(shippingContact)
            }

            switch selectedShippingContact {
            case .success:
                return selectedShippingContact
            case .failure:
                return .failure(.invariant(expected: "payment"))
            }
        }
        set { selectedShippingContact = newValue }
    }

    typealias LastDigits = String
    var lastDigits: Result<LastDigits, ShopifyAcceleratedCheckouts.Error> {
        guard let payment else {
            return .failure(.invariant(expected: "payment"))
        }
        guard
            let digits = payment
            .token
            .paymentMethod
            .displayName?
            .components(separatedBy: " ")
            .last
        else {
            return .failure(.invariant(expected: "displayName"))
        }
        return .success(digits)
    }

    func getValue(code: String) -> String? {
        if PKEncoder.US_TERRITORY_COUNTRY_CODES[code] != nil {
            return PKEncoder.FallbackCountryCodes["US"]
        }
        return PKEncoder.FallbackCountryCodes[code]
    }

    /// Apple's countryCode conforms to ISO-3166 used in our API but in lower case
    /// https://github.com/Shopify/portable-wallets/blob/main/src/components/ApplePayButton/helpers/map-to-address.ts#L63
    func mapToCountryCode(code: String?) -> String {
        guard let code, !code.isEmpty else { return "ZZ" }

        let countryCode = code.uppercased()

        if let value = getValue(code: countryCode) {
            return value
        }

        // Allow the API return an error if the country code is not recognized
        return countryCode
    }

    func cnPostalAddressToPkContact(address: CNPostalAddress) -> PKContact {
        let contact = PKContact()
        contact.postalAddress = address
        return contact
    }

    func pkContactToAddress(contact: PKContact?)
        -> Result<StorefrontAPI.Types.Address, ShopifyAcceleratedCheckouts.Error>
    {
        guard let postalAddress = contact?.postalAddress else {
            return .failure(.invariant(expected: "postalAddress"))
        }
        let country = mapToCountryCode(code: postalAddress.isoCountryCode)
        // HK does not have postal codes. Apple Pay puts Region in postalCode
        // See: https://github.com/Shopify/portable-wallets/blob/main/src/components/ApplePayButton/helpers/map-to-address.ts#L17
        var (zip, province): (String?, String?) =
            switch country {
            case "HK": (nil, postalAddress.postalCode)
            default:
                (
                    postalAddress.postalCode,
                    !postalAddress.state.isEmpty
                        ? postalAddress.state
                        : !postalAddress.subLocality.isEmpty ? postalAddress.subLocality : nil
                )
            }

        // https://github.com/Shopify/portable-wallets/blob/69bcad21de759cc191f86b38a8a12ecee18e3b6e/src/components/ApplePayButton/helpers/map-to-address.ts#L42
        if PKEncoder.US_TERRITORY_COUNTRY_CODES[postalAddress.country] != nil {
            province = postalAddress.country
        }

        let addressLines = postalAddress.street
            .split { $0 == "\n" }
            .map { String($0) }

        /// Apple Pay forces last & first names to be present on addresses added in the payment sheet (at least it does for
        /// desktop and >=16.2 iOS), but it's still possible to add addresses without a last name in the Apple Wallet
        /// settings
        /// This lines up with what we do for Google Pay & Meta Pay when only a single name is provided
        /// See: https://github.com/Shopify/core-issues/issues/53587
        let lastName: String? = {
            let familyName = contact?.name?.familyName
            if let familyName, !familyName.isEmpty { return familyName }
            return contact?.name?.givenName
        }()

        return .success(
            StorefrontAPI.Types.Address(
                address1: addressLines[safe: 0],
                address2: addressLines[safe: 1],
                city: contact?.postalAddress?.city,
                country: country,
                firstName: contact?.name?.givenName,
                lastName: lastName,
                phone: contact?.phoneNumber?.stringValue,
                province: province,
                zip: zip
            )
        )
    }

    var billingAddress: Result<StorefrontAPI.Types.Address, ShopifyAcceleratedCheckouts.Error> {
        guard let contact = try? billingContact.get() else {
            return .failure(.invariant(expected: "billingContact"))
        }
        return pkContactToAddress(contact: contact)
    }

    var shippingAddress: Result<StorefrontAPI.Types.Address, ShopifyAcceleratedCheckouts.Error> {
        guard let contact = try? shippingContact.get() else {
            return .failure(.invariant(expected: "shippingContact"))
        }
        return pkContactToAddress(contact: contact)
    }

    var totalAmount: Result<StorefrontAPI.Types.Money, ShopifyAcceleratedCheckouts.Error> {
        guard let cart = cart() else {
            return .failure(.invariant(expected: "cart"))
        }
        return .success(
            StorefrontAPI.Types.Money(
                amount: cart.cost.totalAmount.amount,
                currencyCode: cart.cost.totalAmount.currencyCode
            )
        )
    }

    var phoneNumber: Result<String, ShopifyAcceleratedCheckouts.Error> {
        guard
            let contact = try? shippingContact.get(),
            let phoneNumber = contact.phoneNumber?.stringValue,
            !phoneNumber.isEmpty
        else {
            return .failure(.invariant(expected: "phoneNumber"))
        }

        return .success(phoneNumber)
    }

    typealias Email = String
    var email: Result<Email, ShopifyAcceleratedCheckouts.Error> {
        if let email = configuration.common.customer?.email {
            return .success(email)
        }

        guard
            let contact = try? shippingContact.get(),
            let email = contact.emailAddress,
            !email.isEmpty
        else {
            return .failure(.invariant(expected: "email"))
        }

        return .success(email)
    }

    var applePayPayment:
        Result<StorefrontAPI.Types.ApplePayPayment, ShopifyAcceleratedCheckouts.Error>
    {
        guard let payment else {
            return .failure(.invariant(expected: "payment"))
        }
        guard let paymentData = decodePaymentData(payment: payment) else {
            return .failure(.invariant(expected: "paymentData"))
        }
        guard let billingAddress = try? billingAddress.get() else {
            return .failure(.invariant(expected: "billingAddress"))
        }
        guard let lastDigits = try? lastDigits.get() else {
            return .failure(.invariant(expected: "lastDigits"))
        }

        return .success(
            StorefrontAPI.Types.ApplePayPayment(
                billingAddress: billingAddress,
                ephemeralPublicKey: paymentData.header.ephemeralPublicKey,
                publicKeyHash: paymentData.header.publicKeyHash,
                transactionId: paymentData.header.transactionId,
                data: paymentData.data,
                signature: paymentData.signature,
                version: paymentData.version,
                lastDigits: lastDigits
            )
        )
    }
}
