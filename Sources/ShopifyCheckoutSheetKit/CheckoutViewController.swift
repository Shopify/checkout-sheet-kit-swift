import SwiftUI
import UIKit

public class CheckoutViewController: UINavigationController {
    public init(checkout url: URL, bridgeHandler: (any CheckoutBridgeHandler)? = nil) {
        let rootViewController = CheckoutWebViewController(checkoutURL: url, bridgeHandler: bridgeHandler, entryPoint: nil)
        rootViewController.notifyPresented()
        super.init(rootViewController: rootViewController)
        presentationController?.delegate = rootViewController
    }

    package init(checkout url: URL, bridgeHandler: (any CheckoutBridgeHandler)? = nil, entryPoint: MetaData.EntryPoint? = nil) {
        let rootViewController = CheckoutWebViewController(checkoutURL: url, bridgeHandler: bridgeHandler, entryPoint: entryPoint)
        rootViewController.notifyPresented()
        super.init(rootViewController: rootViewController)
        presentationController?.delegate = rootViewController
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public struct CheckoutSheet: UIViewControllerRepresentable, CheckoutConfigurable {
    public typealias UIViewControllerType = CheckoutViewController

    var checkoutURL: URL
    var bridgeHandler: (any CheckoutBridgeHandler)?
    var onCancelAction: (() -> Void)?
    var onFailAction: ((CheckoutError) -> Void)?

    public init(checkout url: URL) {
        checkoutURL = url

        ShopifyCheckoutSheetKit.invalidateOnConfigurationChange = false
    }

    public func makeUIViewController(context _: Self.Context) -> CheckoutViewController {
        let viewController = CheckoutViewController(checkout: checkoutURL, bridgeHandler: bridgeHandler)
        configureWebViewController(viewController)
        return viewController
    }

    public func updateUIViewController(_ uiViewController: CheckoutViewController, context _: Self.Context) {
        configureWebViewController(uiViewController)
    }

    private func configureWebViewController(_ navigationController: CheckoutViewController) {
        guard
            let webViewController = navigationController
            .viewControllers
            .compactMap({ $0 as? CheckoutWebViewController })
            .first
        else {
            return
        }

        webViewController.bridgeHandler = bridgeHandler
        webViewController.checkoutView.bridgeHandler = bridgeHandler
        webViewController.onCancel = onCancelAction
        webViewController.onFail = onFailAction
    }

    @discardableResult public func connect(_ handler: any CheckoutBridgeHandler) -> Self {
        var copy = self
        copy.bridgeHandler = handler
        return copy
    }

    @discardableResult public func onCancel(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onCancelAction = action
        return copy
    }

    @discardableResult public func onFail(_ action: @escaping (CheckoutError) -> Void) -> Self {
        var copy = self
        copy.onFailAction = action
        return copy
    }
}

public protocol CheckoutConfigurable {
    func backgroundColor(_ color: UIColor) -> Self
    func colorScheme(_ colorScheme: ShopifyCheckoutSheetKit.Configuration.ColorScheme) -> Self
    func tintColor(_ color: UIColor) -> Self
    func title(_ title: String) -> Self
    func closeButtonTintColor(_ color: UIColor?) -> Self
}

extension CheckoutConfigurable {
    @discardableResult public func backgroundColor(_ color: UIColor) -> Self {
        ShopifyCheckoutSheetKit.configuration.backgroundColor = color
        return self
    }

    @discardableResult public func colorScheme(_ colorScheme: ShopifyCheckoutSheetKit.Configuration.ColorScheme) -> Self {
        ShopifyCheckoutSheetKit.configuration.colorScheme = colorScheme
        return self
    }

    @discardableResult public func tintColor(_ color: UIColor) -> Self {
        ShopifyCheckoutSheetKit.configuration.tintColor = color
        return self
    }

    @discardableResult public func title(_ title: String) -> Self {
        ShopifyCheckoutSheetKit.configuration.title = title
        return self
    }

    @discardableResult public func closeButtonTintColor(_ color: UIColor?) -> Self {
        ShopifyCheckoutSheetKit.configuration.closeButtonTintColor = color
        return self
    }
}
