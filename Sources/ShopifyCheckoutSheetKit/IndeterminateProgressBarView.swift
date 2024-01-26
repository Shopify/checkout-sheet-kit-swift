import UIKit

class IndeterminateProgressBarView: UIView {
	private lazy var progressBar: UIProgressView = {
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
			progressBar.heightAnchor.constraint(equalToConstant: 4),
		])

		progressBar.tintColor = ShopifyCheckoutSheetKit.configuration.spinnerColor
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
		if (progress > progressBar.progress) {
			progressBar.setProgress(progress, animated: animated)
		}
	}

	func startAnimating() {
		UIView.animate(withDuration: 0.2, animations: {
			self.isHidden = false
			self.alpha = 1
		})
	}

	func stopAnimating() {
		animateToCompletion {
			self.fadeOut()
		}
	}

	private func animateToCompletion(_ completion: @escaping () -> Void) {
		self.progressBar.setProgress(1.0, animated: true)
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
			completion()
		}
	}

	private func fadeOut() {
		UIView.animate(withDuration: 0.2, animations: {
			self.alpha = 0
		}) { _ in
			self.isHidden = true
			self.alpha = 0
			self.progressBar.setProgress(0.0, animated: false)
		}
	}
}
