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

public struct CheckoutURL {
    public let url: URL

    init(from url: URL) {
        self.url = url
    }

    public func isMultipassURL() -> Bool {
        return url.absoluteString.contains("multipass")
    }

    public func isConfirmationPage() -> Bool {
		let pattern = "^(thank[_-]you)$"
		let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)

		for component in url.pathComponents {
			let range = NSRange(location: 0, length: component.utf16.count)
			if regex?.firstMatch(in: component, options: [], range: range) != nil {
				return true
			}
		}

		return false
	}

	public func isDeepLink() -> Bool {
		guard let scheme = url.scheme else {
			return false
		}

		return !["http", "https"].contains(scheme)
	}
}
