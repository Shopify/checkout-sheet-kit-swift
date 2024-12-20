import SwiftUI
@preconcurrency import WebKit

struct AuthenticationWebView: UIViewRepresentable {
    let url: URL?
    let authData: AuthData?
    let redirectUri: URLComponents?
    let completionHandler: (String?) -> Void

    func makeUIView(context: Context) -> LoginWebView {
        let webView = LoginWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: LoginWebView, context _: Context) {
        guard let nonNilUrl = url else {
            print("No authorization URL")
            return
        }

        let request = URLRequest(url: nonNilUrl)
        uiView.load(request)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            authData: authData,
            redirectUri: redirectUri,
            completionHandler: completionHandler
        )
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        private var authData: AuthData?
        private var redirectUri: URLComponents?
        private var completionHandler: (String?) -> Void

        init(authData: AuthData?, redirectUri: URLComponents?, completionHandler: @escaping (String?) -> Void) {
            self.completionHandler = completionHandler
            self.authData = authData
            self.redirectUri = redirectUri
        }

        func webView(_: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let nonNullRedirectUrl = redirectUri, let nonNullAuthData = authData else {
                decisionHandler(.allow)
                completionHandler(nil)
                return
            }

            if let url = action.request.url {
                guard let redirectComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                    decisionHandler(.allow)
                    return
                }

                guard redirectComponents.scheme == nonNullRedirectUrl.scheme else {
                    decisionHandler(.allow)
                    return
                }

                CustomerAccountClient.shared.handleAuthorizationCodeRedirect(url, authData: nonNullAuthData, callback: { token, _ in

                    guard let nonNilToken = token else {
                        print("login failed")

                        return
                    }
                    self.completionHandler(nonNilToken)
                })
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }
    }
}
