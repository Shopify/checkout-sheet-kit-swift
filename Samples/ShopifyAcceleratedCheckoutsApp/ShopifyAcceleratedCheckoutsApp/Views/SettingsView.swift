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

import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit
import SwiftUI

enum AppStorageKeys: String {
    case requireEmail
    case requirePhone
    case locale
    case logLevel
    case email
    case phone
    case supportedCountries
}

struct SettingsView: View {
    @AppStorage(AppStorageKeys.requireEmail.rawValue) var requireEmail: Bool = true
    @AppStorage(AppStorageKeys.requirePhone.rawValue) var requirePhone: Bool = true
    @AppStorage(AppStorageKeys.locale.rawValue) var locale: String = "en"
    @AppStorage(AppStorageKeys.logLevel.rawValue) var logLevel: LogLevel = .all {
        didSet {
            ShopifyAcceleratedCheckouts.logLevel = logLevel
        }
    }

    @AppStorage(AppStorageKeys.email.rawValue) var email: String = ""
    @AppStorage(AppStorageKeys.phone.rawValue) var phone: String = ""
    @AppStorage(AppStorageKeys.supportedCountries.rawValue) var supportedCountriesString: String = ""

    private let availableLocales: [(name: String, isoCode: String)] = [
        ("English", "en"),
        ("English (US)", "en-US"),
        ("French", "fr-FR")
    ]

    private var selectedCountries: Set<String> {
        Set(supportedCountriesString.split(separator: ",").map { String($0) }.filter { !$0.isEmpty })
    }

    private func isCountrySelected(_ code: String) -> Bool {
        selectedCountries.contains(code)
    }

