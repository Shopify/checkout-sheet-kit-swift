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

import OSLog
import ShopifyCheckoutSheetKit
import UIKit

class CardSelectionViewController: UIViewController {
    private let event: CheckoutPaymentMethodChangeStartEvent
    private var selectedIndex: Int = 0

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let confirmButton = UIButton(type: .system)

    private let cardOptions: [CreditCardPaymentInstrument] = [
        CreditCardPaymentInstrument(
            externalReferenceId: "card-visa-4242",
            cardHolderName: "John Smith", lastDigits: "4242",
            month: 12, year: 2026, brand: .visa,
            billingAddress: MailingAddress(
                address1: "123 Main St",
                city: "New York",
                province: "NY",
                country: "US",
                countryCodeV2: "US",
                zip: "10001",
                firstName: "John",
                lastName: "Smith"
            )
        ),
        CreditCardPaymentInstrument(
            externalReferenceId: "card-mc-5555",
            cardHolderName: "John Smith", lastDigits: "5555",
            month: 6,
            year: 2027,
            brand: .mastercard,
            billingAddress: MailingAddress(
                address1: "123 Main St",
                city: "New York",
                province: "NY",
                country: "US",
                countryCodeV2: "US",
                zip: "10001",
                firstName: "John",
                lastName: "Smith"
            )
        ),
        CreditCardPaymentInstrument(
            externalReferenceId: "card-amex-3737",
            cardHolderName: "Jane Doe",
             lastDigits: "3737",
            month: 3,
            year: 2028,
            brand: .americanExpress,
            billingAddress: MailingAddress(
                address1: "456 Oak Ave",
                city: "San Francisco",
                province: "CA",
                country: "US",
                countryCodeV2: "US",
                zip: "94102",
                firstName: "Jane",
                lastName: "Doe"
            )
        ),
        CreditCardPaymentInstrument(
            externalReferenceId: "card-amex-3733",
            cardHolderName: nil,
            lastDigits: nil,
            month: nil,
            year: nil,
            brand: nil,
            billingAddress: MailingAddress(
                address1: nil,
                city: nil,
                province: nil,
                country: nil,
                countryCodeV2: nil,
                zip: nil,
                firstName: nil,
                lastName: nil
            )
        )
    ]

