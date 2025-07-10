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
@testable import ShopifyAcceleratedCheckouts
import XCTest

@available(iOS 17.0, *)
final class ApplePayStateTransitionTests: XCTestCase {
    // MARK: - Valid Transition Tests

    func testValidTransitions_FromIdle() {
        let fromState = ApplePayState.idle

        XCTAssertTrue(fromState.canTransition(to: .startPaymentRequest), "Should allow idle -> startPaymentRequest")

        XCTAssertFalse(fromState.canTransition(to: .idle), "Should not allow idle -> idle")
        XCTAssertFalse(fromState.canTransition(to: .appleSheetPresented), "Should not allow idle -> appleSheetPresented")
        XCTAssertFalse(fromState.canTransition(to: .completed), "Should not allow idle -> completed")
        XCTAssertFalse(fromState.canTransition(to: .reset), "Should not allow idle -> reset")
    }

    func testValidTransitions_FromStartPaymentRequest() {
        let fromState = ApplePayState.startPaymentRequest

        XCTAssertTrue(fromState.canTransition(to: .appleSheetPresented), "Should allow startPaymentRequest -> appleSheetPresented")
        XCTAssertTrue(fromState.canTransition(to: .reset), "Should allow startPaymentRequest -> reset (failed to present)")

        XCTAssertFalse(fromState.canTransition(to: .idle), "Should not allow startPaymentRequest -> idle")
        XCTAssertFalse(fromState.canTransition(to: .startPaymentRequest), "Should not allow startPaymentRequest -> startPaymentRequest")
        XCTAssertFalse(fromState.canTransition(to: .completed), "Should not allow startPaymentRequest -> completed")
    }

    func testValidTransitions_FromAppleSheetPresented() {
        let fromState = ApplePayState.appleSheetPresented

        XCTAssertTrue(fromState.canTransition(to: .paymentAuthorized(payment: .createMockPayment())), "Should allow appleSheetPresented -> paymentAuthorized")
        XCTAssertTrue(fromState.canTransition(to: .paymentAuthorizationFailed(error: MockError.testError)), "Should allow appleSheetPresented -> paymentAuthorizationFailed")
        XCTAssertTrue(fromState.canTransition(to: .interrupt(reason: .currencyChanged)), "Should allow appleSheetPresented -> interrupt")
        XCTAssertTrue(fromState.canTransition(to: .completed), "Should allow appleSheetPresented -> completed (user cancelled)")

        XCTAssertFalse(fromState.canTransition(to: .idle), "Should not allow appleSheetPresented -> idle")
        XCTAssertFalse(fromState.canTransition(to: .startPaymentRequest), "Should not allow appleSheetPresented -> startPaymentRequest")
        XCTAssertFalse(fromState.canTransition(to: .reset), "Should not allow appleSheetPresented -> reset")
    }

    func testValidTransitions_FromPaymentAuthorized() {
        let fromState = ApplePayState.paymentAuthorized(payment: .createMockPayment())

        XCTAssertTrue(fromState.canTransition(to: ApplePayState.cartSubmittedForCompletion(redirectURL: URL(string: "https://example.com")!)), "Should allow paymentAuthorized -> cartSubmittedForCompletion")
        XCTAssertTrue(fromState.canTransition(to: ApplePayState.paymentAuthorizationFailed(error: MockError.testError)), "Should allow paymentAuthorized -> paymentAuthorizationFailed")
        XCTAssertTrue(fromState.canTransition(to: ApplePayState.interrupt(reason: .currencyChanged)), "Should allow paymentAuthorized -> interrupt")

        XCTAssertFalse(fromState.canTransition(to: ApplePayState.idle), "Should not allow paymentAuthorized -> idle")
        XCTAssertFalse(fromState.canTransition(to: ApplePayState.appleSheetPresented), "Should not allow paymentAuthorized -> appleSheetPresented")
        XCTAssertFalse(fromState.canTransition(to: ApplePayState.completed), "Should not allow paymentAuthorized -> completed")
        XCTAssertFalse(fromState.canTransition(to: ApplePayState.reset), "Should not allow paymentAuthorized -> reset")
    }

