//
//  File.swift
//  
//
//  Created by Mark Murray on 26/10/2023.
//

import Foundation
import UIKit

class NotificationBanner: UIView {
	static let labelLeftMarging = CGFloat(16)
	static let labelTopMargin = CGFloat(24)
	static let animateDuration = 0.5
	static let bannerAppearanceDuration: TimeInterval = 2

	private lazy var bannerView: UIView = {
		let bannerView = UIView(frame: CGRect(x: 0, y: 0, width: 700, height: 64))
		bannerView.layer.opacity = 1
		bannerView.backgroundColor = UIColor.systemBlue
		bannerView.translatesAutoresizingMaskIntoConstraints = false

		let label = UILabel(frame: CGRect.zero)
		label.textColor = UIColor.white
		label.numberOfLines = 0
		label.text = "Preloading has completed"
		label.translatesAutoresizingMaskIntoConstraints = false

		bannerView.addSubview(label)

		return bannerView
	}()

	override init(frame: CGRect) {
		super.init(frame: frame)

		addSubview(bannerView)

		NSLayoutConstraint.activate([
			widthAnchor.constraint(equalToConstant: 64),
			heightAnchor.constraint(equalToConstant: 64),
			bannerView.topAnchor.constraint(equalTo: topAnchor),
			bannerView.leadingAnchor.constraint(equalTo: leadingAnchor),
			bannerView.trailingAnchor.constraint(equalTo: trailingAnchor),
			bannerView.bottomAnchor.constraint(equalTo: bottomAnchor)
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}


}
