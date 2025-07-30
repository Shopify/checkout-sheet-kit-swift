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

import Buy
import Combine
import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit
import UIKit

class CartItemCell: UITableViewCell {
    let titleLabel = UILabel()
    let vendorLabel = UILabel()
    let quantityLabel = UILabel()
    let decreaseButton = UIButton(type: .system)
    let increaseButton = UIButton(type: .system)
    let labelStackView = UIStackView()
    let quantityStackView = UIStackView()
    let activityIndicator = UIActivityIndicatorView()

    var onQuantityChange: ((_ quantity: Int32) -> Void)?

    private var quantity: Int32 = 0 {
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
        /// Title stack config
        labelStackView.axis = .vertical
        labelStackView.alignment = .leading
        labelStackView.spacing = 4
        labelStackView.translatesAutoresizingMaskIntoConstraints = false

        /// Quantity stack config
        quantityStackView.axis = .horizontal
        quantityStackView.alignment = .center
        quantityStackView.spacing = 8
        quantityStackView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.numberOfLines = 0
        vendorLabel.numberOfLines = 0
        vendorLabel.textColor = .systemBlue
        vendorLabel.font = UIFont.systemFont(ofSize: 12)

        /// Title / vendor
        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(vendorLabel)

        /// Configure spinner
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true

        /// Quantity controls
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

    func configure(with variant: Storefront.ProductVariant, quantity: Int32) {
        titleLabel.text = variant.product.title
        vendorLabel.text = variant.product.vendor
        self.quantity = quantity
    }
}

class AcceleratedCheckoutDelegateImpl: AcceleratedCheckoutDelegate {
    weak var parent: CartViewController?

    init(parent: CartViewController) {
        self.parent = parent
    }

    func renderStateDidChange(state: RenderState) {
        print("UIKit Accelerated checkout render state: \(state)")
    }

    func checkoutDidComplete(event: CheckoutCompletedEvent) {
        print("UIKit Accelerated checkout completed with order ID: \(event.orderDetails.id)")
        CartManager.shared.resetCart()
    }

    func checkoutDidCancel() {
        print("UIKit Accelerated checkout cancelled")
    }

    func checkoutDidFail(error: CheckoutError) {
        print("UIKit Accelerated checkout failed: \(error)")
        parent?.handleUnrecoverableError("Accelerated checkout failed: \(error.localizedDescription)")
    }

    func checkoutDidClickContactLink(url: URL) {
        parent?.checkoutDidClickContactLink(url: url)
    }

    func checkoutDidEmitWebPixelEvent(event: PixelEvent) {
        parent?.checkoutDidEmitWebPixelEvent(event: event)
    }

    func shouldRecoverFromError(error: CheckoutError) -> Bool {
        return parent?.shouldRecoverFromError(error: error) ?? false
    }
}

class CartViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: Properties

    private var bag = Set<AnyCancellable>()

    private var emptyView: UIView!
    private var tableView: UITableView!
    private var checkoutButton: UIButton!

    // Accelerated checkout buttons (UIKit)
    private var acceleratedCheckoutContainer: UIStackView?
    private var shopPayButton: AcceleratedCheckoutButton?
    private var applePayButton: AcceleratedCheckoutButton?
    private var acceleratedDelegate: AcceleratedCheckoutDelegateImpl?

    // MARK: Initializers

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Reset", style: .plain, target: self, action: #selector(resetCart)
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UIViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()

        tableView.register(
            UITableViewCell.self, forCellReuseIdentifier: "CartItemCell"
        )
        tableView.allowsSelection = false
        tableView.rowHeight = 80

