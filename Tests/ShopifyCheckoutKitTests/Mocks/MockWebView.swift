import WebKit
import XCTest
@testable import ShopifyCheckoutKit

class MockWebView: WKWebView {

	var expectedScript = ""

	var evaluateJavaScriptExpectation: XCTestExpectation?

	override func evaluateJavaScript(_ javaScriptString: String) async throws -> Any {
		if javaScriptString == expectedScript {
			evaluateJavaScriptExpectation?.fulfill()
		}
		return true
	}

}
