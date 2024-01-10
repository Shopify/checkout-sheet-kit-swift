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

import WebKit

class MockNavigationAction: WKNavigationAction {
	private let mockRequest: URLRequest

	override var request: URLRequest {
		return mockRequest
	}

	init(url: URL) {
		self.mockRequest = URLRequest(url: url)
		super.init()
	}
}

class MockExternalNavigationAction: WKNavigationAction {
	private let mockRequest: URLRequest
	private let navType: WKNavigationType

	override var request: URLRequest {
		return mockRequest
	}

	override var navigationType: WKNavigationType {
		return self.navType
	}

	override var targetFrame: WKFrameInfo? {
		return nil
	}

	init(url: URL, navigationType: WKNavigationType = .linkActivated) {
		self.mockRequest = URLRequest(url: url)
		self.navType = navigationType
		super.init()
	}
}
