//
//  CartViewController.swift
//  Storefront
//
//  Created by Shopify.
//  Copyright (c) 2017 Shopify Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import Pay
import SafariServices

class CartViewController: ParallaxViewController {

    @IBOutlet fileprivate weak var tableView: UITableView!
    
    private var totalsViewController: TotalsViewController!
    
    fileprivate var paySession: PaySession?
    
    // ----------------------------------
    //  MARK: - Segue -
    //
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier! {
        case "TotalsViewController":
            self.totalsViewController          = (segue.destination as! TotalsViewController)
            self.totalsViewController.delegate = self
        default:
            break
        }
    }
    
    // ----------------------------------
    //  MARK: - View Loading -
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureParallax()
        self.configureTableView()
        
        self.updateSubtotal()
        
        self.registerNotifications()
    }
    
    deinit {
        self.unregisterNotifications()
    }
    
    private func configureParallax() {
        self.layout       = .headerAbove
        self.headerHeight = self.view.bounds.width * 0.5 // 2:1 ratio
        self.multiplier   = 0.0
    }
    
    private func configureTableView() {
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 100.0
        self.tableView.register(UINib(nibName: "CartCell", bundle: nil), forCellReuseIdentifier: "CartCell")
        
        if self.traitCollection.forceTouchCapability == .available {
            self.registerForPreviewing(with: self, sourceView: self.tableView)
        }
    }
    
    // ----------------------------------
    //  MARK: - Notifications -
    //
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(cartControllerItemsDidChange(_:)), name: Notification.Name.CartControllerItemsDidChange, object: nil)
    }
    
    private func unregisterNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func cartControllerItemsDidChange(_ notification: Notification) {
        self.updateSubtotal()
    }
    
    // ----------------------------------
    //  MARK: - Update -
    //
    func updateSubtotal() {
        self.totalsViewController.subtotal  = CartController.shared.subtotal
        self.totalsViewController.itemCount = CartController.shared.itemCount
    }
    
    // ----------------------------------
    //  MARK: - Actions -
    //
    func openWKWebViewControllerFor(_ url: URL, title: String) {
        let webController = WebViewController(url: url, accessToken: AccountController.shared.accessToken)
        webController.navigationItem.title = title
        self.navigationController?.pushViewController(webController, animated: true)
    }
    
    func openSafariViewControllerFor(_ url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.pushViewController(safariViewController, animated: false)
    }

    func buildShopPayURL(_ shopURL: URL, cartItems: [CartItem]) -> URL? {
        func decodeBase64String(_ base64String: String) -> String {
            let decodedData = Data(base64Encoded: base64String)!
            return String(data: decodedData, encoding: .utf8)!
        }
        func extractVariantId(_ fullVariantId: String) -> String {
            // Example string: gid://shopify/ProductVariant/31384149360662
            let pattern = #"gid://shopify/ProductVariant/(\d+)"#
            let regex = try! NSRegularExpression(pattern: pattern, options: [])
            let result = regex.matches(in:fullVariantId, range:NSMakeRange(0, fullVariantId.utf16.count))
            if (result.isEmpty) {
                // Handle error cases.
                return ""
            }
            if let substringRange = Range(result[0].range(at: 1), in: fullVariantId) {
                    return String(fullVariantId[substringRange])
                }
            return ""
        }
        func buildVariantSlugForItem(_ item: CartItem) -> String {
            return extractVariantId(decodeBase64String(item.variant.id)) + ":" + String(item.quantity)
        }
        
        // Build a Shop Pay checkout link.
        var components = URLComponents()
        components.scheme = "https"
        components.host = shopURL.host
        components.path = "/cart/" + cartItems.map(buildVariantSlugForItem).joined(separator: ",")
        components.queryItems = [
            URLQueryItem(name: "payment", value: "shop_pay"),
        ]
        return components.url
    }
    
    func authorizePaymentFor(_ shopName: String, in checkout: CheckoutViewModel) {
        let payCurrency = PayCurrency(currencyCode: "CAD", countryCode: "CA")
        let paySession  = PaySession(
            shopName: shopName,
            checkout: checkout.payCheckout,
            currency: payCurrency,
            merchantID: Client.merchantID
        )
        
        paySession.delegate = self
        self.paySession     = paySession
        
        paySession.authorize()
    }
    
    // ----------------------------------
    //  MARK: - Discount Codes -
    //
    func promptForCodes(completion: @escaping ((discountCode: String?, giftCard: String?)) -> Void) {
        let alert = UIAlertController(title: "Do you have a discount code of gift cards?", message: "Any valid discount code or gift card can be applied to your checkout.", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.attributedPlaceholder = NSAttributedString(string: "Discount code")
        }
        
        alert.addTextField { textField in
            textField.attributedPlaceholder = NSAttributedString(string: "Gift card code")
        }
        
        alert.addAction(UIAlertAction(title: "Continue", style: .cancel, handler: { [unowned alert] action in
            let textFields = alert.textFields!
            
            var discountCode = textFields[0].text?.trimmingCharacters(in: .whitespacesAndNewlines)
            var giftCardCode = textFields[1].text?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let code = discountCode, code.isEmpty {
                discountCode = nil
            }
            
            if let code = giftCardCode, code.isEmpty {
                giftCardCode = nil
            }
            
            completion((discountCode: discountCode, giftCard: giftCardCode))
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // ----------------------------------
    //  MARK: - View Controllers -
    //
    func productDetailsViewControllerWith(_ product: ProductViewModel) -> ProductDetailsViewController {
        let controller: ProductDetailsViewController = self.storyboard!.instantiateViewController()
        controller.product = product
        return controller
    }
}

// ----------------------------------
//  MARK: - Actions -
//
extension CartViewController {
    
    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

// ----------------------------------
//  MARK: - TotalsControllerDelegate -
//
extension CartViewController: TotalsControllerDelegate {
    
    func totalsController(_ totalsController: TotalsViewController, didRequestPaymentWith type: PaymentType) {
        let cartItems = CartController.shared.items
        if type == .shopPay {
            Client.shared.fetchShopURL { shopURL in
                guard let shopURL = shopURL else {
                    print("Failed to fetch shop url.")
                    return
                }
                
                let shopPayURL = self.buildShopPayURL(shopURL, cartItems: cartItems)
                if (shopPayURL != nil) {
                    self.openSafariViewControllerFor(shopPayURL!)
                }
            }
        } else {
            Client.shared.createCheckout(with: cartItems) { checkout in
                guard let checkout = checkout else {
                    print("Failed to create checkout.")
                    return
                }
                
                let completeCreateCheckout: (CheckoutViewModel) -> Void = { checkout in
                    switch type {
                    case .webCheckout:
                        self.openWKWebViewControllerFor(checkout.webURL, title: "Checkout")
                        
                    case .applePay:
                        Client.shared.fetchShopName { shopName in
                            guard let shopName = shopName else {
                                print("Failed to fetch shop name.")
                                return
                            }
                            
                            self.authorizePaymentFor(shopName, in: checkout)
                        }
                        
                    case .shopPay:
                        // Shouldn't happen as it was handled above.
                        break
                    }
                }
                
                /* ----------------------------------------
                 ** Use "HALFOFF" discount code for a 50%
                 ** discount in the graphql.myshopify.com
                 ** store (the test shop).
                 */
                self.promptForCodes { (discountCode, giftCard) in
                    var updatedCheckout = checkout
                    
                    let queue     = DispatchQueue.global(qos: .userInitiated)
                    let group     = DispatchGroup()
                    let semaphore = DispatchSemaphore(value: 1)
                    
                    if let discountCode = discountCode {
                        group.enter()
                        queue.async {
                            semaphore.wait()
                            
                            print("Applying discount code: \(discountCode)")
                            Client.shared.applyDiscount(discountCode, to: checkout.id) { checkout in
                                if let checkout = checkout {
                                    updatedCheckout = checkout
                                } else {
                                    print("Failed to apply discount to checkout")
                                }
                                semaphore.signal()
                                group.leave()
                            }
                        }
                    }
                    
                    if let giftCard = giftCard {
                        group.enter()
                        queue.async {
                            semaphore.wait()
                            
                            print("Applying gift card: \(giftCard)")
                            Client.shared.applyGiftCard(giftCard, to: checkout.id) { checkout in
                                if let checkout = checkout {
                                    updatedCheckout = checkout
                                } else {
                                    print("Failed to apply gift card to checkout")
                                }
                                semaphore.signal()
                                group.leave()
                            }
                        }
                    }
                    
                    group.notify(queue: .main) {
                        if let accessToken = AccountController.shared.accessToken {
                            
                            print("Associating checkout with customer: \(accessToken)")
                            Client.shared.updateCheckout(updatedCheckout.id, associatingCustomer: accessToken) { associatedCheckout in
                                if let associatedCheckout = associatedCheckout {
                                    completeCreateCheckout(associatedCheckout)
                                } else {
                                    print("Failed to associate checkout with customer.")
                                    completeCreateCheckout(updatedCheckout)
                                }
                            }
                            
                        } else {
                            completeCreateCheckout(updatedCheckout)
                        }
                    }
                }
            }
        }
    }
}

// ----------------------------------
//  MARK: - PaySessionDelegate -
//
extension CartViewController: PaySessionDelegate {
    
    func paySession(_ paySession: PaySession, didRequestShippingRatesFor address: PayPostalAddress, checkout: PayCheckout, provide: @escaping  (PayCheckout?, [PayShippingRate]) -> Void) {
        
        print("Updating checkout with address...")
        Client.shared.updateCheckout(checkout.id, updatingPartialShippingAddress: address) { checkout in
            
            guard let checkout = checkout else {
                print("Update for checkout failed.")
                provide(nil, [])
                return
            }
            
            print("Getting shipping rates...")
            Client.shared.fetchShippingRatesForCheckout(checkout.id) { result in
                if let result = result {
                    print("Fetched shipping rates.")
                    provide(result.checkout.payCheckout, result.rates.payShippingRates)
                } else {
                    provide(nil, [])
                }
            }
        }
    }
    
    func paySession(_ paySession: PaySession, didUpdateShippingAddress address: PayPostalAddress, checkout: PayCheckout, provide: @escaping (PayCheckout?) -> Void) {
        
        print("Updating checkout with shipping address for tax estimate...")
        Client.shared.updateCheckout(checkout.id, updatingPartialShippingAddress: address) { checkout in
            guard let checkout = checkout else {
                print("Update for checkout failed.")
                provide(nil)
                return
            }

            if checkout.ready {
                provide(checkout.payCheckout)
            } else {
                Client.shared.pollForReadyCheckout(checkout.id) { checkout in
                    provide(checkout?.payCheckout)
                }
            }
            
        }
    }
    
    func paySession(_ paySession: PaySession, didSelectShippingRate shippingRate: PayShippingRate, checkout: PayCheckout, provide: @escaping  (PayCheckout?) -> Void) {
        
        print("Selecting shipping rate...")
        Client.shared.updateCheckout(checkout.id, updatingShippingRate: shippingRate) { updatedCheckout in
            print("Selected shipping rate.")
            guard let updatedCheckout = updatedCheckout else { return provide(nil) }
            if updatedCheckout.ready {
                provide(updatedCheckout.payCheckout)
            } else {
                Client.shared.pollForReadyCheckout(checkout.id) { checkout in
                    provide(checkout?.payCheckout)
                }
            }
        }
    }
    
    func paySession(_ paySession: PaySession, didAuthorizePayment authorization: PayAuthorization, checkout: PayCheckout, completeTransaction: @escaping (PaySession.TransactionStatus) -> Void) {
        
        guard let email = authorization.shippingAddress.email else {
            print("Unable to update checkout email. Aborting transaction.")
            completeTransaction(.failure)
            return
        }
        
        print("Updating checkout shipping address...")
        Client.shared.updateCheckout(checkout.id, updatingCompleteShippingAddress: authorization.shippingAddress) { updatedCheckout in
            guard let _ = updatedCheckout else {
                completeTransaction(.failure)
                return
            }
            
            print("Updating checkout email...")
            Client.shared.updateCheckout(checkout.id, updatingEmail: email) { updatedCheckout in
                guard let _ = updatedCheckout else {
                    completeTransaction(.failure)
                    return
                }
                
                print("Checkout email updated: \(email)")
                
                Client.shared.pollForReadyCheckout(checkout.id) { readyCheckout in
                    guard let checkout = readyCheckout?.payCheckout else {
                        print("Checkout failed to get ready...")
                        completeTransaction(.failure)
                        return
                    }
                    
                    print("Checkout is ready...")
                    print("Completing checkout...")
                    Client.shared.completeCheckout(checkout, billingAddress: authorization.billingAddress, applePayToken: authorization.token, idempotencyToken: paySession.identifier) { payment in
                        if let payment = payment, checkout.paymentDue == payment.amount {
                            print("Checkout completed successfully.")
                            completeTransaction(.success)
                        } else {
                            print("Checkout failed to complete.")
                            completeTransaction(.failure)
                        }
                    }
                }
            }
        }
    }
    
    func paySessionDidFinish(_ paySession: PaySession) {
        
    }
}

// ----------------------------------
//  MARK: - UIViewControllerPreviewingDelegate -
//
extension CartViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        let tableView = previewingContext.sourceView as! UITableView
        if let indexPath = tableView.indexPathForRow(at: location) {
            
            previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
            
            let cell    = tableView.cellForRow(at: indexPath) as! CartCell
            let product = cell.viewModel!.model.product
            
            return self.productDetailsViewControllerWith(product)
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.navigationController!.show(viewControllerToCommit, sender: self)
    }
}

// ----------------------------------
//  MARK: - CartCellDelegate -
//
extension CartViewController: CartCellDelegate {
    
    func cartCell(_ cell: CartCell, didUpdateQuantity quantity: Int) {
        if let indexPath = self.tableView.indexPath(for: cell) {
            
            let didUpdate = CartController.shared.updateQuantity(quantity, at: indexPath.row)
            if didUpdate {
                
                self.tableView.beginUpdates()
                self.tableView.reloadRows(at: [indexPath], with: .none)
                self.tableView.endUpdates()
            }
        }
    }
}

// ----------------------------------
//  MARK: - UITableViewDataSource -
//
extension CartViewController: UITableViewDataSource {
    
    // ----------------------------------
    //  MARK: - Data -
    //
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CartController.shared.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell     = tableView.dequeueReusableCell(withIdentifier: CartCell.className, for: indexPath) as! CartCell
        let cartItem = CartController.shared.items[indexPath.row]
        
        cell.delegate = self
        cell.configureFrom(cartItem.viewModel)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            
            tableView.beginUpdates()
            
            CartController.shared.removeAllQuantities(at: indexPath.row)
            
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            
        default:
            break
        }
    }
}

// ----------------------------------
//  MARK: - UITableViewDelegate -
//
extension CartViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.updateParallax()
    }
}
