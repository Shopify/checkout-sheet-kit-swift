//
//  TotalsViewController.swift
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
import PassKit

enum PaymentType {
    case applePay
    case webCheckout
    case shopPay
}

protocol TotalsControllerDelegate: AnyObject {
    func totalsController(_ totalsController: TotalsViewController, didRequestPaymentWith type: PaymentType)
}

class TotalsViewController: UIViewController {
    
    @IBOutlet private weak var subtotalTitleLabel: UILabel!
    @IBOutlet private weak var subtotalLabel:      UILabel!
    @IBOutlet private weak var buttonStackView:    UIStackView!
    
    weak var delegate: TotalsControllerDelegate?
    
    var itemCount: Int = 0 {
        didSet {
            self.subtotalTitleLabel.text = "\(self.itemCount) Item\(itemCount == 1 ? "" : "s")"
        }
    }
    
    var subtotal: Decimal = 0.0 {
        didSet {
            self.subtotalLabel.text = Currency.stringFrom(self.subtotal)
        }
    }
    
    // ----------------------------------
    //  MARK: - View Loading -
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadPurchaseOptions()
    }
    
    private func loadPurchaseOptions() {
        
        let webCheckout = RoundedButton(type: .system)
        webCheckout.backgroundColor = UIColor.applicationGreen
        webCheckout.addTarget(self, action: #selector(webCheckoutAction(_:)), for: .touchUpInside)
        webCheckout.setTitle("Checkout",  for: .normal)
        webCheckout.setTitleColor(.white, for: .normal)
        self.buttonStackView.addArrangedSubview(webCheckout)
        
        let shopPayCheckout = RoundedButton(type: .system)
        shopPayCheckout.backgroundColor = UIColor(red: 0.35, green: 0.19, blue: 0.96, alpha: 1.00)
        shopPayCheckout.addTarget(self, action: #selector(shopPayCheckoutAction(_:)), for: .touchUpInside)
        shopPayCheckout.setTitle("Shop Pay",  for: .normal)
        shopPayCheckout.setTitleColor(.white, for: .normal)
        self.buttonStackView.addArrangedSubview(shopPayCheckout)
        
        if PKPaymentAuthorizationController.canMakePayments() {
            let applePay = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
            applePay.addTarget(self, action: #selector(applePayAction(_:)), for: .touchUpInside)
            self.buttonStackView.addArrangedSubview(applePay)
        }
    }
    
    // ----------------------------------
    //  MARK: - Actions -
    //
    @objc func webCheckoutAction(_ sender: Any) {
        self.delegate?.totalsController(self, didRequestPaymentWith: .webCheckout)
    }
    
    @objc func shopPayCheckoutAction(_ sender: Any) {
        self.delegate?.totalsController(self, didRequestPaymentWith: .shopPay)
    }
    
    @objc func applePayAction(_ sender: Any) {
        self.delegate?.totalsController(self, didRequestPaymentWith: .applePay)
    }
}
