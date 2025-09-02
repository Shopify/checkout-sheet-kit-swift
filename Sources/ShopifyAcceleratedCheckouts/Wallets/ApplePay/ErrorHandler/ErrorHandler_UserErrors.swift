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

@available(iOS 16.0, *)
extension ErrorHandler {
    static func map(
        errors: [StorefrontAPI.CartUserError],
        shippingCountry: String?,
        cart: StorefrontAPI.Types.Cart?
    ) -> PaymentSheetAction {
        let actions = errors.map {
            getErrorAction(error: $0, shippingCountry: shippingCountry, cart: cart)
        }
        return getHighestPriorityAction(actions: actions)
    }

    // swiftlint:disable:next cyclomatic_complexity
    private static func getErrorAction(
        error: StorefrontAPI.CartUserError,
        shippingCountry: String?,
        cart: StorefrontAPI.Types.Cart?
    ) -> PaymentSheetAction {
        let field = mapField(field: error.field)

        switch error.code {
        // Field missing or invalid
        case .addressFieldContainsEmojis:
            switch field {
            case "addresses.0.address.deliveryAddress.firstName":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                        message: "errors.emojis.first_name".localizedString)
                ])
            case "addresses.0.address.deliveryAddress.lastName":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                        message: "errors.emojis.last_name".localizedString)
                ])
            case "addresses.0.address.deliveryAddress.address1":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                        field: CNPostalAddressStreetKey,
                        message: "errors.emojis.address1".localizedString
                    )
                ])
            case "addresses.0.address.deliveryAddress.address2":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                        field: CNPostalAddressStreetKey,
                        message: "errors.emojis.address2".localizedString
                    )
                ])
            case "addresses.0.address.deliveryAddress.city":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                        field: CNPostalAddressCityKey,
                        message: "errors.emojis.city".localizedString
                    )
                ])
            case "addresses.0.address.deliveryAddress.zip":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                        field: CNPostalAddressPostalCodeKey,
                        message: "errors.emojis.postal_code".localizedString
                    )
                ])
            default:
                return PaymentSheetAction.interrupt(
                    reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
                )
            }
        case .addressFieldContainsHtmlTags:
            switch field {
            case "addresses.0.address.deliveryAddress.firstName":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                        message: "errors.html_tags.first_name".localizedString)
                ])
            case "addresses.0.address.deliveryAddress.lastName":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                        message: "errors.html_tags.last_name".localizedString)
                ])
            case "addresses.0.address.deliveryAddress.address1":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                        field: CNPostalAddressStreetKey,
                        message: "errors.html_tags.address1".localizedString
                    )
                ])
            case "addresses.0.address.deliveryAddress.address2":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                        field: CNPostalAddressStreetKey,
                        message: "errors.html_tags.address2".localizedString
                    )
                ])
            case "addresses.0.address.deliveryAddress.city":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                        field: CNPostalAddressCityKey,
                        message: "errors.html_tags.city".localizedString
                    )
                ])
            default:
                return PaymentSheetAction.interrupt(
                    reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
                )
            }
        case .addressFieldContainsUrl:
            switch field {
            case "addresses.0.address.deliveryAddress.firstName":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                        message: "errors.url.first_name".localizedString)
                ])
            case "addresses.0.address.deliveryAddress.lastName":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                        message: "errors.url.last_name".localizedString)
                ])
            default:
                return PaymentSheetAction.interrupt(
                    reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
                )
            }
        case .addressFieldDoesNotMatchExpectedPattern:
            switch field {
            case "addresses.0.address.deliveryAddress.firstName":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                        message: "errors.invalid.first_name".localizedString)
                ])
            case "addresses.0.address.deliveryAddress.lastName":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                        message: "errors.invalid.last_name".localizedString)
                ])
            case "addresses.0.address.deliveryAddress.phone":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.phoneNumberInvalid(
                        message: "errors.invalid.phone".localizedString)
                ])
            default:
                return PaymentSheetAction.interrupt(
                    reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
                )
            }
        case .addressFieldIsRequired:
            switch field {
            case "addresses.0.address.deliveryAddress.firstName":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                        message: "errors.missing.first_name".localizedString)
                ])
            case "addresses.0.address.deliveryAddress.lastName":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                        message: "errors.missing.last_name".localizedString)
                ])
            case "addresses.0.address.deliveryAddress.address1":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                        field: CNPostalAddressStreetKey,
                        message: "errors.missing.address1".localizedString
                    )
                ])
            case "addresses.0.address.deliveryAddress.address2":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                        field: CNPostalAddressStreetKey,
                        message: "errors.missing.address2".localizedString
                    )
                ])
            case "addresses.0.address.deliveryAddress.city":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                        field: CNPostalAddressCityKey,
                        message: "errors.missing.city".localizedString
                    )
                ])
            case "addresses.0.address.deliveryAddress.zip":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                        field: CNPostalAddressPostalCodeKey,
                        message: "errors.missing.postal_code".localizedString
                    )
                ])
            case "addresses.0.address.deliveryAddress.phone":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.phoneNumberInvalid(
                        message: "errors.missing.phone".localizedString)
                ])
            default:
                return PaymentSheetAction.interrupt(
                    reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
                )
            }
        case .addressFieldIsTooLong:
            switch field {
            case "addresses.0.address.deliveryAddress.firstName":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                        message: "errors.too_long.first_name".localizedString)
                ])
            case "addresses.0.address.deliveryAddress.lastName":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.nameInvalid(
                        message: "errors.too_long.last_name".localizedString)
                ])
            case "addresses.0.address.deliveryAddress.address1":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                        field: CNPostalAddressStreetKey,
                        message: "errors.too_long.address1".localizedString
                    )
                ])
            case "addresses.0.address.deliveryAddress.address2":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                        field: CNPostalAddressStreetKey,
                        message: "errors.too_long.address2".localizedString
                    )
                ])
            case "addresses.0.address.deliveryAddress.city":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                        field: CNPostalAddressCityKey,
                        message: "errors.too_long.city".localizedString
                    )
                ])
            default:
                return PaymentSheetAction.interrupt(
                    reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
                )
            }
        case .invalid:
            switch field {
            case "buyerIdentity.email":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.emailInvalid(
                        message: "errors.invalid.email".localizedString)
                ])
            case "input.lines.0.quantity":
                // Stock problem, decelerate
                return PaymentSheetAction.interrupt(
                    reason: .outOfStock, checkoutURL: cart?.checkoutUrl.url
                )
            case "buyerIdentity.phone":
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors.phoneNumberInvalid(
                        message: "errors.invalid.phone".localizedString)
                ])
            default:
                return PaymentSheetAction.interrupt(
                    reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
                )
            }
        case .invalidDeliveryGroup,
             .invalidDeliveryOption,
             .unspecifiedAddressError,
             .zipCodeNotSupported:
            // Cannot deliver to address
            return PaymentSheetAction.showError(errors: [
                ApplePayAuthorizationDelegate.ValidationErrors.addressUnserviceableError
            ])
        case .invalidMerchandiseLine:
            // No-op: Should not happens since we do not pass merchandise lines to the API
            return PaymentSheetAction.interrupt(
                reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
            )
        case .invalidPayment:
            switch field {
            case "amount", "payment.amount":
                return PaymentSheetAction.interrupt(
                    reason: .other, checkoutURL: cart?.checkoutUrl.url
                )
            default:
                return PaymentSheetAction.interrupt(
                    reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
                )
            }
        case .invalidPaymentEmptyCart:
            // No-op: Should have caught the problem earlier
            return PaymentSheetAction.interrupt(
                reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
            )
        case .invalidZipCodeForCountry,
             .invalidZipCodeForProvince:
            return PaymentSheetAction.showError(errors: [
                ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                    field: CNPostalAddressPostalCodeKey,
                    message: "errors.invalid.postal_code".localizedString
                )
            ])
        case .invalidIncrement,
             .lessThan,
             .maximumExceeded,
             .minimumNotMet:
            // No-op: Problems related to quantity rules
            return PaymentSheetAction.interrupt(
                reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
            )
        case .invalidMetafields,
             .missingCustomerAccessToken,
             .missingDiscountCode,
             .missingNote,
             .noteTooLong:
            // No-op: These are not handled within the Apple Pay flow
            return PaymentSheetAction.interrupt(
                reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
            )
        case .onlyOneDeliveryAddressCanBeSelected,
             .tooManyDeliveryAddresses:
            // No-op: We never try to select multiple addresses within Apple Pay
            return PaymentSheetAction.interrupt(
                reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
            )
        case .paymentsCreditCardBaseExpired,
             .paymentsCreditCardBaseGatewayNotSupported,
             .paymentsCreditCardGeneric,
             .paymentsCreditCardMonthInclusion,
             .paymentsCreditCardNumberInvalid,
             .paymentsCreditCardNumberInvalidFormat,
             .paymentsCreditCardVerificationValueBlank,
             .paymentsCreditCardVerificationValueInvalidForCardType,
             .paymentsCreditCardYearExpired,
             .paymentsCreditCardYearInvalidExpiryYear:
            // No-op: These are specific to direct payment methods, not Apple Pay
            return PaymentSheetAction.interrupt(
                reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
            )
        case .paymentMethodNotSupported:
            switch field {
            case "payment.walletPaymentMethod.applePayWalletContent":
                return PaymentSheetAction.interrupt(
                    reason: .other, checkoutURL: cart?.checkoutUrl.url
                )
            default:
                return PaymentSheetAction.interrupt(
                    reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
                )
            }
        case .pendingDeliveryGroups:
            // No-op: We are not using the defer directive
            return PaymentSheetAction.interrupt(
                reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
            )
        case .provinceNotFound:
            if useEmirate(shippingCountry: shippingCountry) {
                return PaymentSheetAction.showError(errors: [
                    ApplePayAuthorizationDelegate.ValidationErrors
                        .deliveryAddressInvalid(
                            field: CNPostalAddressSubLocalityKey,
                            message: "errors.invalid.emirate".localizedString
                        )
                ])
            }
            return PaymentSheetAction.showError(errors: [
                ApplePayAuthorizationDelegate.ValidationErrors.deliveryAddressInvalid(
                    field: CNPostalAddressSubAdministrativeAreaKey,
                    message: "errors.invalid.zone".localizedString
                )
            ])
        case .invalidCompanyLocation:
            // No-op: Not possible to get company field from Apple Pay
            return PaymentSheetAction.interrupt(
                reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
            )
        case .invalidDeliveryAddressId:
            // Should not happen if the wrapper is working correctly
            return PaymentSheetAction.interrupt(
                reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
            )
        case .validationCustom:
            // Custom validations from functions are not handled
            return PaymentSheetAction.interrupt(reason: .other, checkoutURL: cart?.checkoutUrl.url)
        case .variantRequiresSellingPlan,
             .sellingPlanNotApplicable:
            return PaymentSheetAction.interrupt(
                reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
            )
        case .cartTooLarge,
             .serviceUnavailable:
            // Problems with storing the cart
            return PaymentSheetAction.interrupt(
                reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
            )
        // Legacy/compatibility cases
        case .tooManyLineItems:
            return PaymentSheetAction.interrupt(
                reason: .outOfStock, checkoutURL: cart?.checkoutUrl.url
            )
        case .notApplicable:
            return PaymentSheetAction.interrupt(
                reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
            )
        case .notEnoughStock:
            return PaymentSheetAction.interrupt(
                reason: .notEnoughStock, checkoutURL: cart?.checkoutUrl.url
            )
        case .insufficientBalance:
            return PaymentSheetAction.interrupt(
                reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
            )
        case .deliveryAddressSizeExceeded:
            return PaymentSheetAction.interrupt(
                reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
            )
        case .paymentMethodUnavailable:
            return PaymentSheetAction.interrupt(
                reason: .other, checkoutURL: cart?.checkoutUrl.url
            )
        // Generic Errors
        case .unknownValue,
             nil:
            return PaymentSheetAction.interrupt(
                reason: .unhandled, checkoutURL: cart?.checkoutUrl.url
            )
        }
    }

    private static func mapField(field: [String]?) -> String? {
        return field?.joined(separator: ".")
    }
}
