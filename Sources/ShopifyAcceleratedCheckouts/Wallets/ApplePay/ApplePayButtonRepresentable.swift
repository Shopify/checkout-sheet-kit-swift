import PassKit
import SwiftUI
import UIKit

@available(iOS 16.0, *)
struct ApplePayButtonRepresentable: UIViewRepresentable {
    typealias UIViewType = PKPaymentButton
    typealias Coordinator = Void

    let buttonType: PKPaymentButtonType
    let buttonStyle: PKPaymentButtonStyle
    let cornerRadius: CGFloat
    let action: @Sendable () -> Void

    func makeUIView(context _: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: buttonType, paymentButtonStyle: buttonStyle)
        button.cornerRadius = cornerRadius
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    func updateUIView(_ button: PKPaymentButton, context _: Context) {
        button.cornerRadius = cornerRadius
    }
}
