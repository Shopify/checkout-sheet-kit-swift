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

import UIKit
import ShopifyCheckout

class SettingsViewController: UITableViewController {

	// MARK: Properties
	enum Section: Int, CaseIterable {
		case preloading = 0
		case vaultedState = 1
		case colorScheme = 2
		case version = 3
		case undefined = -1

		static func from(_ rawValue: Int) -> Section {
			return Section(rawValue: rawValue) ?? .undefined
	   }
	}

	private lazy var preloadingSwitch: UISwitch = {
		let view = UISwitch()
		view.isOn = ShopifyCheckout.configuration.preloading.enabled
		view.addTarget(self, action: #selector(preloadingSwitchDidChange), for: .valueChanged)
		return view
	}()

	private lazy var vaultedStateSwitch: UISwitch = {
		let view = UISwitch()
		view.isOn = appConfiguration.useVaultedState
		view.addTarget(self, action: #selector(vaultedStateSwitchDidChange), for: .valueChanged)
		return view
	}()

	// MARK: Initializers

	init() {
		super.init(style: .grouped)

		title = "Settings"

		tabBarItem.image = UIImage(systemName: "gearshape.2")
	}

	required init?(coder: NSCoder) {
		fatalError("not implemented")
	}

	// MARK: UIViewController

	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.register(Cell.self, forCellReuseIdentifier: "cell")
	}

	// MARK: UITableViewDataSource

	override func numberOfSections(in tableView: UITableView) -> Int {
		return Section.allCases.count
	}

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch Section.from(section) {
		case Section.colorScheme:
			return "Color Scheme"
		default:
			return nil
		}
	}

	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		switch Section.from(section) {
		case Section.colorScheme:
			return "NOTE: If preloading is enabled, color scheme changes may not be applied unless the cart is preloaded again."
		default:
			return nil
		}
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch Section.from(section) {
		case Section.preloading:
			return 1
		case Section.vaultedState:
			return 1
		case Section.colorScheme:
			return ShopifyCheckout.Configuration.ColorScheme.allCases.count
		case Section.version:
			return 1
		default:
			return 0
		}
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

		var content = cell.defaultContentConfiguration()

		switch Section.from(indexPath.section) {
		case Section.preloading:
			content.text = "Use Preloading"
			cell.accessoryView = preloadingSwitch
		case Section.vaultedState:
			content.text = "Use Vaulted State"
			cell.accessoryView = vaultedStateSwitch
		case Section.colorScheme:
			let scheme = colorScheme(at: indexPath)
			content.text = scheme.prettyTitle
			content.secondaryText = ShopifyCheckout.configuration.colorScheme == scheme ? "Active" : ""
		case Section.version:
			content = UIListContentConfiguration.valueCell()
			content.text = "Version"
			content.secondaryText = currentVersion()
		default:
			()
		}

		cell.contentConfiguration = content

		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch Section.from(indexPath.section) {
		case Section.preloading:
			preloadingSwitch.isOn.toggle()
			preloadingSwitchDidChange()
		case Section.vaultedState:
			vaultedStateSwitch.isOn.toggle()
			vaultedStateSwitchDidChange()
		case Section.colorScheme:
			let newColorScheme = colorScheme(at: indexPath)
			ShopifyCheckout.configuration.colorScheme = newColorScheme
			let navigationBarAppearance = newColorScheme.navigationBarAppearance
			UINavigationBar.appearance().standardAppearance = navigationBarAppearance
			UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
			navigationController?.navigationBar.standardAppearance = navigationBarAppearance
			navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance
			view?.window?.overrideUserInterfaceStyle = newColorScheme.userInterfaceStyle
			tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
		default:
			()
		}
	}

	// MARK: Private

	@objc private func preloadingSwitchDidChange() {
		ShopifyCheckout.configuration.preloading.enabled = preloadingSwitch.isOn
	}

	@objc private func vaultedStateSwitchDidChange() {
		appConfiguration.useVaultedState = vaultedStateSwitch.isOn
	}

	private func currentColorScheme() -> Configuration.ColorScheme {
		return ShopifyCheckout.configuration.colorScheme
	}

	private func colorScheme(at indexPath: IndexPath) -> Configuration.ColorScheme {
		return ShopifyCheckout.Configuration.ColorScheme.allCases[indexPath.item]
	}

	private func indexPath(for colorScheme: Configuration.ColorScheme) -> IndexPath? {
		return ShopifyCheckout.Configuration.ColorScheme.allCases.firstIndex(of: colorScheme).map {
			IndexPath(row: $0, section: 1)
		}
	}

	private func currentVersion() -> String {
		guard
			let info = Bundle.main.infoDictionary,
			let version = info["CFBundleShortVersionString"] as? String,
			let buildNumber = info["CFBundleVersion"] as? String
		else {
			return "--"
		}

		return "\(version) (\(buildNumber))"
	}
}

private class Cell: UITableViewCell {
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
		automaticallyUpdatesContentConfiguration = false
		selectionStyle = .none
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

extension Configuration.ColorScheme {
	var prettyTitle: String {
		switch self {
		case .light:
			return "Light"
		case .dark:
			return "Dark"
		case .automatic:
			return "Automatic"
		case .web:
			return "Web Browser"
		}
	}

	var userInterfaceStyle: UIUserInterfaceStyle {
		switch self {
		case .light:
			return .light
		case .dark:
			return .dark
		default:
			return .unspecified
		}
	}

	var navigationBarAppearance: UINavigationBarAppearance {
		switch self {
		case .web:
			let navBarAppearance = UINavigationBarAppearance()
			navBarAppearance.backgroundImage = UIImage(named: "WebBrowserBarBackground")
			return navBarAppearance
		default:
			let navBarAppearance = UINavigationBarAppearance()
			navBarAppearance.configureWithDefaultBackground()
			return navBarAppearance
		}
	}
}