    func testValidTransitions_FromPaymentAuthorizationFailed() {
        let fromState = ApplePayState.paymentAuthorizationFailed(error: MockError.testError)

        XCTAssertTrue(fromState.canTransition(to: .completed), "Should allow paymentAuthorizationFailed -> completed")
        XCTAssertTrue(fromState.canTransition(to: .reset), "Should allow paymentAuthorizationFailed -> reset")

        XCTAssertFalse(fromState.canTransition(to: .idle), "Should not allow paymentAuthorizationFailed -> idle")
        XCTAssertFalse(fromState.canTransition(to: .startPaymentRequest), "Should not allow paymentAuthorizationFailed -> startPaymentRequest")
        XCTAssertFalse(fromState.canTransition(to: .appleSheetPresented), "Should not allow paymentAuthorizationFailed -> appleSheetPresented")
    }

    func testValidTransitions_FromCartSubmittedForCompletion() {
        let fromState = ApplePayState.cartSubmittedForCompletion(redirectURL: URL(string: "https://example.com")!)

        XCTAssertTrue(fromState.canTransition(to: .completed), "Should allow cartSubmittedForCompletion -> completed")

        XCTAssertFalse(fromState.canTransition(to: .idle), "Should not allow cartSubmittedForCompletion -> idle")
        XCTAssertFalse(fromState.canTransition(to: .startPaymentRequest), "Should not allow cartSubmittedForCompletion -> startPaymentRequest")
        XCTAssertFalse(fromState.canTransition(to: .reset), "Should not allow cartSubmittedForCompletion -> reset")
        XCTAssertFalse(fromState.canTransition(to: .presentingCSK(url: nil)), "Should not allow cartSubmittedForCompletion -> presentingCSK")
    }

    func testValidTransitions_FromInterrupt() {
        let fromState = ApplePayState.interrupt(reason: .currencyChanged)

        XCTAssertTrue(fromState.canTransition(to: .completed), "Should allow interrupt -> completed")

        XCTAssertFalse(fromState.canTransition(to: .idle), "Should not allow interrupt -> idle")
        XCTAssertFalse(fromState.canTransition(to: .startPaymentRequest), "Should not allow interrupt -> startPaymentRequest")
        XCTAssertFalse(fromState.canTransition(to: .reset), "Should not allow interrupt -> reset")
        XCTAssertFalse(fromState.canTransition(to: .presentingCSK(url: nil)), "Should not allow interrupt -> presentingCSK")
    }

    func testValidTransitions_FromUnexpectedError() {
        let fromState = ApplePayState.unexpectedError(error: MockError.testError)

        XCTAssertTrue(fromState.canTransition(to: .completed), "Should allow unexpectedError -> completed")
        XCTAssertTrue(fromState.canTransition(to: .terminalError(error: MockError.testError)), "Should allow unexpectedError -> terminalError")

        XCTAssertFalse(fromState.canTransition(to: .idle), "Should not allow unexpectedError -> idle")
        XCTAssertFalse(fromState.canTransition(to: .reset), "Should not allow unexpectedError -> reset")
        XCTAssertFalse(fromState.canTransition(to: .presentingCSK(url: nil)), "Should not allow unexpectedError -> presentingCSK")
    }

    func testValidTransitions_FromTerminalError() {
        let fromState = ApplePayState.terminalError(error: MockError.testError)

        XCTAssertTrue(fromState.canTransition(to: .completed), "Should allow terminalError -> completed")

        XCTAssertFalse(fromState.canTransition(to: .idle), "Should not allow terminalError -> idle")
        XCTAssertFalse(fromState.canTransition(to: .reset), "Should not allow terminalError -> reset")
        XCTAssertFalse(fromState.canTransition(to: .startPaymentRequest), "Should not allow terminalError -> startPaymentRequest")
    }

    func testValidTransitions_FromPresentingCSK() {
        let fromState = ApplePayState.presentingCSK(url: URL(string: "https://example.com"))

        XCTAssertTrue(fromState.canTransition(to: .completed), "Should allow presentingCSK -> completed")

        XCTAssertFalse(fromState.canTransition(to: .idle), "Should not allow presentingCSK -> idle")
        XCTAssertFalse(fromState.canTransition(to: .reset), "Should not allow presentingCSK -> reset")
        XCTAssertFalse(fromState.canTransition(to: .startPaymentRequest), "Should not allow presentingCSK -> startPaymentRequest")
    }

