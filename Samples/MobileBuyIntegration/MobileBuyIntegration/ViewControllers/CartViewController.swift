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

import ApolloAPI
import Combine
@preconcurrency import ShopifyAcceleratedCheckouts
@preconcurrency import ShopifyCheckoutSheetKit
import SwiftUI
import UIKit

typealias CartLineVariant = Storefront.CartLineFragment.Merchandise.AsProductVariant

class CartItemCell: UITableViewCell {
    let titleLabel = UILabel()
    let vendorLabel = UILabel()
    let quantityLabel = UILabel()
    let decreaseButton = UIButton(type: .system)
    let increaseButton = UIButton(type: .system)
    let labelStackView = UIStackView()
    let quantityStackView = UIStackView()
    let activityIndicator = UIActivityIndicatorView()

    var onQuantityChange: ((_ quantity: Int) -> Void)?

    private var quantity: Int = 0 {
        didSet {
            quantityLabel.text = "\(quantity)"
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        labelStackView.axis = .vertical
        labelStackView.alignment = .leading
        labelStackView.spacing = 4
        labelStackView.translatesAutoresizingMaskIntoConstraints = false

        quantityStackView.axis = .horizontal
        quantityStackView.alignment = .center
        quantityStackView.spacing = 8
        quantityStackView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.numberOfLines = 0
        vendorLabel.numberOfLines = 0
        vendorLabel.textColor = .systemBlue
        vendorLabel.font = UIFont.systemFont(ofSize: 12)

        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(vendorLabel)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true

        quantityStackView.addArrangedSubview(decreaseButton)
        quantityStackView.addArrangedSubview(activityIndicator)
        quantityStackView.addArrangedSubview(quantityLabel)
        quantityStackView.addArrangedSubview(increaseButton)

        decreaseButton.setTitle("-", for: .normal)
        increaseButton.setTitle("+", for: .normal)
        decreaseButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        increaseButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)

        activityIndicator.widthAnchor.constraint(equalToConstant: 20).isActive = true
        quantityLabel.widthAnchor.constraint(equalToConstant: 20).isActive = true
        quantityLabel.textAlignment = .center

        decreaseButton.addTarget(self, action: #selector(decreaseQuantity), for: .touchUpInside)
        increaseButton.addTarget(self, action: #selector(increaseQuantity), for: .touchUpInside)

        contentView.addSubview(labelStackView)
        contentView.addSubview(quantityStackView)

        NSLayoutConstraint.activate([
            labelStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            labelStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            labelStackView.trailingAnchor.constraint(equalTo: quantityStackView.leadingAnchor, constant: -16),

            quantityStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            quantityStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    @objc private func decreaseQuantity() {
        if quantity > 1 {
            quantity -= 1
            onQuantityChange?(quantity)
        }
    }

    @objc private func increaseQuantity() {
        quantity += 1
        onQuantityChange?(quantity)
    }

    func showLoading(_ loading: Bool) {
        if loading {
            quantityLabel.isHidden = true
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            quantityLabel.isHidden = false
        }
    }

    func configure(with variant: CartLineVariant, quantity: Int) {
        titleLabel.text = variant.product.title
        vendorLabel.text = variant.product.vendor
        self.quantity = quantity
    }
}

@MainActor
class CartViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: Properties

    private var bag = Set<AnyCancellable>()

    private var emptyView: UIView!
    private var tableView: UITableView!
    private var buttonContainerView: UIView!
    private var buttonStackView: UIStackView!
    private var checkoutButton: UIButton!
    private var acceleratedCheckoutHostingController: UIHostingController<AnyView>?

    // MARK: Initializers

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Reset", style: .plain, target: self, action: #selector(resetCart)
        )

        CartManager.shared.$cart
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.cartDidUpdate()
            }
            .store(in: &bag)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UIViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        tableView.register(
            UITableViewCell.self, forCellReuseIdentifier: "CartItemCell"
        )
        tableView.allowsSelection = false
        tableView.rowHeight = 80

        cartDidUpdate()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        emptyView = UIView()
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.backgroundColor = .systemBackground

        let emptyLabel = UILabel()
        emptyLabel.text = "Your cart is empty"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(emptyLabel)

        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self

        buttonContainerView = UIView()
        buttonContainerView.backgroundColor = .systemBackground

        buttonStackView = UIStackView()
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .vertical
        buttonStackView.spacing = DesignSystem.buttonSpacing
        buttonStackView.alignment = .fill
        buttonStackView.distribution = .fill

        checkoutButton = UIButton(type: .system)
        checkoutButton.translatesAutoresizingMaskIntoConstraints = false
        checkoutButton.setTitle("Check out", for: .normal)
        checkoutButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        checkoutButton.backgroundColor = ColorPalette.primaryColor
        checkoutButton.setTitleColor(.white, for: .normal)
        checkoutButton.layer.cornerRadius = DesignSystem.cornerRadius
        checkoutButton.layer.masksToBounds = true
        checkoutButton.contentHorizontalAlignment = .fill
        checkoutButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        checkoutButton.addTarget(self, action: #selector(presentCheckout), for: .touchUpInside)

        setupCheckoutButtonContent()

        buttonStackView.addArrangedSubview(checkoutButton)

        buttonContainerView.addSubview(buttonStackView)

        tableView.tableFooterView = buttonContainerView

        view.addSubview(emptyView)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            emptyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            buttonStackView.leadingAnchor.constraint(equalTo: buttonContainerView.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: buttonContainerView.trailingAnchor, constant: -16),
            buttonStackView.topAnchor.constraint(equalTo: buttonContainerView.topAnchor, constant: 32),
            buttonStackView.bottomAnchor.constraint(equalTo: buttonContainerView.bottomAnchor, constant: -16)
        ])

        setupAcceleratedCheckoutButtons()

        updateButtonContainerSize()
    }

