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

import UIKit

class PreloadBanner {
	static let shared = PreloadBanner()
	private let bannerView: UIView
	private let label: UILabel
	private let height: CGFloat = 30
	private let yVisible: CGFloat = UIScreen.main.bounds.height - 113
	private let yHidden: CGFloat = UIScreen.main.bounds.height - 108

	private init() {
		bannerView = UIView(
			frame: CGRect(
				x: 0,
				y: yHidden,
				width: UIScreen.main.bounds.width,
				height: height
			)
		)
		bannerView.backgroundColor = .systemGreen
		bannerView.isHidden = true
		bannerView.alpha = 0

		label = UILabel(frame: bannerView.bounds)
		label.textAlignment = .center
		label.textColor = .white
		label.font = UIFont.systemFont(ofSize: 14)

		bannerView.addSubview(label)

		let firstConnectedScene = UIApplication.shared.connectedScenes.first

		if let windowScene = firstConnectedScene as? UIWindowScene, let window = windowScene.windows.first {
			window.addSubview(bannerView)
		}
	}

	func showBanner(withText text: String) {
		label.text = text

		UIView.animate(withDuration: 0.3) {
			self.bannerView.frame.origin.y = self.yVisible
			self.bannerView.alpha = 1
			self.bannerView.isHidden = false
		}

		// Schedule a timer to hide the banner after 3 seconds
		DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
			self.hideBanner()
		}
	}

	func hideBanner() {
		UIView.animate(withDuration: 0.3, animations: {
			self.bannerView.frame.origin.y = self.yHidden
			self.bannerView.alpha = 0
		}, completion: {(_ completed) in
			self.bannerView.isHidden = true
		})
	}
}
