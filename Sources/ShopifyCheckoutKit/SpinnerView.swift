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

class SpinnerView: UIView {
	private lazy var imageView: UIImageView = {
		let view = UIImageView(image: UIImage(
			named: "spinner", in: .module, with: nil
		))
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}()

	private let animationKey = "SpinnerView.rotation"

	override init(frame: CGRect) {
		super.init(frame: frame)

		addSubview(imageView)

		NSLayoutConstraint.activate([
			widthAnchor.constraint(equalToConstant: 64),
			heightAnchor.constraint(equalToConstant: 64),
			imageView.topAnchor.constraint(equalTo: topAnchor),
			imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
			imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
			imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
		])

		imageView.tintColor = ShopifyCheckoutKit.configuration.spinnerColor

		isHidden = true
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func startAnimating() {
		isHidden = false

		let rotation = CABasicAnimation(
			keyPath: "transform.rotation"
		)
		rotation.fromValue = 0
		rotation.toValue = Double.pi * 2
		rotation.duration = 0.5
		rotation.repeatCount = .greatestFiniteMagnitude

		layer.add(rotation, forKey: animationKey)
	}

	func stopAnimating() {
		isHidden = true

		layer.removeAnimation(forKey: animationKey)
	}
}