    private func setupCheckoutButtonContent() {
        checkoutButton.subviews.forEach { $0.removeFromSuperview() }

        checkoutButton.backgroundColor = checkoutButton.isEnabled ? ColorPalette.primaryColor : .lightGray

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.isUserInteractionEnabled = false
        checkoutButton.addSubview(containerView)

        let checkoutLabel = UILabel()
        checkoutLabel.text = "Check out"
        checkoutLabel.font = UIFont.boldSystemFont(ofSize: 17)
        checkoutLabel.textColor = checkoutButton.isEnabled ? .white : .darkGray
        checkoutLabel.translatesAutoresizingMaskIntoConstraints = false

        let totalLabel = UILabel()
        totalLabel.font = UIFont.boldSystemFont(ofSize: 14)
        totalLabel.textColor = checkoutButton.isEnabled ? .white : .darkGray
        totalLabel.textAlignment = .right
        totalLabel.translatesAutoresizingMaskIntoConstraints = false

        if let amount = CartManager.shared.cart?.cost.totalAmount,
           let total = MoneyV2(amount: amount.amount, currencyCode: amount.currencyCode).formattedString()
        {
            totalLabel.text = total
        } else {
            totalLabel.text = ""
        }

        containerView.addSubview(checkoutLabel)
        containerView.addSubview(totalLabel)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: checkoutButton.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: checkoutButton.trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: checkoutButton.topAnchor, constant: 16),
            containerView.bottomAnchor.constraint(equalTo: checkoutButton.bottomAnchor, constant: -16),

            checkoutLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            checkoutLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            totalLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            totalLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            totalLabel.leadingAnchor.constraint(greaterThanOrEqualTo: checkoutLabel.trailingAnchor, constant: 8)
        ])

        checkoutButton.setTitle("", for: .normal)
    }

    private func setupAcceleratedCheckoutButtons() {
        guard let cartId = CartManager.shared.cart?.id else { return }

        let savedStyle = UserDefaults.standard.string(forKey: AppStorageKeys.applePayStyle.rawValue)
            .flatMap(ApplePayStyleOption.init(rawValue:)) ?? .automatic

        let acceleratedCheckoutButtonsView = AcceleratedCheckoutButtons(cartID: cartId)
            .applePayStyle(savedStyle.style)
            .wallets([.shopPay, .applePay])
            .cornerRadius(10)
            .onComplete { _ in
                CartManager.shared.resetCart()
            }
            .onFail { error in
                print("Accelerated checkout failed: \(error)")
            }
            .onCancel {
                print("Accelerated checkout cancelled")
            }
            .environmentObject(appConfiguration.acceleratedCheckoutsStorefrontConfig)
            .environmentObject(appConfiguration.acceleratedCheckoutsApplePayConfig)

        let acceleratedCheckoutsController = UIHostingController(rootView: AnyView(acceleratedCheckoutButtonsView))
        acceleratedCheckoutsController.view.translatesAutoresizingMaskIntoConstraints = false
        acceleratedCheckoutsController.view.backgroundColor = UIColor.clear

        let heightConstraint = acceleratedCheckoutsController.view.heightAnchor.constraint(equalToConstant: 96)
        heightConstraint.priority = UILayoutPriority(999)
        heightConstraint.isActive = true

        addChild(acceleratedCheckoutsController)
        buttonStackView.insertArrangedSubview(acceleratedCheckoutsController.view, at: 0)
        acceleratedCheckoutsController.didMove(toParent: self)

        acceleratedCheckoutHostingController = acceleratedCheckoutsController

        updateButtonContainerSize()
    }

    private func updateButtonContainerSize() {
        let checkoutButtonHeight: CGFloat = 48
        let acceleratedButtonHeight: CGFloat = acceleratedCheckoutHostingController != nil ? 96 : 0
        let spacing: CGFloat = acceleratedCheckoutHostingController != nil ? DesignSystem.buttonSpacing : 0
        let topPadding: CGFloat = 40
        let bottomPadding: CGFloat = 16
        let totalPadding = topPadding + bottomPadding

        let totalHeight = checkoutButtonHeight + acceleratedButtonHeight + spacing + totalPadding

        buttonContainerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: totalHeight)

        buttonContainerView.layoutIfNeeded()

        tableView.tableFooterView = buttonContainerView
    }

    private func refreshAcceleratedCheckoutButtons() {
        if let hostingController = acceleratedCheckoutHostingController {
            buttonStackView.removeArrangedSubview(hostingController.view)
            hostingController.view.removeFromSuperview()
            hostingController.removeFromParent()
            acceleratedCheckoutHostingController = nil
        }

        setupAcceleratedCheckoutButtons()

        updateButtonContainerSize()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.reloadData()

        if let url = CartManager.shared.cart?.checkoutURL {
            ShopifyCheckoutSheetKit.preload(checkout: url)
        }
    }

    // MARK: UITableViewDataSource

    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return CartManager.shared.cart?.lines.nodes.count ?? 0
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let node = node(at: indexPath)
        let variant = variant(at: indexPath)

        let cell = CartItemCell()
        cell.configure(with: variant, quantity: node.quantity)
        cell.onQuantityChange = { quantity in
            cell.showLoading(true)
            self.checkoutButton.isEnabled = false
            self.setupCheckoutButtonContent()

            ShopifyCheckoutSheetKit.invalidate()

            _Concurrency.Task {
                let cart = try await CartManager.shared.performCartLinesUpdate(id: node.id, quantity: quantity)

                cell.showLoading(false)
                self.checkoutButton.isEnabled = true
                self.setupCheckoutButtonContent()
                cell.quantityLabel.text = "\(cart.lines.nodes[indexPath.item].quantity)"

                if let checkoutUrl = cart.checkoutURL {
                    ShopifyCheckoutSheetKit.preload(checkout: checkoutUrl)
                }
            }
        }
        return cell
    }

    // MARK: Private

    private func cartDidUpdate() {
        let cart = CartManager.shared.cart
        let totalQuantity = cart?.totalQuantity ?? 0

        tabBarItem.badgeValue = String(totalQuantity)

        if isViewLoaded {
            emptyView.isHidden = totalQuantity > 0
            tableView.reloadData()
            tableView.isHidden = totalQuantity <= 0
            checkoutButton.isHidden = totalQuantity <= 0

            acceleratedCheckoutHostingController?.view.isHidden = totalQuantity <= 0

            if totalQuantity > 0 {
                refreshAcceleratedCheckoutButtons()
            } else {
                updateButtonContainerSize()
            }

            setupCheckoutButtonContent()
        }
    }

    @objc private func presentCheckout() {
        guard let url = CartManager.shared.cart?.checkoutURL else { return }

        ShopifyCheckoutSheetKit.present(checkout: url, from: self, delegate: self)
    }

    @objc private func resetCart() {
        CartManager.shared.resetCart()
    }

    private func node(at indexPath: IndexPath) -> CartLineNode {
        guard let lines = CartManager.shared.cart?.lines.nodes else {
            fatalError("invald index path")
        }

        return lines[indexPath.item]
    }

    private func variant(at indexPath: IndexPath) -> CartLineVariant {
        guard let variant = node(at: indexPath).merchandise.asProductVariant else {
            fatalError("invald index path")
        }
        return variant
    }
}

