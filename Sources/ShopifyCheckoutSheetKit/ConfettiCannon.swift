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

enum ConfettiCannon {
	static func fire(in view: UIView) {
		let layerName = "shopify-confetti"

		view.layer.sublayers?.first(where: { layer in
			layer.name == layerName
		})?.removeFromSuperlayer()

		let config = ShopifyCheckoutSheetKit.configuration.confetti
		guard config.enabled, !config.particles.isEmpty else {
			return
		}

		let frame = view.frame

		let confetti = CAEmitterLayer()
		confetti.name = layerName
		confetti.frame = frame
		confetti.emitterPosition = CGPoint(x: frame.midX, y: frame.minY - 100)
		confetti.emitterSize = CGSize(width: frame.size.width, height: 100)
		confetti.emitterCells = config.particles.map {
			let cell = CAEmitterCell()

			cell.beginTime = 0.1
			cell.birthRate = 20
			cell.contents = $0.cgImage
			cell.emissionRange = CGFloat(Double.pi)
			cell.lifetime = 10
			cell.spin = 4
			cell.spinRange = 8
			cell.velocityRange = 100
			cell.yAcceleration = 150

			return cell
		}
		confetti.emitterShape = .rectangle
		confetti.beginTime = CACurrentMediaTime()

		view.layer.addSublayer(confetti)

		DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak confetti] in
			confetti?.birthRate = 0
		}
	}
}