    func testValidTransitions_FromCompleted() {
        let fromState = ApplePayState.completed

        XCTAssertTrue(fromState.canTransition(to: .presentingCSK(url: URL(string: "https://example.com"))), "Should allow completed -> presentingCSK")
        XCTAssertTrue(fromState.canTransition(to: .reset), "Should allow completed -> reset")

        XCTAssertFalse(fromState.canTransition(to: .idle), "Should not allow completed -> idle")
        XCTAssertFalse(fromState.canTransition(to: .startPaymentRequest), "Should not allow completed -> startPaymentRequest")
        XCTAssertFalse(fromState.canTransition(to: .completed), "Should not allow completed -> completed")
    }

    func testValidTransitions_FromReset() {
        let fromState = ApplePayState.reset

        XCTAssertTrue(fromState.canTransition(to: .idle), "Should allow reset -> idle")

        XCTAssertFalse(fromState.canTransition(to: .reset), "Should not allow reset -> reset")
        XCTAssertFalse(fromState.canTransition(to: .startPaymentRequest), "Should not allow reset -> startPaymentRequest")
        XCTAssertFalse(fromState.canTransition(to: .completed), "Should not allow reset -> completed")
    }

    // MARK: - Error State Transition Tests

    func testErrorStatesCanBeReachedFromAnyState() {
        let allStates: [ApplePayState] = [
            .idle,
            .startPaymentRequest,
            .appleSheetPresented,
            .paymentAuthorized(payment: .createMockPayment()),
            .paymentAuthorizationFailed(error: MockError.testError),
            .cartSubmittedForCompletion(redirectURL: URL(string: "https://example.com")!),
            .interrupt(reason: .currencyChanged),
            .unexpectedError(error: MockError.testError),
            .terminalError(error: MockError.testError),
            .presentingCSK(url: URL(string: "https://example.com")),
            .completed,
            .reset
        ]

        for state in allStates {
            XCTAssertTrue(
                state.canTransition(to: ApplePayState.unexpectedError(error: MockError.testError)),
                "State \(state) should allow transition to unexpectedError"
            )
            XCTAssertTrue(
                state.canTransition(to: ApplePayState.terminalError(error: MockError.testError)),
                "State \(state) should allow transition to terminalError"
            )
        }
    }

    // MARK: - Comprehensive State Flow Tests

    func testTypicalSuccessFlow() {
        XCTAssertTrue(ApplePayState.idle.canTransition(to: .startPaymentRequest))
        XCTAssertTrue(ApplePayState.startPaymentRequest.canTransition(to: .appleSheetPresented))
        XCTAssertTrue(ApplePayState.appleSheetPresented.canTransition(to: .paymentAuthorized(payment: .createMockPayment())))
        XCTAssertTrue(ApplePayState.paymentAuthorized(payment: .createMockPayment()).canTransition(to: .cartSubmittedForCompletion(redirectURL: URL(string: "https://example.com")!)))
        XCTAssertTrue(ApplePayState.cartSubmittedForCompletion(redirectURL: URL(string: "https://example.com")!).canTransition(to: .completed))
        XCTAssertTrue(ApplePayState.completed.canTransition(to: .presentingCSK(url: URL(string: "https://example.com"))))
        XCTAssertTrue(ApplePayState.presentingCSK(url: URL(string: "https://example.com")).canTransition(to: .completed))
        XCTAssertTrue(ApplePayState.completed.canTransition(to: .reset))
        XCTAssertTrue(ApplePayState.reset.canTransition(to: .idle))
    }

    func testTypicalFailureFlow() {
        XCTAssertTrue(ApplePayState.idle.canTransition(to: .startPaymentRequest))
        XCTAssertTrue(ApplePayState.startPaymentRequest.canTransition(to: .appleSheetPresented))
        XCTAssertTrue(ApplePayState.appleSheetPresented.canTransition(to: .paymentAuthorizationFailed(error: MockError.testError)))
        XCTAssertTrue(ApplePayState.paymentAuthorizationFailed(error: MockError.testError).canTransition(to: .completed))
        XCTAssertTrue(ApplePayState.completed.canTransition(to: .presentingCSK(url: URL(string: "https://example.com"))))
        XCTAssertTrue(ApplePayState.presentingCSK(url: URL(string: "https://example.com")).canTransition(to: .completed))
        XCTAssertTrue(ApplePayState.completed.canTransition(to: .reset))
        XCTAssertTrue(ApplePayState.reset.canTransition(to: .idle))
    }