extension CartViewController: @preconcurrency CheckoutDelegate {
    func checkoutDidComplete(event: ShopifyCheckoutSheetKit.CheckoutCompletedEvent) {
        resetCart()

        ShopifyCheckoutSheetKit.configuration.logger.log("Order created: \(event.orderDetails.id)")
    }

    func checkoutDidCancel() {
        dismiss(animated: true)
    }

    func checkoutDidClickContactLink(url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func checkoutDidFail(error: ShopifyCheckoutSheetKit.CheckoutError) {
        var errorMessage = ""

        if case let .sdkError(underlying, _) = error {
            errorMessage = "\(underlying.localizedDescription)"
        }

        if case let .checkoutUnavailable(message, code, _) = error {
            errorMessage = message
            handleCheckoutUnavailable(message, code)
        }

        if case let .configurationError(message, _, _) = error {
            errorMessage = message
        }

        if case let .checkoutExpired(message, _, _) = error {
            errorMessage = message
        }

        print(errorMessage, "Recoverable: \(error.isRecoverable)")

        if !error.isRecoverable {
            handleUnrecoverableError(errorMessage)
        }
    }

    private func handleCheckoutUnavailable(_ message: String, _ code: CheckoutUnavailable) {
        switch code {
        case let .clientError(clientErrorCode):
            print("[CheckoutUnavailable] (checkoutError)", message, clientErrorCode)
        case let .httpError(statusCode):
            print("[CheckoutUnavailable] (httpError)", statusCode)
        }
    }

    func checkoutDidEmitWebPixelEvent(event: ShopifyCheckoutSheetKit.PixelEvent) {
        switch event {
        case let .customEvent(customEvent):
            print("[PIXEL - Custom]", customEvent.name!)
            if let genericEvent = mapToGenericEvent(customEvent: customEvent) {
                recordAnalyticsEvent(genericEvent)
            }
        case let .standardEvent(standardEvent):
            print("[PIXEL - Standard]", standardEvent.name!)
            recordAnalyticsEvent(mapToGenericEvent(standardEvent: standardEvent))
        }
    }

    private func handleUnrecoverableError(_ message: String = "Checkout unavailable") {
        DispatchQueue.main.async {
            self.resetCart()
            self.showAlert(message: message)
        }
    }
}

extension CartViewController {
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Checkout Failed", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in }))

        present(alert, animated: true, completion: nil)
    }
}

extension CartViewController {
    private func mapToGenericEvent(standardEvent: StandardEvent) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: standardEvent.name!,
            userId: getUserId(),
            timestamp: standardEvent.timestamp!,
            checkoutTotal: standardEvent.data?.checkout?.totalPrice?.amount ?? 0.0
        )
    }

    private func mapToGenericEvent(customEvent: CustomEvent) -> AnalyticsEvent? {
        guard customEvent.name != nil else {
            print("Failed to parse custom event", customEvent)
            return nil
        }
        return AnalyticsEvent(
            name: customEvent.name!,
            userId: getUserId(),
            timestamp: customEvent.timestamp!,
            checkoutTotal: nil
        )
    }

    private func decodeAndMap(event: CustomEvent, decoder _: JSONDecoder = JSONDecoder()) throws -> AnalyticsEvent {
        return AnalyticsEvent(
            name: event.name!,
            userId: getUserId(),
            timestamp: event.timestamp!,
            checkoutTotal: nil
        )
    }

    private func getUserId() -> String {
        return "123"
    }

    func recordAnalyticsEvent(_ event: AnalyticsEvent) {
        appConfiguration.webPixelsLogger.log(event.name)
    }
}

struct AnalyticsEvent: Codable {
    var name = ""
    var userId = ""
    var timestamp = ""
    var checkoutTotal: Double? = 0.0
}

struct CustomPixelEventData: Codable {
    var customAttribute = 0.0
}
