@testable import ShopifyCheckoutSheetKit
import WebKit
import XCTest

class CheckoutBridgeTests: XCTestCase {
    func testReturnsStandardUserAgent() {
        let version = ShopifyCheckoutSheetKit.version
        let schemaVersion = MetaData.schemaVersion
        XCTAssertEqual(CheckoutBridge.applicationName, "ShopifyCheckoutSDK/\(version) (\(schemaVersion);automatic;standard)")
    }

    func testReturnsRecoveryUserAgent() {
        let version = ShopifyCheckoutSheetKit.version
        XCTAssertEqual(CheckoutBridge.recoveryAgent, "ShopifyCheckoutSDK/\(version) (noconnect;automatic;standard_recovery)")
    }

    func testReturnsUserAgentWithCustomPlatformSuffix() {
        let version = ShopifyCheckoutSheetKit.version
        let schemaVersion = MetaData.schemaVersion
        ShopifyCheckoutSheetKit.configuration.platform = Platform.reactNative
        XCTAssertEqual(CheckoutBridge.applicationName, "ShopifyCheckoutSDK/\(version) (\(schemaVersion);automatic;standard) ReactNative")
        XCTAssertEqual(CheckoutBridge.recoveryAgent, "ShopifyCheckoutSDK/\(version) (noconnect;automatic;standard_recovery) ReactNative")
        ShopifyCheckoutSheetKit.configuration.platform = nil
    }

    func testReturnsUserAgentWithEntryPoint() {
        let version = ShopifyCheckoutSheetKit.version
        let schemaVersion = MetaData.schemaVersion
        let applicationNameWithEntryPoint = CheckoutBridge.applicationName(entryPoint: .acceleratedCheckouts)
        let recoveryAgentWithEntryPoint = CheckoutBridge.recoveryAgent(entryPoint: .acceleratedCheckouts)

        XCTAssertEqual(applicationNameWithEntryPoint, "ShopifyCheckoutSDK/\(version) (\(schemaVersion);automatic;standard) AcceleratedCheckouts")
        XCTAssertEqual(recoveryAgentWithEntryPoint, "ShopifyCheckoutSDK/\(version) (noconnect;automatic;standard_recovery) AcceleratedCheckouts")
    }

    func testReturnsUserAgentWithEntryPointAndPlatform() {
        let version = ShopifyCheckoutSheetKit.version
        let schemaVersion = MetaData.schemaVersion
        ShopifyCheckoutSheetKit.configuration.platform = Platform.reactNative

        let applicationNameWithEntryPoint = CheckoutBridge.applicationName(entryPoint: .acceleratedCheckouts)
        let recoveryAgentWithEntryPoint = CheckoutBridge.recoveryAgent(entryPoint: .acceleratedCheckouts)

        XCTAssertEqual(applicationNameWithEntryPoint, "ShopifyCheckoutSDK/\(version) (\(schemaVersion);automatic;standard) ReactNative AcceleratedCheckouts")
        XCTAssertEqual(recoveryAgentWithEntryPoint, "ShopifyCheckoutSDK/\(version) (noconnect;automatic;standard_recovery) ReactNative AcceleratedCheckouts")

        ShopifyCheckoutSheetKit.configuration.platform = nil
    }

    func testInstrumentationPayloadToBridgeEvent() {
        let payload = InstrumentationPayload(name: "test", value: 1, type: .histogram)
        let jsonString = payload.toBridgeEvent()
        XCTAssertNotNil(jsonString)

        if let jsonData = jsonString?.data(using: .utf8) {
            let decodedPayload = try? JSONDecoder().decode(SdkToWebEvent<InstrumentationPayload>.self, from: jsonData)
            XCTAssertNotNil(decodedPayload)
            XCTAssertEqual(decodedPayload?.detail.name, "test")
            XCTAssertEqual(decodedPayload?.detail.value, 1)
            XCTAssertEqual(decodedPayload?.detail.type, .histogram)
        }
    }

    func testSendMessageShouldCallEvaluateJavaScriptPresented() {
        let webView = MockWebView()
        webView.expectedScript = expectedPresentedScript()
        let evaluateJavaScriptExpectation = expectation(
            description: "evaluateJavaScript was called"
        )
        webView.evaluateJavaScriptExpectation = evaluateJavaScriptExpectation

        CheckoutBridge.sendMessage(webView, messageName: "presented", messageBody: nil)

        wait(for: [evaluateJavaScriptExpectation], timeout: 2)
    }

    func testSendMessageWithPayloadEvaulatesJavaScript() {
        let webView = MockWebView()
        webView.expectedScript = expectedPayloadScript()
        let evaluateJavaScriptExpectation = expectation(
            description: "evaluateJavaScript was called"
        )
        webView.evaluateJavaScriptExpectation = evaluateJavaScriptExpectation

        CheckoutBridge.sendMessage(webView, messageName: "payload", messageBody: "{\"one\": true}")

        wait(for: [evaluateJavaScriptExpectation], timeout: 2)
    }

    private func expectedPresentedScript() -> String {
        return """
        if (window.MobileCheckoutSdk && window.MobileCheckoutSdk.dispatchMessage) {
        	window.MobileCheckoutSdk.dispatchMessage('presented');
        } else {
        	window.addEventListener('mobileCheckoutBridgeReady', function () {
        		window.MobileCheckoutSdk.dispatchMessage('presented');
        	}, {passive: true, once: true});
        }
        """
    }

    private func expectedPayloadScript() -> String {
        return """
        if (window.MobileCheckoutSdk && window.MobileCheckoutSdk.dispatchMessage) {
        	window.MobileCheckoutSdk.dispatchMessage('payload', {"one": true});
        } else {
        	window.addEventListener('mobileCheckoutBridgeReady', function () {
        		window.MobileCheckoutSdk.dispatchMessage('payload', {"one": true});
        	}, {passive: true, once: true});
        }
        """
    }
}