        setupAcceleratedCheckoutButtons()
        subscribeToCartUpdates()
        cartDidUpdate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh the view state when appearing
        cartDidUpdate()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // This gets called when Shop Pay modal is presented
    }

    private func subscribeToCartUpdates() {
        CartManager.shared.$cart
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.cartDidUpdate()
            }
            .store(in: &bag)
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground

        // Create table view
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        // Create empty view
        emptyView = UIView()
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.backgroundColor = .systemBackground

        let emptyLabel = UILabel()
        emptyLabel.text = "Your cart is empty"
        emptyLabel.textAlignment = .center
        emptyLabel.font = .systemFont(ofSize: 18, weight: .medium)
        emptyLabel.textColor = .systemGray
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(emptyLabel)

        view.addSubview(emptyView)

        // Create checkout button to match CartView styling
        checkoutButton = UIButton(type: .system)
        checkoutButton.setTitle("Check out", for: .normal)
        checkoutButton.backgroundColor = ColorPalette.primaryColor
        checkoutButton.setTitleColor(.white, for: .normal)
        checkoutButton.layer.cornerRadius = 10
        checkoutButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        checkoutButton.translatesAutoresizingMaskIntoConstraints = false
        checkoutButton.addTarget(self, action: #selector(checkoutButtonTapped), for: .touchUpInside)

        // Setup constraints
        NSLayoutConstraint.activate([
            // Table view
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Empty view
            emptyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Empty label
            emptyLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor)
        ])
    }

    @objc private func checkoutButtonTapped() {
        guard let checkoutUrl = CartManager.shared.cart?.checkoutUrl else { return }
        CheckoutController.shared?.present(checkout: checkoutUrl)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Refresh the cart state and UI
        cartDidUpdate()
        tableView.reloadData()

        // Force view layout refresh to fix Shop Pay modal dismissal state
        view.setNeedsLayout()
        view.layoutIfNeeded()

        if let url = CartManager.shared.cart?.checkoutUrl {
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
            /// Display loading state on row + disable checkout button
            cell.showLoading(true)
            self.checkoutButton.isEnabled = false

            /// Invalidate checkout cache to ensure correct number of items are shown on checkout
            ShopifyCheckoutSheetKit.invalidate()

            /// Update cart quantities
            _Concurrency.Task {
                let cart = try await CartManager.shared.performCartLinesUpdate(id: node.id, quantity: quantity)

                cell.showLoading(false)
                self.checkoutButton.isEnabled = true
                cell.quantityLabel.text = "\(cart.lines.nodes[indexPath.item].quantity)"

                ShopifyCheckoutSheetKit.preload(checkout: cart.checkoutUrl)
            }
        }
        return cell
    }

    // MARK: Private

    private func setupAcceleratedCheckoutButtons() {
        // Configure ShopifyAcceleratedCheckouts
        ShopifyAcceleratedCheckouts.configure(appConfiguration.acceleratedCheckoutsConfiguration)

        // Create table footer view that will scroll with content
        createTableFooterView()
    }

    private func createTableFooterView() {
        // Create footer container
        let footerContainer = UIView()
        footerContainer.backgroundColor = .systemBackground

        // Create accelerated checkout container stack view
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false

        // Create button stack
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 8
        buttonStack.distribution = .fill
        buttonStack.alignment = .fill

        container.addArrangedSubview(buttonStack)

        // Add checkout button to container
        container.addArrangedSubview(checkoutButton)

        // Add container to footer
        footerContainer.addSubview(container)
        acceleratedCheckoutContainer = container

        // Set up constraints
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: footerContainer.topAnchor, constant: 16),
            container.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor, constant: 20),
            container.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor, constant: -20),
            container.bottomAnchor.constraint(equalTo: footerContainer.bottomAnchor, constant: -16),

            // Checkout button constraints
            checkoutButton.heightAnchor.constraint(equalToConstant: 48)
        ])

        // Set the footer height based on content
        let footerHeight: CGFloat = 16 + 48 + 8 + 48 + 8 + 48 + 16 // top margin + button + spacing + button + spacing + checkout + bottom margin
        footerContainer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: footerHeight)

        tableView.tableFooterView = footerContainer
    }

    private func updateAcceleratedCheckoutButtons() {
        guard let container = acceleratedCheckoutContainer,
              let buttonStack = container.arrangedSubviews.first as? UIStackView,
              let cart = CartManager.shared.cart
        else {
            return
        }

        // Remove existing buttons
        shopPayButton?.removeFromSuperview()
        applePayButton?.removeFromSuperview()

        // Create new buttons for current cart
        let shopPay = AcceleratedCheckoutButton.shopPay(cartID: cart.id.rawValue)
        let applePay = AcceleratedCheckoutButton.applePay(cartID: cart.id.rawValue)

        // Configure delegates
        if acceleratedDelegate == nil {
            acceleratedDelegate = AcceleratedCheckoutDelegateImpl(parent: self)
        }
        shopPay.delegate = acceleratedDelegate
        applePay.delegate = acceleratedDelegate

        // Set presentation delegate to ensure buttons present from this view controller
        shopPay.presentationDelegate = self
        applePay.presentationDelegate = self

        // Configure appearance
        shopPay.cornerRadius = 10
        applePay.cornerRadius = 10

        // Let buttons use their intrinsic content size
        shopPay.translatesAutoresizingMaskIntoConstraints = false
        applePay.translatesAutoresizingMaskIntoConstraints = false

        // Add buttons to stack
        buttonStack.addArrangedSubview(shopPay)
        buttonStack.addArrangedSubview(applePay)

        // Store references
        shopPayButton = shopPay
        applePayButton = applePay
    }

    private func cartDidUpdate() {
        let cart = CartManager.shared.cart
        let totalQuantity = cart?.totalQuantity ?? 0

        tabBarItem.badgeValue = String(totalQuantity)

        if isViewLoaded {
            emptyView.isHidden = totalQuantity > 0
            tableView.reloadData()
            tableView.isHidden = totalQuantity <= 0
            checkoutButton.isHidden = totalQuantity <= 0

            // Update table footer view visibility
            if totalQuantity > 0 {
                if tableView.tableFooterView == nil {
                    createTableFooterView()
                }
                updateAcceleratedCheckoutButtons()
            } else {
                tableView.tableFooterView = nil
            }

            if #available(iOS 15.0, *) {
                checkoutButton.configuration?
                    .subtitle = cart?.cost.totalAmount.formattedString()
            }
        }
    }

    @IBAction private func presentCheckout() {
        guard let url = CartManager.shared.cart?.checkoutUrl else { return }

        ShopifyCheckoutSheetKit.present(checkout: url, from: self, delegate: self)
    }

    @IBAction private func resetCart() {
        CartManager.shared.resetCart()
    }

    private func node(at indexPath: IndexPath) -> BaseCartLine {
        guard let lines = CartManager.shared.cart?.lines.nodes else {
            fatalError("invald index path")
        }

        return lines[indexPath.item]
    }

    private func variant(at indexPath: IndexPath) -> Storefront.ProductVariant {
        guard
            let variant = node(at: indexPath).merchandise as? Storefront.ProductVariant
        else {
            fatalError("invald index path")
        }
        return variant
    }
}

