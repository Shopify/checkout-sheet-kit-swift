// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    /// The three-letter currency codes that represent the world currencies used in
    /// stores. These include standard ISO 4217 codes, legacy codes,
    /// and non-standard codes.
    enum CurrencyCode: String, EnumType {
        /// United States Dollars (USD).
        case usd = "USD"
        /// Euro (EUR).
        case eur = "EUR"
        /// United Kingdom Pounds (GBP).
        case gbp = "GBP"
        /// Canadian Dollars (CAD).
        case cad = "CAD"
        /// Afghan Afghani (AFN).
        case afn = "AFN"
        /// Albanian Lek (ALL).
        case all = "ALL"
        /// Algerian Dinar (DZD).
        case dzd = "DZD"
        /// Angolan Kwanza (AOA).
        case aoa = "AOA"
        /// Argentine Pesos (ARS).
        case ars = "ARS"
        /// Armenian Dram (AMD).
        case amd = "AMD"
        /// Aruban Florin (AWG).
        case awg = "AWG"
        /// Australian Dollars (AUD).
        case aud = "AUD"
        /// Barbadian Dollar (BBD).
        case bbd = "BBD"
        /// Azerbaijani Manat (AZN).
        case azn = "AZN"
        /// Bangladesh Taka (BDT).
        case bdt = "BDT"
        /// Bahamian Dollar (BSD).
        case bsd = "BSD"
        /// Bahraini Dinar (BHD).
        case bhd = "BHD"
        /// Burundian Franc (BIF).
        case bif = "BIF"
        /// Belize Dollar (BZD).
        case bzd = "BZD"
        /// Bermudian Dollar (BMD).
        case bmd = "BMD"
        /// Bhutanese Ngultrum (BTN).
        case btn = "BTN"
        /// Bosnia and Herzegovina Convertible Mark (BAM).
        case bam = "BAM"
        /// Brazilian Real (BRL).
        case brl = "BRL"
        /// Bolivian Boliviano (BOB).
        case bob = "BOB"
        /// Botswana Pula (BWP).
        case bwp = "BWP"
        /// Brunei Dollar (BND).
        case bnd = "BND"
        /// Bulgarian Lev (BGN).
        case bgn = "BGN"
        /// Burmese Kyat (MMK).
        case mmk = "MMK"
        /// Cambodian Riel.
        case khr = "KHR"
        /// Cape Verdean escudo (CVE).
        case cve = "CVE"
        /// Cayman Dollars (KYD).
        case kyd = "KYD"
        /// Central African CFA Franc (XAF).
        case xaf = "XAF"
        /// Chilean Peso (CLP).
        case clp = "CLP"
        /// Chinese Yuan Renminbi (CNY).
        case cny = "CNY"
        /// Colombian Peso (COP).
        case cop = "COP"
        /// Comorian Franc (KMF).
        case kmf = "KMF"
        /// Congolese franc (CDF).
        case cdf = "CDF"
        /// Costa Rican Colones (CRC).
        case crc = "CRC"
        /// Croatian Kuna (HRK).
        case hrk = "HRK"
        /// Czech Koruny (CZK).
        case czk = "CZK"
        /// Danish Kroner (DKK).
        case dkk = "DKK"
        /// Dominican Peso (DOP).
        case dop = "DOP"
        /// East Caribbean Dollar (XCD).
        case xcd = "XCD"
        /// Egyptian Pound (EGP).
        case egp = "EGP"
        /// Eritrean Nakfa (ERN).
        case ern = "ERN"
        /// Ethiopian Birr (ETB).
        case etb = "ETB"
        /// Falkland Islands Pounds (FKP).
        case fkp = "FKP"
        /// CFP Franc (XPF).
        case xpf = "XPF"
        /// Fijian Dollars (FJD).
        case fjd = "FJD"
        /// Gibraltar Pounds (GIP).
        case gip = "GIP"
        /// Gambian Dalasi (GMD).
        case gmd = "GMD"
        /// Ghanaian Cedi (GHS).
        case ghs = "GHS"
        /// Guatemalan Quetzal (GTQ).
        case gtq = "GTQ"
        /// Guyanese Dollar (GYD).
        case gyd = "GYD"
        /// Georgian Lari (GEL).
        case gel = "GEL"
        /// Haitian Gourde (HTG).
        case htg = "HTG"
        /// Honduran Lempira (HNL).
        case hnl = "HNL"
        /// Hong Kong Dollars (HKD).
        case hkd = "HKD"
        /// Hungarian Forint (HUF).
        case huf = "HUF"
        /// Icelandic Kronur (ISK).
        case isk = "ISK"
        /// Indian Rupees (INR).
        case inr = "INR"
        /// Indonesian Rupiah (IDR).
        case idr = "IDR"
        /// Israeli New Shekel (NIS).
        case ils = "ILS"
        /// Iraqi Dinar (IQD).
        case iqd = "IQD"
        /// Jamaican Dollars (JMD).
        case jmd = "JMD"
        /// Japanese Yen (JPY).
        case jpy = "JPY"
        /// Jersey Pound.
        case jep = "JEP"
        /// Jordanian Dinar (JOD).
        case jod = "JOD"
        /// Kazakhstani Tenge (KZT).
        case kzt = "KZT"
        /// Kenyan Shilling (KES).
        case kes = "KES"
        /// Kiribati Dollar (KID).
        case kid = "KID"
        /// Kuwaiti Dinar (KWD).
        case kwd = "KWD"
        /// Kyrgyzstani Som (KGS).
        case kgs = "KGS"
        /// Laotian Kip (LAK).
        case lak = "LAK"
        /// Latvian Lati (LVL).
        case lvl = "LVL"
        /// Lebanese Pounds (LBP).
        case lbp = "LBP"
        /// Lesotho Loti (LSL).
        case lsl = "LSL"
        /// Liberian Dollar (LRD).
        case lrd = "LRD"
        /// Lithuanian Litai (LTL).
        case ltl = "LTL"
        /// Malagasy Ariary (MGA).
        case mga = "MGA"
        /// Macedonia Denar (MKD).
        case mkd = "MKD"
        /// Macanese Pataca (MOP).
        case mop = "MOP"
        /// Malawian Kwacha (MWK).
        case mwk = "MWK"
        /// Maldivian Rufiyaa (MVR).
        case mvr = "MVR"
        /// Mauritanian Ouguiya (MRU).
        case mru = "MRU"
        /// Mexican Pesos (MXN).
        case mxn = "MXN"
        /// Malaysian Ringgits (MYR).
        case myr = "MYR"
        /// Mauritian Rupee (MUR).
        case mur = "MUR"
        /// Moldovan Leu (MDL).
        case mdl = "MDL"
        /// Moroccan Dirham.
        case mad = "MAD"
        /// Mongolian Tugrik.
        case mnt = "MNT"
        /// Mozambican Metical.
        case mzn = "MZN"
        /// Namibian Dollar.
        case nad = "NAD"
        /// Nepalese Rupee (NPR).
        case npr = "NPR"
        /// Netherlands Antillean Guilder.
        case ang = "ANG"
        /// New Zealand Dollars (NZD).
        case nzd = "NZD"
        /// Nicaraguan Córdoba (NIO).
        case nio = "NIO"
        /// Nigerian Naira (NGN).
        case ngn = "NGN"
        /// Norwegian Kroner (NOK).
        case nok = "NOK"
        /// Omani Rial (OMR).
        case omr = "OMR"
        /// Panamian Balboa (PAB).
        case pab = "PAB"
        /// Pakistani Rupee (PKR).
        case pkr = "PKR"
        /// Papua New Guinean Kina (PGK).
        case pgk = "PGK"
        /// Paraguayan Guarani (PYG).
        case pyg = "PYG"
        /// Peruvian Nuevo Sol (PEN).
        case pen = "PEN"
        /// Philippine Peso (PHP).
        case php = "PHP"
        /// Polish Zlotych (PLN).
        case pln = "PLN"
        /// Qatari Rial (QAR).
        case qar = "QAR"
        /// Romanian Lei (RON).
        case ron = "RON"
        /// Russian Rubles (RUB).
        case rub = "RUB"
        /// Rwandan Franc (RWF).
        case rwf = "RWF"
        /// Samoan Tala (WST).
        case wst = "WST"
        /// Saint Helena Pounds (SHP).
        case shp = "SHP"
        /// Saudi Riyal (SAR).
        case sar = "SAR"
        /// Serbian dinar (RSD).
        case rsd = "RSD"
        /// Seychellois Rupee (SCR).
        case scr = "SCR"
        /// Singapore Dollars (SGD).
        case sgd = "SGD"
        /// Sudanese Pound (SDG).
        case sdg = "SDG"
        /// Somali Shilling (SOS).
        case sos = "SOS"
        /// Syrian Pound (SYP).
        case syp = "SYP"
        /// South African Rand (ZAR).
        case zar = "ZAR"
        /// South Korean Won (KRW).
        case krw = "KRW"
        /// South Sudanese Pound (SSP).
        case ssp = "SSP"
        /// Solomon Islands Dollar (SBD).
        case sbd = "SBD"
        /// Sri Lankan Rupees (LKR).
        case lkr = "LKR"
        /// Surinamese Dollar (SRD).
        case srd = "SRD"
        /// Swazi Lilangeni (SZL).
        case szl = "SZL"
        /// Swedish Kronor (SEK).
        case sek = "SEK"
        /// Swiss Francs (CHF).
        case chf = "CHF"
        /// Taiwan Dollars (TWD).
        case twd = "TWD"
        /// Thai baht (THB).
        case thb = "THB"
        /// Tanzanian Shilling (TZS).
        case tzs = "TZS"
        /// Trinidad and Tobago Dollars (TTD).
        case ttd = "TTD"
        /// Tunisian Dinar (TND).
        case tnd = "TND"
        /// Turkish Lira (TRY).
        case `try` = "TRY"
        /// Turkmenistani Manat (TMT).
        case tmt = "TMT"
        /// Ugandan Shilling (UGX).
        case ugx = "UGX"
        /// Ukrainian Hryvnia (UAH).
        case uah = "UAH"
        /// United Arab Emirates Dirham (AED).
        case aed = "AED"
        /// Uruguayan Pesos (UYU).
        case uyu = "UYU"
        /// Uzbekistan som (UZS).
        case uzs = "UZS"
        /// Vanuatu Vatu (VUV).
        case vuv = "VUV"
        /// Venezuelan Bolivares Soberanos (VES).
        case ves = "VES"
        /// Vietnamese đồng (VND).
        case vnd = "VND"
        /// West African CFA franc (XOF).
        case xof = "XOF"
        /// Yemeni Rial (YER).
        case yer = "YER"
        /// Zambian Kwacha (ZMW).
        case zmw = "ZMW"
        /// Belarusian Ruble (BYN).
        case byn = "BYN"
        /// Belarusian Ruble (BYR).
        ///
        /// **Deprecated**: `BYR` is deprecated. Use `BYN` available from version `2021-01` onwards instead.
        case byr = "BYR"
        /// Djiboutian Franc (DJF).
        case djf = "DJF"
        /// Guinean Franc (GNF).
        case gnf = "GNF"
        /// Iranian Rial (IRR).
        case irr = "IRR"
        /// Libyan Dinar (LYD).
        case lyd = "LYD"
        /// Sierra Leonean Leone (SLL).
        case sll = "SLL"
        /// Sao Tome And Principe Dobra (STD).
        ///
        /// **Deprecated**: `STD` is deprecated. Use `STN` available from version `2022-07` onwards instead.
        case std = "STD"
        /// Sao Tome And Principe Dobra (STN).
        case stn = "STN"
        /// Tajikistani Somoni (TJS).
        case tjs = "TJS"
        /// Tongan Pa'anga (TOP).
        case top = "TOP"
        /// Venezuelan Bolivares (VED).
        case ved = "VED"
        /// Venezuelan Bolivares (VEF).
        ///
        /// **Deprecated**: `VEF` is deprecated. Use `VES` available from version `2020-10` onwards instead.
        case vef = "VEF"
        /// Unrecognized currency.
        case xxx = "XXX"
    }
}
