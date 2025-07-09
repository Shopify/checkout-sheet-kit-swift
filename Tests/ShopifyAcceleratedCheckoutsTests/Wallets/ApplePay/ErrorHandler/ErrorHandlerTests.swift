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

@testable import ShopifyAcceleratedCheckouts
import XCTest

class ErrorHandlerTests: XCTestCase {
    func testUseEmirate_whenShippingCountryIsAE_returnsTrue() {
        let shippingCountry = "AE"
        let result = ErrorHandler.useEmirate(shippingCountry: shippingCountry)
        XCTAssertTrue(result)
    }

    func testUseEmirate_whenShippingCountryIsOtherCountry_returnsFalse() {
        let testCases = ["US", "CA", "GB", "DE", "FR", "JP", "AU", "IN"]
        for country in testCases {
            let result = ErrorHandler.useEmirate(shippingCountry: country)
            XCTAssertFalse(result)
        }
    }

    func testUseEmirate_whenShippingCountryIsNil_returnsFalse() {
        let shippingCountry: String? = nil
        let result = ErrorHandler.useEmirate(shippingCountry: shippingCountry)
        XCTAssertFalse(result)
    }

    func testGetHighestPriorityAction_withSingleAction_returnsThatAction() {
        let regularInterrupt = ErrorHandler.PaymentSheetAction.interrupt(reason: .currencyChanged)
        let unhandledInterrupt = ErrorHandler.PaymentSheetAction.interrupt(reason: .unhandled)
        let showError = ErrorHandler.PaymentSheetAction.showError(errors: [TestError()])

        let singleActions = [regularInterrupt, unhandledInterrupt, showError]

        for action in singleActions {
            let result = ErrorHandler.getHighestPriorityAction(actions: [action])

            switch (action, result) {
            case let (.interrupt(originalReason, originalURL), .interrupt(resultReason, resultURL)):
                XCTAssertEqual(originalReason, resultReason)
                XCTAssertEqual(originalURL, resultURL)
            case let (.showError(originalErrors), .showError(resultErrors)):
                XCTAssertEqual(originalErrors.count, resultErrors.count)
            default:
                XCTFail("Single action should return the same action type")
            }
        }
    }

    func testGetHighestPriorityAction_withEmptyActions_returnsOtherInterrupt() {
        let actions: [ErrorHandler.PaymentSheetAction] = []
        let result = ErrorHandler.getHighestPriorityAction(actions: actions)

        switch result {
        case let .interrupt(reason, checkoutURL):
            XCTAssertEqual(reason, .other)
            XCTAssertNil(checkoutURL)
        default:
            XCTFail("Expected interrupt with .other reason for empty actions")
        }
    }

    func testGetHighestPriorityAction_regularInterruptBeatsShowError() {
        let regularInterrupt = ErrorHandler.PaymentSheetAction.interrupt(reason: .currencyChanged)
        let showError = ErrorHandler.PaymentSheetAction.showError(errors: [TestError()])
        let actions = [showError, regularInterrupt]

        let result = ErrorHandler.getHighestPriorityAction(actions: actions)

        switch result {
        case let .interrupt(reason, _):
            XCTAssertEqual(reason, .currencyChanged)
        default:
            XCTFail("Regular interrupt should beat showError")
        }
    }

    func testGetHighestPriorityAction_regularInterruptBeatsUnhandledInterrupt() {
        let unhandledInterrupt = ErrorHandler.PaymentSheetAction.interrupt(reason: .unhandled)
        let regularInterrupt = ErrorHandler.PaymentSheetAction.interrupt(reason: .dynamicTax)
        let actions = [unhandledInterrupt, regularInterrupt]

        let result = ErrorHandler.getHighestPriorityAction(actions: actions)

        switch result {
        case let .interrupt(reason, _):
            XCTAssertEqual(reason, .dynamicTax)
        default:
            XCTFail("Regular interrupt should beat unhandled interrupt")
        }
    }

    func testGetHighestPriorityAction_showErrorBeatsUnhandledInterrupt() {
        let unhandledInterrupt = ErrorHandler.PaymentSheetAction.interrupt(reason: .unhandled)
        let showError = ErrorHandler.PaymentSheetAction.showError(errors: [TestError()])
        let actions = [unhandledInterrupt, showError]

        let result = ErrorHandler.getHighestPriorityAction(actions: actions)

        switch result {
        case .showError:
            break
        default:
            XCTFail("ShowError should beat unhandled interrupt")
        }
    }

    func testGetHighestPriorityAction_combinesAllShowErrors() {
        let error1 = TestError(message: "Error 1")
        let error2 = TestError(message: "Error 2")
        let error3 = TestError(message: "Error 3")

        let showError1 = ErrorHandler.PaymentSheetAction.showError(errors: [error1])
        let showError2 = ErrorHandler.PaymentSheetAction.showError(errors: [error2, error3])
        let actions = [showError1, showError2]

        let result = ErrorHandler.getHighestPriorityAction(actions: actions)

        switch result {
        case let .showError(errors):
            XCTAssertEqual(errors.count, 3)
            let testErrors = errors.compactMap { $0 as? TestError }
            XCTAssertTrue(testErrors.contains { $0.message == "Error 1" })
            XCTAssertTrue(testErrors.contains { $0.message == "Error 2" })
            XCTAssertTrue(testErrors.contains { $0.message == "Error 3" })
        default:
            XCTFail("Expected showError action")
        }
    }

    func testGetHighestPriorityAction_complexScenarioFollowsPriorityOrder() {
        let unhandledInterrupt = ErrorHandler.PaymentSheetAction.interrupt(reason: .unhandled)
        let regularInterrupt = ErrorHandler.PaymentSheetAction.interrupt(reason: .outOfStock)
        let showError = ErrorHandler.PaymentSheetAction.showError(errors: [TestError()])
        let actions = [unhandledInterrupt, showError, regularInterrupt]

        let result = ErrorHandler.getHighestPriorityAction(actions: actions)

        switch result {
        case let .interrupt(reason, _):
            XCTAssertEqual(reason, .outOfStock)
        default:
            XCTFail("Regular interrupt should have highest priority")
        }
    }

    func testMap_whenApiErrorIsCurrencyChanged_returnsInterruptWithCurrencyChangedReason() {
        let error = StorefrontAPI.Errors.currencyChanged
        let result = ErrorHandler.map(error: error, shippingCountry: "US")

        switch result {
        case let .interrupt(reason, checkoutURL):
            XCTAssertEqual(reason, .currencyChanged)
            XCTAssertNil(checkoutURL)
        default:
            XCTFail("Expected interrupt action with currencyChanged reason")
        }
    }

    // MARK: - Test Helpers

    private struct TestError: Error, Equatable {
        let message: String

        init(message: String = "Test error") {
            self.message = message
        }

        static func == (lhs: TestError, rhs: TestError) -> Bool {
            return lhs.message == rhs.message
        }
    }
}