extension CartViewController: CheckoutDelegate {
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

        /// Internal Checkout SDK error
        if case let .sdkError(underlying, _) = error {
            errorMessage = "\(underlying.localizedDescription)"
        }

        /// Checkout unavailable error
        if case let .checkoutUnavailable(message, code, _) = error {
            errorMessage = message
            handleCheckoutUnavailable(message, code)
        }

        /// Storefront configuration error
        if case let .configurationError(message, _, _) = error {
            errorMessage = message
        }

        /// Checkout has expired, re-create cart to fetch a new checkout URL
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

    func shouldRecoverFromError(error: ShopifyCheckoutSheetKit.CheckoutError) -> Bool {
        return error.isRecoverable
    }

    func handleUnrecoverableError(_ message: String = "Checkout unavailable") {
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

// analytics examples
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
        // return ID for user used in your existing analytics system
        return "123"
    }

    func recordAnalyticsEvent(_ event: AnalyticsEvent) {
        // send the event to an analytics system, e.g. via an analytics sdk
        appConfiguration.webPixelsLogger.log(event.name)
    }
}

// example type, e.g. that may be defined by an analytics sdk
struct AnalyticsEvent: Codable {
    var name = ""
    var userId = ""
    var timestamp = ""
    var checkoutTotal: Double? = 0.0
}

struct CustomPixelEventData: Codable {
    var customAttribute = 0.0
}

// MARK: - AcceleratedCheckoutPresentationDelegate

extension CartViewController: AcceleratedCheckoutPresentationDelegate {
    func present(_ viewController: UIViewController, animated: Bool) {
        // Try to find the best presenting view controller
        let presentingController: UIViewController
        if let navController = navigationController {
            presentingController = navController
        } else {
            presentingController = self
        }

        presentingController.present(viewController, animated: animated, completion: nil)
    }
}