    var body: some View {
        Form {
            Text("These settings will apply to new checkouts and persist between app launches")
                .font(.subheadline)

            Section("Logging") {
                Picker(
                    "Log Level",
                    /// Binding used instead of $logLevel due to property observers (didSet)
                    /// are not called on published values such as @AppStorage
                    selection: Binding(
                        get: { logLevel },
                        set: { logLevel = $0 }
                    )
                ) {
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Text(
                            level.rawValue.capitalized(with: Locale.current)
                        ).tag(level)
                    }
                }
                .pickerStyle(.menu)

                Text("Controls the level of logging for Accelerated Checkouts operations")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Language") {
                Picker("Language", selection: $locale) {
                    ForEach(availableLocales, id: \.isoCode) { localeOption in
                        Text(localeOption.name)
                            .tag(localeOption.isoCode)
                    }
                }
                .pickerStyle(.menu)

                Text("Configures localization for fallback if ApplePay not supported")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Apple Pay Contact Fields") {
                Text("At least one contact field should be present to complete a checkout with Apple Pay. If email or phone is toggled off, you may supply a hardcoded value instead.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Require Email from Apple Pay", isOn: $requireEmail)

                TextField("Prefill Email (Optional)", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .accessibilityLabel("Email field")

                Text("Email will be attached to the buyerIdentity during cartCreate.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Require Phone from Apple Pay", isOn: $requirePhone)

                TextField("Prefill Phone (Optional)", text: $phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)

                Text("Phone Number will be attached to the buyerIdentity during cartCreate.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Apple Pay Shipping Countries") {
                Text("Select countries where Apple Pay shipping is supported. Leave empty to allow all countries.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !selectedCountries.isEmpty {
                    Text("Selected: \(selectedCountries.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                NavigationLink("Select Countries (\(selectedCountries.count) selected)") {
                    CountrySelectionView(
                        supportedCountriesString: $supportedCountriesString
                    )
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CountrySelectionView: View {
    @Binding var supportedCountriesString: String
    @State private var searchText = ""
    
    private var selectedCountries: Set<String> {
        Set(supportedCountriesString.split(separator: ",").map { String($0) }.filter { !$0.isEmpty })
    }
    
    private func toggleCountry(_ code: String) {
        var countries = selectedCountries
        if countries.contains(code) {
            countries.remove(code)
        } else {
            countries.insert(code)
        }
        supportedCountriesString = countries.joined(separator: ",")
    }
    
    // Create an array of all country codes with their display names
    private static let allCountries: [(code: String, name: String)] = [
        ("US", "United States"),
        ("CA", "Canada"),
        ("GB", "United Kingdom"),
        ("MX", "Mexico"),
        ("FR", "France"),
        ("DE", "Germany"),
        ("ES", "Spain"),
        ("IT", "Italy"),
        ("AU", "Australia"),
        ("JP", "Japan"),
        ("CN", "China"),
        ("BR", "Brazil"),
        ("AR", "Argentina"),
        ("NL", "Netherlands"),
        ("BE", "Belgium"),
        ("SE", "Sweden"),
        ("NO", "Norway"),
        ("DK", "Denmark"),
        ("FI", "Finland"),
        ("PL", "Poland"),
        ("PT", "Portugal"),
        ("IE", "Ireland"),
        ("AT", "Austria"),
        ("CH", "Switzerland"),
        ("NZ", "New Zealand"),
        ("SG", "Singapore"),
        ("HK", "Hong Kong"),
        ("KR", "South Korea"),
        ("TW", "Taiwan"),
        ("TH", "Thailand"),
        ("MY", "Malaysia"),
        ("ID", "Indonesia"),
        ("PH", "Philippines"),
        ("VN", "Vietnam"),
        ("IN", "India"),
        ("PK", "Pakistan"),
        ("BD", "Bangladesh"),
        ("ZA", "South Africa"),
        ("EG", "Egypt"),
        ("NG", "Nigeria"),
        ("KE", "Kenya"),
        ("MA", "Morocco"),
        ("AE", "United Arab Emirates"),
        ("SA", "Saudi Arabia"),
        ("IL", "Israel"),
        ("TR", "Turkey"),
        ("RU", "Russia"),
        ("UA", "Ukraine"),
        ("CZ", "Czech Republic"),
        ("HU", "Hungary"),
        ("RO", "Romania"),
        ("BG", "Bulgaria"),
        ("GR", "Greece"),
        ("HR", "Croatia"),
        ("RS", "Serbia"),
        ("SI", "Slovenia"),
        ("SK", "Slovakia"),
        ("CL", "Chile"),
        ("CO", "Colombia"),
        ("PE", "Peru"),
        ("VE", "Venezuela"),
        ("UY", "Uruguay"),
        ("PY", "Paraguay"),
        ("BO", "Bolivia"),
        ("EC", "Ecuador"),
        ("CR", "Costa Rica"),
        ("GT", "Guatemala"),
        ("HN", "Honduras"),
        ("NI", "Nicaragua"),
        ("PA", "Panama"),
        ("SV", "El Salvador"),
        ("DO", "Dominican Republic"),
        ("CU", "Cuba"),
        ("JM", "Jamaica"),
        ("HT", "Haiti"),
        ("PR", "Puerto Rico"),
        ("TT", "Trinidad and Tobago"),
        ("BB", "Barbados"),
        ("BS", "Bahamas"),
        ("IS", "Iceland"),
        ("LU", "Luxembourg"),
        ("MT", "Malta"),
        ("CY", "Cyprus"),
        ("EE", "Estonia"),
        ("LV", "Latvia"),
        ("LT", "Lithuania"),
        ("BY", "Belarus"),
        ("MD", "Moldova"),
        ("GE", "Georgia"),
        ("AM", "Armenia"),
        ("AZ", "Azerbaijan"),
        ("KZ", "Kazakhstan"),
        ("UZ", "Uzbekistan"),
        ("TM", "Turkmenistan"),
        ("KG", "Kyrgyzstan"),
        ("TJ", "Tajikistan"),
        ("AF", "Afghanistan"),
        ("LK", "Sri Lanka"),
        ("NP", "Nepal"),
        ("BT", "Bhutan"),
        ("MM", "Myanmar"),
        ("KH", "Cambodia"),
        ("LA", "Laos"),
        ("BN", "Brunei"),
        ("TL", "East Timor"),
        ("MN", "Mongolia"),
        ("KP", "North Korea"),
        ("LB", "Lebanon"),
        ("JO", "Jordan"),
        ("SY", "Syria"),
        ("IQ", "Iraq"),
        ("IR", "Iran"),
        ("YE", "Yemen"),
        ("OM", "Oman"),
        ("QA", "Qatar"),
        ("KW", "Kuwait"),
        ("BH", "Bahrain"),
        ("PS", "Palestine"),
        ("DZ", "Algeria"),
        ("TN", "Tunisia"),
        ("LY", "Libya"),
        ("SD", "Sudan"),
        ("ET", "Ethiopia"),
        ("ER", "Eritrea"),
        ("DJ", "Djibouti"),
        ("SO", "Somalia"),
        ("UG", "Uganda"),
        ("RW", "Rwanda"),
        ("BI", "Burundi"),
        ("TZ", "Tanzania"),
        ("MZ", "Mozambique"),
        ("MW", "Malawi"),
        ("ZM", "Zambia"),
        ("ZW", "Zimbabwe"),
        ("BW", "Botswana"),
        ("NA", "Namibia"),
        ("SZ", "Eswatini"),
        ("LS", "Lesotho"),
        ("AO", "Angola"),
        ("CD", "Democratic Republic of the Congo"),
        ("CG", "Republic of the Congo"),
        ("CM", "Cameroon"),
        ("CF", "Central African Republic"),
        ("TD", "Chad"),
        ("NE", "Niger"),
        ("ML", "Mali"),
        ("MR", "Mauritania"),
        ("SN", "Senegal"),
        ("GM", "Gambia"),
        ("GW", "Guinea-Bissau"),
        ("GN", "Guinea"),
        ("SL", "Sierra Leone"),
        ("LR", "Liberia"),
        ("CI", "Ivory Coast"),
        ("BF", "Burkina Faso"),
        ("GH", "Ghana"),
        ("TG", "Togo"),
        ("BJ", "Benin"),
        ("GA", "Gabon"),
        ("GQ", "Equatorial Guinea"),
        ("ST", "São Tomé and Príncipe"),
        ("CV", "Cape Verde"),
        ("MU", "Mauritius"),
        ("SC", "Seychelles"),
        ("MG", "Madagascar"),
        ("KM", "Comoros"),
        ("FJ", "Fiji"),
        ("PG", "Papua New Guinea"),
        ("SB", "Solomon Islands"),
        ("VU", "Vanuatu"),
        ("NC", "New Caledonia"),
        ("PF", "French Polynesia"),
        ("WS", "Samoa"),
        ("TO", "Tonga"),
        ("KI", "Kiribati"),
        ("TV", "Tuvalu"),
        ("NR", "Nauru"),
        ("PW", "Palau"),
        ("MH", "Marshall Islands"),
        ("FM", "Micronesia"),
        ("AD", "Andorra"),
        ("MC", "Monaco"),
        ("SM", "San Marino"),
        ("VA", "Vatican City"),
        ("LI", "Liechtenstein"),
        ("MK", "North Macedonia"),
        ("AL", "Albania"),
        ("BA", "Bosnia and Herzegovina"),
        ("ME", "Montenegro"),
        ("XK", "Kosovo"),
        ("FO", "Faroe Islands"),
        ("GL", "Greenland"),
        ("BM", "Bermuda"),
        ("KY", "Cayman Islands"),
        ("VG", "British Virgin Islands"),
        ("AI", "Anguilla"),
        ("MS", "Montserrat"),
        ("TC", "Turks and Caicos Islands"),
        ("AG", "Antigua and Barbuda"),
        ("DM", "Dominica"),
        ("GD", "Grenada"),
        ("KN", "Saint Kitts and Nevis"),
        ("LC", "Saint Lucia"),
        ("VC", "Saint Vincent and the Grenadines"),
        ("AW", "Aruba"),
        ("CW", "Curaçao"),
        ("SX", "Sint Maarten"),
        ("BQ", "Caribbean Netherlands"),
        ("GF", "French Guiana"),
        ("SR", "Suriname"),
        ("GY", "Guyana"),
        ("FK", "Falkland Islands"),
        ("MO", "Macau"),
        ("BZ", "Belize")
    ].sorted { $0.name < $1.name }
    
    private var filteredCountries: [(code: String, name: String)] {
        if searchText.isEmpty {
            return Self.allCountries
        } else {
            return Self.allCountries.filter { country in
                country.name.localizedCaseInsensitiveContains(searchText) ||
                country.code.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                if selectedCountries.isEmpty {
                    Text("No countries selected - All countries allowed")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    Button("Clear All") {
                        supportedCountriesString = ""
                    }
                    .foregroundColor(.red)
                }
            }
            
            Section("Countries") {
                ForEach(filteredCountries, id: \.code) { country in
                    HStack {
                        Text("\(country.name) (\(country.code))")
                        Spacer()
                        if selectedCountries.contains(country.code) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleCountry(country.code)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search countries")
        .navigationTitle("Select Countries")
        .navigationBarTitleDisplayMode(.inline)
    }
}
