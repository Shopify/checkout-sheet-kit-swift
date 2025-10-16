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

struct AddressOption {
    let label: String
    let address: CartAddress
}

class AddressSelectionViewController: UIViewController {
    private let event: AddressChangeRequested
    private var selectedIndex: Int = 0

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let confirmButton = UIButton(type: .system)

    private let addressOptions: [AddressOption] = [
        AddressOption(
            label: "Default",
            address: CartAddress(
                firstName: "Evelyn",
                lastName: "Hartley",
                address1: "Default",
                address2: "",
                city: "Toronto",
                countryCode: "CA",
                phone: "+1-888-746-7439",
                provinceCode: "ON",
                zip: "M5V 1M7"
            )
        ),
        AddressOption(
            label: "Happy path lane",
            address: CartAddress(
                firstName: "Evelyn",
                lastName: "Hartley",
                address1: "Happy path lane",
                address2: "Apt 5B",
                city: "Toronto",
                countryCode: "CA",
                phone: "+441792547555",
                provinceCode: "ON",
                zip: "M4L 1C9"
            )
        ),
        /// This address will cause validation errors on postcalCode
        /// causing the address form to 'unroll' back in checkout
        AddressOption(
            label: "Broken Ave",
            address: CartAddress(
                firstName: "Evelyn",
                lastName: "Hartley",
                address1: "Broken Ave",
                address2: "Apt 5B",
                city: "Toronto",
                countryCode: "CA",
                phone: "+441792547555",
                provinceCode: "ON",
                zip: "SA3 5HP"
            )
        )
    ]

    init(event: AddressChangeRequested) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Select Shipping Address"
        view.backgroundColor = .systemBackground

        setupTableView()
        setupConfirmButton()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AddressCell.self, forCellReuseIdentifier: "AddressCell")
        tableView.alwaysBounceVertical = false

        view.addSubviewPinnedToEdges(of: tableView)

        NSLayoutConstraint.activate([
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80)
        ])
    }

    private func setupConfirmButton() {
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.setTitle("Use Selected Address", for: .normal)
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
        let selectedAddress = addressOptions[selectedIndex].address
        let addressInput = CartSelectableAddress(address: selectedAddress)
        let delivery = CartDelivery(addresses: [addressInput])

        do {
            try event.respondWith(payload: delivery)
            OSLogger.shared.debug("[AddressSelection] Successfully responded with address")
            navigationController?.popViewController(animated: true)
        } catch {
            OSLogger.shared.error("[AddressSelection] Failed to respond: \(error.localizedDescription)")
            showError(message: "Failed to update address: \(error.localizedDescription)")
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

extension AddressSelectionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return addressOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell", for: indexPath) as? AddressCell else {
            return UITableViewCell()
        }

        let option = addressOptions[indexPath.row]
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

class AddressCell: UITableViewCell {
    private let radioButton = UIView()
    private let radioButtonInner = UIView()
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

        labelLabel.translatesAutoresizingMaskIntoConstraints = false
        labelLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        detailsLabel.font = UIFont.systemFont(ofSize: 14)
        detailsLabel.textColor = .secondaryLabel

        contentView.addSubview(radioButton)
        radioButton.addSubview(radioButtonInner)
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

            labelLabel.leadingAnchor.constraint(equalTo: radioButton.trailingAnchor, constant: 16),
            labelLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            labelLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            detailsLabel.leadingAnchor.constraint(equalTo: labelLabel.leadingAnchor),
            detailsLabel.topAnchor.constraint(equalTo: labelLabel.bottomAnchor, constant: 4),
            detailsLabel.trailingAnchor.constraint(equalTo: labelLabel.trailingAnchor),
            detailsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with option: AddressOption, isSelected: Bool) {
        labelLabel.text = option.label

        let address = option.address
        detailsLabel.text = "\(address.city ?? ""), \(address.provinceCode ?? "") \(address.zip ?? "")"

        radioButtonInner.isHidden = !isSelected

        if isSelected {
            contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            radioButton.layer.borderColor = ColorPalette.primaryColor.cgColor
        } else {
            contentView.backgroundColor = .systemBackground
            radioButton.layer.borderColor = UIColor.systemGray3.cgColor
        }
    }
}
