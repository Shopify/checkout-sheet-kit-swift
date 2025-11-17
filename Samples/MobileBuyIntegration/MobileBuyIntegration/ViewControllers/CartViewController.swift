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

@preconcurrency import Buy
import Combine
import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit
import SwiftUI
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

        // Create empty view
        emptyView = UIView()
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.backgroundColor = .systemBackground

        let emptyLabel = UILabel()
        emptyLabel.text = "Your cart is empty"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(emptyLabel)

        // Create table view
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self

        // Create button container view
        buttonContainerView = UIView()
        buttonContainerView.backgroundColor = .systemBackground

        // Create button stack view
        buttonStackView = UIStackView()
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .vertical
        buttonStackView.spacing = DesignSystem.buttonSpacing
        buttonStackView.alignment = .fill
        buttonStackView.distribution = .fill

        // Create checkout button
        checkoutButton = UIButton(type: .system)
        checkoutButton.translatesAutoresizingMaskIntoConstraints = false
        checkoutButton.setTitle("Check out", for: .normal)
        checkoutButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        checkoutButton.backgroundColor = ColorPalette.primaryColor
        checkoutButton.setTitleColor(.white, for: .normal)
        checkoutButton.layer.cornerRadius = DesignSystem.cornerRadius
        // Ensure corner radius is maintained for all states
        checkoutButton.layer.masksToBounds = true
        // We'll set up custom layout for text and amount
        checkoutButton.contentHorizontalAlignment = .fill
        checkoutButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        checkoutButton.addTarget(self, action: #selector(presentCheckout), for: .touchUpInside)

        // Set up custom button content
        setupCheckoutButtonContent()

        // Add checkout button to stack view
        buttonStackView.addArrangedSubview(checkoutButton)

        // Add button stack to container view
        buttonContainerView.addSubview(buttonStackView)

        // Set as table footer view (scrolls with table content)
        tableView.tableFooterView = buttonContainerView

        // Add subviews
        view.addSubview(emptyView)
        view.addSubview(tableView)

        // Setup constraints
        NSLayoutConstraint.activate([
            // Empty view constraints
            emptyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor),

            // Table view constraints
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Button stack view constraints within container view
            buttonStackView.leadingAnchor.constraint(equalTo: buttonContainerView.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: buttonContainerView.trailingAnchor, constant: -16),
            buttonStackView.topAnchor.constraint(equalTo: buttonContainerView.topAnchor, constant: 32),
            buttonStackView.bottomAnchor.constraint(equalTo: buttonContainerView.bottomAnchor, constant: -16)
        ])

        // Add accelerated checkout buttons
        setupAcceleratedCheckoutButtons()

        // Update button container size
        updateButtonContainerSize()
    }

    private func setupCheckoutButtonContent() {
        // Remove any existing custom views
        checkoutButton.subviews.forEach { $0.removeFromSuperview() }

        // Update button background color based on enabled state
        checkoutButton.backgroundColor = checkoutButton.isEnabled ? ColorPalette.primaryColor : .lightGray

        // Create container view
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.isUserInteractionEnabled = false
        checkoutButton.addSubview(containerView)

        // Create labels
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

        // Update total label text
        if let amount = CartManager.shared.cart?.cost.totalAmount,
           let total = amount.formattedString()
        {
            totalLabel.text = total
        } else {
            totalLabel.text = ""
        }

        containerView.addSubview(checkoutLabel)
        containerView.addSubview(totalLabel)

        NSLayoutConstraint.activate([
            // Container view constraints
            containerView.leadingAnchor.constraint(equalTo: checkoutButton.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: checkoutButton.trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: checkoutButton.topAnchor, constant: 16),
            containerView.bottomAnchor.constraint(equalTo: checkoutButton.bottomAnchor, constant: -16),

            // Checkout label constraints
            checkoutLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            checkoutLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            // Total label constraints
            totalLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            totalLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            totalLabel.leadingAnchor.constraint(greaterThanOrEqualTo: checkoutLabel.trailingAnchor, constant: 8)
        ])

        // Clear the button's default title since we're using custom labels
        checkoutButton.setTitle("", for: .normal)
    }

    private func setupAcceleratedCheckoutButtons() {
        guard let cartId = CartManager.shared.cart?.id else { return }

        // Create accelerated checkout buttons
        let acceleratedCheckoutButtonsView = AcceleratedCheckoutButtons(cartID: cartId.rawValue)
            .wallets([.shopPay, .applePay])
            .cornerRadius(10)
            .onComplete { _ in
                // Reset cart on successful checkout
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

        // Wrap in AnyView and create hosting controller
        let acceleratedCheckoutsController = UIHostingController(rootView: AnyView(acceleratedCheckoutButtonsView))
        acceleratedCheckoutsController.view.translatesAutoresizingMaskIntoConstraints = false
        acceleratedCheckoutsController.view.backgroundColor = UIColor.clear

        // Set height constraint for accelerated checkout buttons (2 buttons: Apple Pay + Shop Pay)
        let heightConstraint = acceleratedCheckoutsController.view.heightAnchor.constraint(equalToConstant: 96)
        heightConstraint.priority = UILayoutPriority(999) // High priority but not required
        heightConstraint.isActive = true

        // Add to button stack view (at index 0 to appear above checkout button)
        addChild(acceleratedCheckoutsController)
        buttonStackView.insertArrangedSubview(acceleratedCheckoutsController.view, at: 0)
        acceleratedCheckoutsController.didMove(toParent: self)

        acceleratedCheckoutHostingController = acceleratedCheckoutsController

        // Update button container size after adding buttons
        updateButtonContainerSize()
    }

    private func updateButtonContainerSize() {
        // Calculate required height for the button container
        let checkoutButtonHeight: CGFloat = 48
        let acceleratedButtonHeight: CGFloat = acceleratedCheckoutHostingController != nil ? 96 : 0
        let spacing: CGFloat = acceleratedCheckoutHostingController != nil ? DesignSystem.buttonSpacing : 0
        let topPadding: CGFloat = 40
        let bottomPadding: CGFloat = 16
        let totalPadding = topPadding + bottomPadding

        let totalHeight = checkoutButtonHeight + acceleratedButtonHeight + spacing + totalPadding

        // Set the frame for the button container with proper dimensions
        buttonContainerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: totalHeight)

        // Force layout update to ensure proper stacking
        buttonContainerView.layoutIfNeeded()

        // Update the table view's footer
        tableView.tableFooterView = buttonContainerView
    }

    private func refreshAcceleratedCheckoutButtons() {
        // Remove existing hosting controller if it exists
        if let hostingController = acceleratedCheckoutHostingController {
            buttonStackView.removeArrangedSubview(hostingController.view)
            hostingController.view.removeFromSuperview()
            hostingController.removeFromParent()
            acceleratedCheckoutHostingController = nil
        }

        // Recreate with current cart
        setupAcceleratedCheckoutButtons()

        // Update container size
        updateButtonContainerSize()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.reloadData()

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
            self.setupCheckoutButtonContent() // Update button appearance for disabled state

            /// Invalidate checkout cache to ensure correct number of items are shown on checkout
            ShopifyCheckoutSheetKit.invalidate()

            /// Update cart quantities
            _Concurrency.Task {
                let cart = try await CartManager.shared.performCartLinesUpdate(id: node.id, quantity: quantity)

                cell.showLoading(false)
                self.checkoutButton.isEnabled = true
                self.setupCheckoutButtonContent() // Update button appearance for enabled state
                cell.quantityLabel.text = "\(cart.lines.nodes[indexPath.item].quantity)"

                ShopifyCheckoutSheetKit.preload(checkout: cart.checkoutUrl)
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

            // Show/hide accelerated checkout buttons based on cart state
            acceleratedCheckoutHostingController?.view.isHidden = totalQuantity <= 0

            // Refresh accelerated checkout buttons when cart changes
            if totalQuantity > 0 {
                refreshAcceleratedCheckoutButtons()
            } else {
                // Update container size when cart is empty
                updateButtonContainerSize()
            }

            // Update checkout button content with new cart total
            setupCheckoutButtonContent()
        }
    }

    @objc private func presentCheckout() {
        guard let url = CartManager.shared.cart?.checkoutUrl else { return }

        ShopifyCheckoutSheetKit.present(checkout: url, from: self, delegate: self)
    }

    @objc private func resetCart() {
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

        ShopifyCheckoutSheetKit.configuration.logger.log("Order created: \(event.orderConfirmation.order.id)")
    }

    func checkoutDidCancel() {
        dismiss(animated: true)
    }

    func checkoutDidClickContactLink(url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func checkoutDidRequestAddressChange(event: AddressChangeRequested) {
        // Respond with a hardcoded address after 2 seconds to simulate native address picker
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let hardcodedAddress = CartDeliveryAddress(
                firstName: "Alice",
                lastName: "Johnson",
                address1: "789 UIKit Boulevard",
                address2: "Floor 3",
                city: "Montreal",
                countryCode: "CA",
                phone: "+1-514-555-0789",
                provinceCode: "QC",
                zip: "H3B 2Y7"
            )

            let addressInput = CartSelectableAddress(address: .deliveryAddress(hardcodedAddress))
            let delivery = CartDelivery(addresses: [addressInput])
            let response = DeliveryAddressChangePayload(delivery: delivery)

            do {
                try event.respondWith(payload: response)
            } catch {
                print("[AddressChangeRequest]: Failed to respondWith ")
            }
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
