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
import WebKit

struct CustomerAccountLoginView: UIViewRepresentable {
    let authorizationURL: URL
    let callbackScheme: String
    let onCodeReceived: (String) -> Void
    let onCancel: () -> Void

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: authorizationURL))
        return webView
    }

    func updateUIView(_: WKWebView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(callbackScheme: callbackScheme, onCodeReceived: onCodeReceived, onCancel: onCancel)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let callbackScheme: String
        let onCodeReceived: (String) -> Void
        let onCancel: () -> Void

        init(callbackScheme: String, onCodeReceived: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
            self.callbackScheme = callbackScheme
            self.onCodeReceived = onCodeReceived
            self.onCancel = onCancel
        }

        func webView(
            _: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if url.scheme == callbackScheme, url.host == "callback" {
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                      let queryItems = components.queryItems
                else {
                    decisionHandler(.cancel)
                    onCancel()
                    return
                }

                let queryDict = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item -> (String, String)? in
                    guard let value = item.value else { return nil }
                    return (item.name, value)
                })

                if let code = queryDict["code"] {
                    onCodeReceived(code)
                } else {
                    onCancel()
                }

                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
            if (error as NSError).code == NSURLErrorCancelled {
                return
            }
            print("WebView navigation failed: \(error)")
        }

        func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
            if (error as NSError).code == NSURLErrorCancelled {
                return
            }
            print("WebView provisional navigation failed: \(error)")
        }
    }
}

struct LoginSheetView: View {
    @ObservedObject var accountManager = CustomerAccountManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var authorizationURL: URL?

    private var callbackScheme: String? {
        guard let shopId = InfoDictionary.shared.customerAccountApiShopId else { return nil }
        return "shop.\(shopId).app"
    }

    var body: some View {
        NavigationView {
            Group {
                if let url = authorizationURL, let scheme = callbackScheme {
                    CustomerAccountLoginView(
                        authorizationURL: url,
                        callbackScheme: scheme,
                        onCodeReceived: { code in
                            Task {
                                do {
                                    try await accountManager.exchangeCodeForTokens(code: code)
                                    dismiss()
                                } catch {
                                    print("Failed to exchange code: \(error)")
                                }
                            }
                        },
                        onCancel: {
                            dismiss()
                        }
                    )
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            authorizationURL = accountManager.buildAuthorizationURL()
        }
    }
}
