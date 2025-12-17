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

import ShopifyCheckoutSheetKit
import SwiftUI
import UIKit

struct CheckoutWithPayButtonView: View {
    let checkoutURL: URL
    @Binding var isPresented: Bool
    let showPayButton: Bool

    @State private var submitAction: (() async throws -> CheckoutSubmitResponsePayload)?
    @State private var isSubmitting = false

    var body: some View {
        ZStack(alignment: .bottom) {
            CheckoutViewRepresentable(
                checkoutURL: checkoutURL,
                isPresented: $isPresented,
                onSubmitReady: { action in
                    submitAction = action
                }
            )

            if showPayButton {
                NativePayButtonOverlay(isSubmitting: $isSubmitting) {
                    guard let submit = submitAction else { return }
                    isSubmitting = true
                    Task {
                        do {
                            let response = try await submit()
                            print("Checkout submit succeeded: \(response)")
                        } catch {
                            print("Checkout submit failed: \(error)")
                        }
                        isSubmitting = false
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct NativePayButtonOverlay: View {
    @Binding var isSubmitting: Bool
    let onTap: () -> Void

    var body: some View {
        VStack {
            Button(action: onTap) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text("Pay now")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(ColorPalette.primaryColor))
                .cornerRadius(DesignSystem.cornerRadius)
            }
            .disabled(isSubmitting)
        }
        .padding()
        .background(Color.white)
    }
}

struct CheckoutViewRepresentable: UIViewControllerRepresentable {
    let checkoutURL: URL
    @Binding var isPresented: Bool
    var onSubmitReady: ((@escaping () async throws -> CheckoutSubmitResponsePayload) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> CheckoutViewController {
        let viewController = CheckoutViewController(
            checkout: checkoutURL,
            delegate: context.coordinator
        )
        context.coordinator.checkoutViewController = viewController
        return viewController
    }

    func updateUIViewController(_ uiViewController: CheckoutViewController, context: Context) {
        guard
            let webViewController = uiViewController
                .viewControllers
                .compactMap({ $0 as? CheckoutWebViewController })
                .first
        else {
            return
        }

        context.coordinator.webViewController = webViewController

        onSubmitReady? {
            try await webViewController.submit()
        }
    }

    class Coordinator: NSObject, CheckoutDelegate {
        var parent: CheckoutViewRepresentable
        weak var checkoutViewController: CheckoutViewController?
        weak var webViewController: CheckoutWebViewController?

        init(parent: CheckoutViewRepresentable) {
            self.parent = parent
        }

        func checkoutDidStart(event: CheckoutStartEvent) {
            print("Checkout started with cart ID: \(event.cart.id)")
        }

        func checkoutDidComplete(event: CheckoutCompleteEvent) {
            parent.isPresented = false
            print("Checkout completed with order ID: \(event.orderConfirmation.order.id)")
        }

        func checkoutDidCancel() {
            parent.isPresented = false
        }

        func checkoutDidFail(error: CheckoutError) {
            parent.isPresented = false
            print("Checkout failed: \(error)")
        }

        func checkoutDidClickLink(url: URL) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }

        func checkoutDidStartAddressChange(event: CheckoutAddressChangeStartEvent) {
            print("Address change started for type: \(event.addressType)")
        }

        func checkoutDidStartSubmit(event: CheckoutSubmitStartEvent) {
            print("Submit started")
        }

        func checkoutDidStartPaymentMethodChange(event: CheckoutPaymentMethodChangeStartEvent) {
            print("Payment method change started")
        }
    }
}
