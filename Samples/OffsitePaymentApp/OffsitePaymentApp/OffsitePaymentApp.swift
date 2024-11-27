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

import SwiftUI

@main
struct OffsitePaymentApp: App {
    @State private var showPaymentSheet: Bool = false
    @State private var paymentToken: String?
    @State private var paymentStatus: PaymentStatus?
    @State private var timer: Timer?

    enum PaymentStatus {
        case confirmed, cancelled
    }

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 15) {
                Image(systemName: iconForStatus())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 30)
                    .foregroundColor(colorForStatus())

                Text(statusText())
					.font(.title3)
                    .fontWeight(.bold)
					.lineLimit(1)

				Text(descriptionText())
					.font(.body)
					.lineLimit(3)
					.multilineTextAlignment(.center)
					.padding(5)

                Button(action: {
                    paymentToken = "SIMULATED_TOKEN"
                    showPaymentSheet = true
                }) {
                    Text("Simulate Payment")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
				}.padding(.horizontal)
            }
            .padding(30)
            .background(Color(.systemGroupedBackground))
            .cornerRadius(20)
            .shadow(
				color: Color.black.opacity(0.1),
				radius: 10,
				x: 0,
				y: 10
			)
			.padding()
            .onOpenURL(perform: handleOpenURL)
			.sheet(isPresented: $showPaymentSheet, onDismiss: {
				startTimer()
			}) {
                PaymentConfirmationView(token: $paymentToken, onConfirm: {
                    paymentStatus = .confirmed
                }, onCancel: {
                    paymentStatus = .cancelled
                })
                .presentationDetents([.medium, .large])
				.navigationTitle("Payment Confirmation")
				.navigationBarTitleDisplayMode(.inline)
				.presentationDragIndicator(.visible)
            }.padding(30)
        }
    }

    private func handleOpenURL(_ url: URL) {
        print("Received URL: \(url.absoluteString)")

        if url.scheme == "offsitepayment" {
            let path = url.path

            if !path.isEmpty {
                print("Path check resolved, token: \(path.dropFirst())")
                paymentToken = String(path.dropFirst())
                print("paymentToken", paymentToken!)
                showPaymentSheet = true
            }
        } else {
            print("Scheme does not match")
        }
    }

    private func iconForStatus() -> String {
        switch paymentStatus {
        case .confirmed:
            return "checkmark.circle.fill"
        case .cancelled:
            return "xmark.circle.fill"
        default:
            return "creditcard.fill"
        }
    }

    private func colorForStatus() -> Color {
        switch paymentStatus {
        case .confirmed:
            return .green
        case .cancelled:
            return .red
        default:
            return .blue
        }
    }

    private func statusText() -> String {
        switch paymentStatus {
        case .confirmed:
            return "Payment Confirmed"
        case .cancelled:
            return "Payment Cancelled"
        default:
            return "Offsite Payment"
        }
    }

    private func descriptionText() -> String {
        switch paymentStatus {
        case .confirmed:
            return "Redirecting..."
        case .cancelled:
            return "Payment cancelled. Redirecting..."
        default:
            return "This app is intended to simulate the experience of an offiste payment app."
        }
    }

	private func startTimer() {
		// Invalidate any existing timer before creating a new one
		timer?.invalidate()
		timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
			resetState()
		}
	}

	private func stopTimer() {
		timer?.invalidate()
		timer = nil
	}

	private func resetState() {
		showPaymentSheet = false
		paymentToken = nil
		paymentStatus = nil
	}
}

struct PaymentConfirmationView: View {
    @Binding var token: String?
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            Text("Payment In Progress")
                .font(.title2)
                .fontWeight(.bold)

            Text("Processing your payment with token:")
                .font(.body)

            Text(token ?? "TOKEN MISSING")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            HStack(spacing: 20) {
                Button(action: {
                    print("Payment cancelled for token: \(token ?? "TOKEN MISSING")")
                    onCancel()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    print("Payment confirmed for token: \(token ?? "TOKEN MISSING")")
                    onConfirm()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Confirm")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .padding(40)
    }
}

struct OffsitePaymentApp_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(false, Optional("exampleToken123")) { showPaymentSheet, paymentToken in
            VStack(spacing: 15) {
                Image(systemName: "creditcard.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 30)
                    .foregroundColor(.blue)
                    .padding()

                Text("Offsite Payment")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding()

                Button(action: {
                    paymentToken.wrappedValue = "exampleToken123"
                    showPaymentSheet.wrappedValue = true
                }) {
                    Text("Simulate Payment")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 10)
            .padding(30)
            .sheet(isPresented: showPaymentSheet) {
                if let token = paymentToken.wrappedValue {
                    PaymentConfirmationView(token: .constant(token), onConfirm: {
                        print("Payment confirmed")
                    }, onCancel: {
                        print("Payment cancelled")
                    })
                }
            }
        }
    }
}

// A utility to simulate @State variables in SwiftUI previews
struct StatefulPreviewWrapper<Value1, Value2, Content: View>: View {
    @State private var value1: Value1
    @State private var value2: Value2
    private let content: (Binding<Value1>, Binding<Value2>) -> Content

    init(_ value1: Value1, _ value2: Value2, @ViewBuilder content: @escaping (Binding<Value1>, Binding<Value2>) -> Content) {
        _value1 = State(initialValue: value1)
        _value2 = State(initialValue: value2)
        self.content = content
    }

    var body: some View {
        content($value1, $value2)
    }
}