    init(event: CheckoutPaymentMethodChangeStartEvent) {
        self.event = event
        super.init(nibName: nil, bundle: nil)

        // If payment instruments exist, try to select the first one
        if let firstInstrument = event.cart.payment.methods.first?.instruments.first {
            for (index, instrument) in cardOptions
                .enumerated() where instrument.externalReferenceId == firstInstrument.externalReferenceId
            {
                selectedIndex = index
                break
            }
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Select Payment Method"
        view.backgroundColor = .systemBackground

        setupTableView()
        setupConfirmButton()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CardCell.self, forCellReuseIdentifier: "CardCell")
        tableView.alwaysBounceVertical = false

        view.addSubviewPinnedToEdges(of: tableView)

        NSLayoutConstraint.activate([
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80)
        ])
    }

    private func setupConfirmButton() {
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.setTitle("Use Selected Card", for: .normal)
        confirmButton.backgroundColor = ColorPalette.primaryColor
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        confirmButton.layer.cornerRadius = 8
        confirmButton.addTarget(self, action: #selector(confirmSelection), for: .touchUpInside)

        view.addSubview(confirmButton)

        NSLayoutConstraint.activate([
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            confirmButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    @objc private func confirmSelection() {
        let selectedCard = cardOptions[selectedIndex]

        let instrument = CreditCardPaymentInstrument(
            externalReferenceId: selectedCard.externalReferenceId,
            cardHolderName: selectedCard.cardHolderName,
            lastDigits: selectedCard.lastDigits,
            month: selectedCard.month,
            year: selectedCard.year,
            brand: selectedCard.brand,
            billingAddress: selectedCard.billingAddress
        )

        let paymentMethod = CartPaymentMethod(instruments: [instrument])
        let payment = CartPayment(methods: [paymentMethod])

        let updatedCart = event.cart.copy(
            payment: .override(payment)
        )

        let result = CheckoutPaymentMethodChangeStartResponsePayload(cart: updatedCart)

        do {
            try event.respondWith(payload: result)
            OSLogger.shared.debug("[CardSelection] Successfully responded with card change")
            navigationController?.popViewController(animated: true)
        } catch {
            OSLogger.shared.error("[CardSelection] Failed to respond: \(error.localizedDescription)")
            showError(message: "Failed to update card: \(error.localizedDescription)")
        }
    }

    private func showError(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension CardSelectionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return cardOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell", for: indexPath) as? CardCell else {
            return UITableViewCell()
        }

        let option = cardOptions[indexPath.row]
        let isSelected = indexPath.row == selectedIndex
        cell.configure(with: option, isSelected: isSelected)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedIndex = indexPath.row
        tableView.reloadData()
    }
}

class CardCell: UITableViewCell {
    private let radioButton = UIView()
    private let radioButtonInner = UIView()
    private let cardImageView = UIImageView()
    private let labelLabel = UILabel()
    private let detailsLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        radioButton.translatesAutoresizingMaskIntoConstraints = false
        radioButton.layer.borderWidth = 2
        radioButton.layer.borderColor = UIColor.systemGray3.cgColor
        radioButton.layer.cornerRadius = 12

        radioButtonInner.translatesAutoresizingMaskIntoConstraints = false
        radioButtonInner.backgroundColor = ColorPalette.primaryColor
        radioButtonInner.layer.cornerRadius = 6
        radioButtonInner.isHidden = true

        cardImageView.translatesAutoresizingMaskIntoConstraints = false
        cardImageView.contentMode = .scaleAspectFit

        labelLabel.translatesAutoresizingMaskIntoConstraints = false
        labelLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        detailsLabel.font = UIFont.systemFont(ofSize: 14)
        detailsLabel.textColor = .secondaryLabel

        contentView.addSubview(radioButton)
        radioButton.addSubview(radioButtonInner)
        contentView.addSubview(cardImageView)
        contentView.addSubview(labelLabel)
        contentView.addSubview(detailsLabel)

        NSLayoutConstraint.activate([
            radioButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            radioButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            radioButton.widthAnchor.constraint(equalToConstant: 24),
            radioButton.heightAnchor.constraint(equalToConstant: 24),

            radioButtonInner.centerXAnchor.constraint(equalTo: radioButton.centerXAnchor),
            radioButtonInner.centerYAnchor.constraint(equalTo: radioButton.centerYAnchor),
            radioButtonInner.widthAnchor.constraint(equalToConstant: 12),
            radioButtonInner.heightAnchor.constraint(equalToConstant: 12),

            cardImageView.leadingAnchor.constraint(equalTo: radioButton.trailingAnchor, constant: 16),
            cardImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            cardImageView.widthAnchor.constraint(equalToConstant: 40),
            cardImageView.heightAnchor.constraint(equalToConstant: 26),

            labelLabel.leadingAnchor.constraint(equalTo: cardImageView.trailingAnchor, constant: 12),
            labelLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            labelLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            detailsLabel.leadingAnchor.constraint(equalTo: labelLabel.leadingAnchor),
            detailsLabel.topAnchor.constraint(equalTo: labelLabel.bottomAnchor, constant: 4),
            detailsLabel.trailingAnchor.constraint(equalTo: labelLabel.trailingAnchor),
            detailsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with option: CreditCardPaymentInstrument, isSelected: Bool) {
        labelLabel.text = option.brand?.rawValue

        // Set card brand image
        let imageName = getCardImageName(for: option.brand)
        cardImageView.image = UIImage(systemName: imageName)
        cardImageView.tintColor = .label

        // Set billing details from address
        let address = option.billingAddress
        detailsLabel.text = "\(address?.city ?? ""), \(address?.province ?? "") \(address?.zip ?? "")"

        radioButtonInner.isHidden = !isSelected

        if isSelected {
            contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            radioButton.layer.borderColor = ColorPalette.primaryColor.cgColor
        } else {
            contentView.backgroundColor = .systemBackground
            radioButton.layer.borderColor = UIColor.systemGray3.cgColor
        }
    }

    private func getCardImageName(for brand: CardBrand?) -> String {
        switch brand {
        case .visa:
            return "creditcard"
        case .mastercard:
            return "creditcard.fill"
        case .americanExpress:
            return "creditcard.and.123"
        default:
            return "creditcard"
        }
    }
}
