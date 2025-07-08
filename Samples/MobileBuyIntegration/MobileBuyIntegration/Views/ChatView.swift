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

struct ChatView: View {
    @ObservedObject var cartManager: CartManager = .shared
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "Hi! I can help you complete your purchase. Would you like to checkout now?", isUser: false)
    ]
    @State private var showingInlineCheckout = false
    @State private var messageText = ""
    @State private var checkoutCompleted = false
    @State private var checkoutError: String? = nil
    @State private var isCheckoutLoading = true

    var body: some View {
        VStack(spacing: 0) {
            // Chat messages
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        ChatMessageRow(message: message)
                    }

                    // Inline checkout view
                    if showingInlineCheckout, let checkoutUrl = cartManager.cart?.checkoutUrl {
                        CheckoutMessageView(
                            checkoutUrl: checkoutUrl,
                            isLoading: $isCheckoutLoading
                        ) { result in
                            switch result {
                            case .completed:
                                checkoutCompleted = true
                                showingInlineCheckout = false
                                messages.append(ChatMessage(text: "✅ Checkout completed successfully!", isUser: false))
                            case .cancelled:
                                showingInlineCheckout = false
                                messages.append(ChatMessage(text: "Checkout was cancelled. Let me know if you'd like to try again.", isUser: false))
                            case let .failed(error):
                                checkoutError = error.localizedDescription
                                showingInlineCheckout = false
                                messages.append(ChatMessage(text: "❌ Checkout failed: \(error.localizedDescription)", isUser: false))
                            }
                        }
                    }
                }
                .padding()
            }

            // Quick actions
            if !showingInlineCheckout {
                QuickActionsView { action in
                    switch action {
                    case .checkout:
                        isCheckoutLoading = true
                        showingInlineCheckout = true
                    case .help:
                        messages.append(ChatMessage(text: "I need help with my order", isUser: true))
                        messages.append(ChatMessage(text: "I'm here to help! What would you like to know?", isUser: false))
                    case .support:
                        messages.append(ChatMessage(text: "Contact support", isUser: true))
                        messages.append(ChatMessage(text: "You can reach our support team at support@example.com", isUser: false))
                    }
                }
            }

            // Message input
            MessageInputView(text: $messageText) {
                if !messageText.isEmpty {
                    messages.append(ChatMessage(text: messageText, isUser: true))
                    messageText = ""

                    // Simple bot response
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        messages.append(ChatMessage(text: "Thanks for your message! How can I help you today?", isUser: false))
                    }
                }
            }
        }
        .navigationTitle("Chat Support")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Checkout Complete", isPresented: $checkoutCompleted) {
            Button("OK") {}
        }
        .alert("Checkout Error", isPresented: Binding<Bool>(
            get: { checkoutError != nil },
            set: { _ in checkoutError = nil }
        )) {
            Button("OK") {}
        } message: {
            Text(checkoutError ?? "")
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ChatMessageRow: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .frame(maxWidth: 250, alignment: .trailing)
            } else {
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .frame(maxWidth: 250, alignment: .leading)
                Spacer()
            }
        }
    }
}

struct CheckoutMessageView: View {
    let checkoutUrl: URL
    @Binding var isLoading: Bool
    let onResult: (CheckoutResult) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🛍️ Complete Your Purchase")
                .font(.headline)
                .padding(.horizontal)

            Text("You can complete your checkout right here:")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ZStack {
                InlineCheckout(
                    checkout: checkoutUrl,
                    autoResizeHeight: true,
                    onCheckoutComplete: { _ in
                        onResult(.completed)
                    },
                    onCheckoutCancel: {
                        onResult(.cancelled)
                    },
                    onCheckoutFail: { error in
                        onResult(.failed(error))
                    },
                    onHeightChange: { _ in
                        // Height changes are handled by the loading state
                    },
                    onLoadingStateChange: { loading in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isLoading = loading
                        }
                    }
                )
                .frame(maxWidth: .infinity)
                .opacity(isLoading ? 0 : 1)

                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                            .scaleEffect(1.0)

                        Text("Loading checkout...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .transition(.opacity)
                }
            }
            .frame(height: isLoading ? 80 : nil)
            .frame(minHeight: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

enum QuickAction {
    case checkout
    case help
    case support
}

enum CheckoutResult {
    case completed
    case cancelled
    case failed(Error)
}

struct QuickActionsView: View {
    let onAction: (QuickAction) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickActionButton(title: "🛒 Checkout", action: .checkout, onAction: onAction)
                QuickActionButton(title: "❓ Help", action: .help, onAction: onAction)
                QuickActionButton(title: "📞 Support", action: .support, onAction: onAction)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

struct QuickActionButton: View {
    let title: String
    let action: QuickAction
    let onAction: (QuickAction) -> Void

    var body: some View {
        Button(action: {
            onAction(action)
        }) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

struct MessageInputView: View {
    @Binding var text: String
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onSend()
                }

            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.blue)
            }
            .disabled(text.isEmpty)
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

#Preview {
    ChatView()
        .environmentObject(CartManager.shared)
}
