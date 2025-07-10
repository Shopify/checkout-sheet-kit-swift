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

import Foundation
import PassKit

@available(iOS 17.0, *)
extension ErrorHandler {
    static func map(
        payload: StorefrontAPI.CartSubmitForCompletionPayload, shippingCountry: String?
    ) -> PaymentSheetAction {
        guard let result = payload.result else { return PaymentSheetAction.interrupt(reason: .other) }
        switch result {
        case let .failed(submitFailed):
            let filteredErrors = filterGenericViolations(errors: submitFailed.errors)
            let actions = filteredErrors.map {
                getErrorAction(error: $0, shippingCountry: shippingCountry, checkoutURL: submitFailed.checkoutUrl?.url)
            }
            return getHighestPriorityAction(actions: actions)
        case .alreadyAccepted:
            return PaymentSheetAction.interrupt(reason: .other)
        case .throttled:
            return PaymentSheetAction.interrupt(reason: .cartThrottled)
        case .success:
            // No-op: error handler not called for success result
            // Other response type are not possible
            print("ErrorHandler: map: received unexpected result type from Cart API on submit")
            return PaymentSheetAction.interrupt(reason: .other)
        }
    }

    private static func getErrorAction(error: StorefrontAPI.SubmissionError, shippingCountry: String?, checkoutURL: URL?)
        -> PaymentSheetAction
    {
        switch error.code {
        // --- Contact information ---

        // Email
        case .buyerIdentityEmailRequired:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.emailInvalid(
                message: "errors.missing.email".localizedString)])