    func testInterruptFlow() {
        XCTAssertTrue(ApplePayState.idle.canTransition(to: .startPaymentRequest))
        XCTAssertTrue(ApplePayState.startPaymentRequest.canTransition(to: .appleSheetPresented))
        XCTAssertTrue(ApplePayState.appleSheetPresented.canTransition(to: .interrupt(reason: .currencyChanged)))
        XCTAssertTrue(ApplePayState.interrupt(reason: .currencyChanged).canTransition(to: .completed))
        XCTAssertTrue(ApplePayState.completed.canTransition(to: .presentingCSK(url: URL(string: "https://example.com"))))
        XCTAssertTrue(ApplePayState.presentingCSK(url: URL(string: "https://example.com")).canTransition(to: .completed))
        XCTAssertTrue(ApplePayState.completed.canTransition(to: .reset))
        XCTAssertTrue(ApplePayState.reset.canTransition(to: .idle))
    }

    func testUserCancelFlow() {
        XCTAssertTrue(ApplePayState.idle.canTransition(to: .startPaymentRequest))
        XCTAssertTrue(ApplePayState.startPaymentRequest.canTransition(to: .appleSheetPresented))
        XCTAssertTrue(ApplePayState.appleSheetPresented.canTransition(to: .completed))
        XCTAssertTrue(ApplePayState.completed.canTransition(to: .reset))
        XCTAssertTrue(ApplePayState.reset.canTransition(to: .idle))
    }

    // MARK: - Edge Case Tests

    func testSelfTransitionsAreInvalid() {
        let nonErrorStates: [ApplePayState] = [
            .idle,
            .startPaymentRequest,
            .appleSheetPresented,
            .paymentAuthorized(payment: .createMockPayment()),
            .paymentAuthorizationFailed(error: MockError.testError),
            .cartSubmittedForCompletion(redirectURL: URL(string: "https://example.com")!),
            .interrupt(reason: .currencyChanged),
            .presentingCSK(url: URL(string: "https://example.com")),
            .completed,
            .reset
        ]

        for state in nonErrorStates {
            XCTAssertFalse(state.canTransition(to: state), "State \(state) should not allow self-transition")
        }

        let errorStates: [ApplePayState] = [
            .unexpectedError(error: MockError.testError),
            .terminalError(error: MockError.testError)
        ]

        for errorState in errorStates {
            XCTAssertTrue(
                errorState.canTransition(to: ApplePayState.unexpectedError(error: MockError.networkError)),
                "Error state \(errorState) should allow transition to other unexpectedError"
            )
            XCTAssertTrue(
                errorState.canTransition(to: ApplePayState.terminalError(error: MockError.networkError)),
                "Error state \(errorState) should allow transition to other terminalError"
            )
        }
    }

    func testInterruptReasonVariations() {
        let interruptReasons: [ErrorHandler.InterruptReason] = [
            .currencyChanged,
            .outOfStock,
            .dynamicTax,
            .cartNotReady,
            .cartThrottled,
            .notEnoughStock,
            .other,
            .unhandled
        ]

        for reason in interruptReasons {
            let interruptState = ApplePayState.interrupt(reason: reason)
            XCTAssertTrue(
                interruptState.canTransition(to: .completed),
                "Interrupt with reason \(reason) should allow transition to completed"
            )
            XCTAssertFalse(
                interruptState.canTransition(to: .idle),
                "Interrupt with reason \(reason) should not allow transition to idle"
            )
        }
    }
}

// MARK: - Mock Types

@available(iOS 17.0, *)
enum MockError: Error, Equatable {
    case testError
    case networkError
    case authenticationError
}

// MARK: - Mock PKPayment

@available(iOS 17.0, *)
class MockPKPayment: PKPayment {
    // Mock implementation for testing
    // PKPayment doesn't have public initializers, so we create a simple mock subclass
}

@available(iOS 17.0, *)
extension PKPayment {
    static func createMockPayment() -> PKPayment {
        return MockPKPayment()
    }
}
