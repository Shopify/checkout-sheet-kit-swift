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

class ProgressBarView: UIView {
	internal lazy var progressBar: UIProgressView = {
		let progressBar = UIProgressView(progressViewStyle: .bar)
		progressBar.setProgress(0.0, animated: false)
		progressBar.translatesAutoresizingMaskIntoConstraints = false
		return progressBar
	}()

	private var progressAnimation: UIViewPropertyAnimator?

	override init(frame: CGRect) {
		super.init(frame: frame)

		addSubview(progressBar)

		NSLayoutConstraint.activate([
			progressBar.topAnchor.constraint(equalTo: topAnchor),
			progressBar.heightAnchor.constraint(equalToConstant: 1)
		])

		/// Use tintColor, but fallback to deprecated spinnerColor
		progressBar.tintColor = ShopifyCheckoutSheetKit.configuration.tintColor ?? ShopifyCheckoutSheetKit.configuration.spinnerColor
	}

	override func didMoveToSuperview() {
		super.didMoveToSuperview()

		if let superview = superview {
			progressBar.leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor).isActive = true
			progressBar.trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor).isActive = true
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func setProgress(_ progress: Float, animated: Bool = false) {
		if progress > progressBar.progress {
			progressBar.setProgress(progress, animated: animated)
		}
	}

	func startAnimating() {
		alpha = 1
		isHidden = false
	}

	func stopAnimating() {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			UIView.animate(withDuration: 0.2, animations: {
				self.alpha = 0
			}, completion: { _ in
				self.isHidden = true
				self.alpha = 1
				self.progressBar.setProgress(0.0, animated: false)
			})
		})
	}
}