        case .buyerIdentityEmailIsInvalid:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.emailInvalid(
                message: "errors.invalid.email".localizedString)])

        // Phone number
        case .deliveryPhoneNumberRequired:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.phoneNumberInvalid(
                message: "errors.missing.phone".localizedString)])

        case .deliveryPhoneNumberInvalid:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.phoneNumberInvalid(
                message: "errors.invalid.phone".localizedString)])

        // First name
        case .deliveryFirstNameRequired, .paymentsFirstNameRequired:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                message: "errors.missing.first_name".localizedString)])

        case .deliveryFirstNameInvalid, .paymentsFirstNameInvalid:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                message: "errors.invalid.first_name".localizedString)])

        case .deliveryFirstNameTooLong, .paymentsFirstNameTooLong:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                message: "errors.too_long.first_name".localizedString)])

        // Last name
        case .deliveryLastNameRequired, .paymentsLastNameRequired:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                message: "errors.missing.last_name".localizedString)])

        case .deliveryLastNameInvalid, .paymentsLastNameInvalid:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                message: "errors.invalid.last_name".localizedString)])

        case .deliveryLastNameTooLong, .paymentsLastNameTooLong:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                message: "errors.too_long.last_name".localizedString)])

        // --- Delivery address ---

        // Address 1
        case .deliveryAddress1Required:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                field: CNPostalAddressStreetKey,
                message: "errors.missing.address1".localizedString
            )])

        case .deliveryAddress1Invalid:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                field: CNPostalAddressStreetKey,
                message: "errors.invalid.address1".localizedString
            )])

        case .deliveryAddress1TooLong:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                field: CNPostalAddressStreetKey,
                message: "errors.too_long.address1".localizedString
            )])

        // Address 2
        case .deliveryAddress2Required:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                field: CNPostalAddressStreetKey,
                message: "errors.missing.address2".localizedString
            )])

        case .deliveryAddress2Invalid:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                field: CNPostalAddressStreetKey,
                message: "errors.invalid.address2".localizedString
            )])

        case .deliveryAddress2TooLong:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                field: CNPostalAddressStreetKey,
                message: "errors.too_long.address2".localizedString
            )])

        // Postal code
        case .deliveryPostalCodeRequired:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                field: CNPostalAddressPostalCodeKey,
                message: "errors.missing.postal_code".localizedString
            )])

        case .deliveryPostalCodeInvalid:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                field: CNPostalAddressPostalCodeKey,
                message: "errors.invalid.postal_code".localizedString
            )])

        case .deliveryInvalidPostalCodeForCountry,
             .deliveryInvalidPostalCodeForZone:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                field: CNPostalAddressPostalCodeKey,
                message: "errors.invalid.postal_code".localizedString
            )])

        // City
        case .deliveryCityRequired:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                field: CNPostalAddressCityKey,
                message: "errors.missing.city".localizedString
            )])

        case .deliveryCityInvalid:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                field: CNPostalAddressCityKey,
                message: "errors.invalid.city".localizedString
            )])

        case .deliveryCityTooLong:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                field: CNPostalAddressCityKey,
                message: "errors.too_long.city".localizedString
            )])

        // Zone
        case .deliveryZoneNotFound:
            if useEmirate(shippingCountry: shippingCountry) {
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors
                        .deliveryAddressInvalid(
                            field: CNPostalAddressSubLocalityKey,
                            message: "errors.invalid.emirate".localizedString
                        )
                ])
            }
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                field: CNPostalAddressSubAdministrativeAreaKey,
                message: "errors.invalid.zone".localizedString
            )])

        case .deliveryZoneRequiredForCountry:
            if useEmirate(shippingCountry: shippingCountry) {
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors
                        .deliveryAddressInvalid(
                            field: CNPostalAddressSubLocalityKey,
                            message: "errors.missing.emirate".localizedString
                        )
                ])
            }
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                field: CNPostalAddressSubAdministrativeAreaKey,
                message: "errors.missing.zone".localizedString
            )])

        // Country
        case .deliveryCountryRequired:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                field: CNPostalAddressCountryKey,
                message: "errors.missing.country".localizedString
            )])

        // No delivery method available for the provided address
        case .deliveryNoDeliveryAvailable,
             .noDeliveryGroupSelected:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.addressUnserviceableError])

        // --- Billing address ---

        // Address 1
        case .paymentsAddress1Required:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.billingAddressInvalid(
                field: CNPostalAddressStreetKey,
                message: "errors.missing.address1".localizedString
            )])

        case .paymentsAddress1Invalid:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.billingAddressInvalid(
                field: CNPostalAddressStreetKey,
                message: "errors.invalid.address1".localizedString
            )])

        case .paymentsAddress1TooLong:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.billingAddressInvalid(
                field: CNPostalAddressStreetKey,
                message: "errors.too_long.address1".localizedString
            )])

        // Address 2
        case .paymentsAddress2Required:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.billingAddressInvalid(
                field: CNPostalAddressStreetKey,
                message: "errors.missing.address2".localizedString
            )])

        case .paymentsAddress2Invalid:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.billingAddressInvalid(
                field: CNPostalAddressStreetKey,
                message: "errors.invalid.address2".localizedString
            )])

        case .paymentsAddress2TooLong:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.billingAddressInvalid(
                field: CNPostalAddressStreetKey,
                message: "errors.too_long.address2".localizedString
            )])

        // Postal code
        case .paymentsPostalCodeRequired:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.billingAddressInvalid(
                field: CNPostalAddressPostalCodeKey,
                message: "errors.missing.postal_code".localizedString
            )])

        case .paymentsPostalCodeInvalid:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.billingAddressInvalid(
                field: CNPostalAddressPostalCodeKey,
                message: "errors.invalid.postal_code".localizedString
            )])

        case .paymentsInvalidPostalCodeForCountry,
             .paymentsInvalidPostalCodeForZone:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.billingAddressInvalid(
                field: CNPostalAddressPostalCodeKey,
                message: "errors.invalid.postal_code".localizedString
            )])

        // City
        case .paymentsCityRequired:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.billingAddressInvalid(
                field: CNPostalAddressCityKey,
                message: "errors.missing.city".localizedString
            )])

        case .paymentsCityInvalid:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.billingAddressInvalid(
                field: CNPostalAddressCityKey,
                message: "errors.invalid.city".localizedString
            )])

        case .paymentsCityTooLong:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.billingAddressInvalid(
                field: CNPostalAddressCityKey,
                message: "errors.too_long.city".localizedString
            )])

        // Zone
        case .paymentsBillingAddressZoneNotFound:
            if useEmirate(shippingCountry: shippingCountry) {
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors
                        .billingAddressInvalid(
                            field: CNPostalAddressSubLocalityKey,
                            message: "errors.invalid.emirate".localizedString
                        )
                ])
            }
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.billingAddressInvalid(
                field: CNPostalAddressSubAdministrativeAreaKey,
                message: "errors.invalid.zone".localizedString
            )])

        case .paymentsBillingAddressZoneRequiredForCountry:
            if useEmirate(shippingCountry: shippingCountry) {
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors
                        .billingAddressInvalid(
                            field: CNPostalAddressSubLocalityKey,
                            message: "errors.missing.emirate".localizedString
                        )
                ])
            }
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.billingAddressInvalid(
                field: CNPostalAddressSubAdministrativeAreaKey,
                message: "errors.missing.zone".localizedString
            )])

        // Country
        case .paymentsCountryRequired:
            return PaymentSheetAction.showError(errors: [ApplePayAuthorizationDelegate.ValidationErrors.billingAddressInvalid(
                field: CNPostalAddressCountryKey,
                message: "errors.missing.country".localizedString
            )])

        // --- Errors that lead to deceleration ---

        // Address missing
        case .deliveryAddressRequired:
            // No-op: We should not have called SubmitForCompletion with empty address
            return PaymentSheetAction.interrupt(reason: .unhandled, checkoutURL: checkoutURL)

        // Phone number
        case .buyerIdentityPhoneIsInvalid,
             .deliveryOptionsPhoneNumberInvalid,
             .deliveryOptionsPhoneNumberRequired,
             .paymentsPhoneNumberInvalid,
             .paymentsPhoneNumberRequired:
            // No-op: We save the phone number on delivery address, not buyer identity, billing address or delivery options
            return PaymentSheetAction.interrupt(reason: .unhandled, checkoutURL: checkoutURL)

        // Company
        case .deliveryCompanyRequired,
             .deliveryCompanyInvalid,
             .deliveryCompanyTooLong,
             .paymentsCompanyRequired,
             .paymentsCompanyInvalid,
             .paymentsCompanyTooLong:
            // No-op: Not possible to get company field from Apple Pay
            return PaymentSheetAction.interrupt(reason: .unhandled, checkoutURL: checkoutURL)

        case .paymentsCreditCardBaseExpired,
             .paymentsCreditCardBaseGatewayNotSupported,
             .paymentsCreditCardBaseInvalidStartDateOrIssueNumberForDebit,
             .paymentsCreditCardBrandNotSupported,
             .paymentsCreditCardFirstNameBlank,
             .paymentsCreditCardGeneric,
             .paymentsCreditCardLastNameBlank,
             .paymentsCreditCardMonthInclusion,
             .paymentsCreditCardNameInvalid,
             .paymentsCreditCardNumberInvalid,
             .paymentsCreditCardNumberInvalidFormat,
             .paymentsCreditCardSessionId,
             .paymentsCreditCardVerificationValueBlank,
             .paymentsCreditCardVerificationValueInvalidForCardType,
             .paymentsCreditCardYearExpired,
             .paymentsCreditCardYearInvalidExpiryYear:
            // No-op: These are specific to direct payment methods, not Apple Pay
            return PaymentSheetAction.interrupt(reason: .unhandled, checkoutURL: checkoutURL)

        // Payment Method Errors
        case .paymentsMethodRequired,
             .paymentsMethodUnavailable,
             .paymentsShopifyPaymentsRequired,
             .paymentsWalletContentMissing,
             .paymentCardDeclined:
            // Payment method issues - not fixable by user input validation
            return PaymentSheetAction.interrupt(reason: .unhandled, checkoutURL: checkoutURL)

        case .paymentsUnacceptablePaymentAmount:
            return PaymentSheetAction.interrupt(reason: .dynamicTax, checkoutURL: checkoutURL)

        // Inventory issues
        case .merchandiseNotEnoughStockAvailable:
            return PaymentSheetAction.interrupt(reason: .notEnoughStock, checkoutURL: checkoutURL)

        case .merchandiseLineLimitReached,
             .merchandiseNotApplicable,
             .merchandiseOutOfStock,
             .merchandiseProductNotPublished,
             .deliveryNoDeliveryAvailableForMerchandiseLine:
            return PaymentSheetAction.interrupt(reason: .outOfStock, checkoutURL: checkoutURL)

        // Tax Errors
        case .taxesDeliveryGroupIdNotFound,
             .taxesLineIdNotFound,
             .taxesMustBeDefined:
            return PaymentSheetAction.interrupt(reason: .unhandled, checkoutURL: checkoutURL)

        // Custom validations from functions
        case .validationCustom:
            return PaymentSheetAction.interrupt(reason: .other, checkoutURL: checkoutURL)

        // Generic Errors
        case .error,
             .redirectToCheckoutRequired,
             .unknownValue:
            return PaymentSheetAction.interrupt(reason: .unhandled, checkoutURL: checkoutURL)
        }
    }

    private static func filterGenericViolations(errors: [StorefrontAPI.SubmissionError]) -> [StorefrontAPI.SubmissionError] {
        // If the only error is paymentsUnacceptablePaymentAmount, return it
        if errors.count == 1, errors.first?.code == .paymentsUnacceptablePaymentAmount {
            return errors
        }
        // Otherwise, filter out paymentsUnacceptablePaymentAmount
        return errors.filter { $0.code != .paymentsUnacceptablePaymentAmount }
    }
}
