// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    /// The code designating a country/region, which generally follows ISO 3166-1 alpha-2 guidelines.
    /// If a territory doesn't have a country code value in the `CountryCode` enum, then it might be considered a subdivision
    /// of another country. For example, the territories associated with Spain are represented by the country code `ES`,
    /// and the territories associated with the United States of America are represented by the country code `US`.
    enum CountryCode: String, EnumType {
        /// Afghanistan.
        case af = "AF"
        /// Åland Islands.
        case ax = "AX"
        /// Albania.
        case al = "AL"
        /// Algeria.
        case dz = "DZ"
        /// Andorra.
        case ad = "AD"
        /// Angola.
        case ao = "AO"
        /// Anguilla.
        case ai = "AI"
        /// Antigua & Barbuda.
        case ag = "AG"
        /// Argentina.
        case ar = "AR"
        /// Armenia.
        case am = "AM"
        /// Aruba.
        case aw = "AW"
        /// Ascension Island.
        case ac = "AC"
        /// Australia.
        case au = "AU"
        /// Austria.
        case at = "AT"
        /// Azerbaijan.
        case az = "AZ"
        /// Bahamas.
        case bs = "BS"
        /// Bahrain.
        case bh = "BH"
        /// Bangladesh.
        case bd = "BD"
        /// Barbados.
        case bb = "BB"
        /// Belarus.
        case by = "BY"
        /// Belgium.
        case be = "BE"
        /// Belize.
        case bz = "BZ"
        /// Benin.
        case bj = "BJ"
        /// Bermuda.
        case bm = "BM"
        /// Bhutan.
        case bt = "BT"
        /// Bolivia.
        case bo = "BO"
        /// Bosnia & Herzegovina.
        case ba = "BA"
        /// Botswana.
        case bw = "BW"
        /// Bouvet Island.
        case bv = "BV"
        /// Brazil.
        case br = "BR"
        /// British Indian Ocean Territory.
        case io = "IO"
        /// Brunei.
        case bn = "BN"
        /// Bulgaria.
        case bg = "BG"
        /// Burkina Faso.
        case bf = "BF"
        /// Burundi.
        case bi = "BI"
        /// Cambodia.
        case kh = "KH"
        /// Canada.
        case ca = "CA"
        /// Cape Verde.
        case cv = "CV"
        /// Caribbean Netherlands.
        case bq = "BQ"
        /// Cayman Islands.
        case ky = "KY"
        /// Central African Republic.
        case cf = "CF"
        /// Chad.
        case td = "TD"
        /// Chile.
        case cl = "CL"
        /// China.
        case cn = "CN"
        /// Christmas Island.
        case cx = "CX"
        /// Cocos (Keeling) Islands.
        case cc = "CC"
        /// Colombia.
        case co = "CO"
        /// Comoros.
        case km = "KM"
        /// Congo - Brazzaville.
        case cg = "CG"
        /// Congo - Kinshasa.
        case cd = "CD"
        /// Cook Islands.
        case ck = "CK"
        /// Costa Rica.
        case cr = "CR"
        /// Croatia.
        case hr = "HR"
        /// Cuba.
        case cu = "CU"
        /// Curaçao.
        case cw = "CW"
        /// Cyprus.
        case cy = "CY"
        /// Czechia.
        case cz = "CZ"
        /// Côte d’Ivoire.
        case ci = "CI"
        /// Denmark.
        case dk = "DK"
        /// Djibouti.
        case dj = "DJ"
        /// Dominica.
        case dm = "DM"
        /// Dominican Republic.
        case `do` = "DO"
        /// Ecuador.
        case ec = "EC"
        /// Egypt.
        case eg = "EG"
        /// El Salvador.
        case sv = "SV"
        /// Equatorial Guinea.
        case gq = "GQ"
        /// Eritrea.
        case er = "ER"
        /// Estonia.
        case ee = "EE"
        /// Eswatini.
        case sz = "SZ"
        /// Ethiopia.
        case et = "ET"
        /// Falkland Islands.
        case fk = "FK"
        /// Faroe Islands.
        case fo = "FO"
        /// Fiji.
        case fj = "FJ"
        /// Finland.
        case fi = "FI"
        /// France.
        case fr = "FR"
        /// French Guiana.
        case gf = "GF"
        /// French Polynesia.
        case pf = "PF"
        /// French Southern Territories.
        case tf = "TF"
        /// Gabon.
        case ga = "GA"
        /// Gambia.
        case gm = "GM"
        /// Georgia.
        case ge = "GE"
        /// Germany.
        case de = "DE"
        /// Ghana.
        case gh = "GH"
        /// Gibraltar.
        case gi = "GI"
        /// Greece.
        case gr = "GR"
        /// Greenland.
        case gl = "GL"
        /// Grenada.
        case gd = "GD"
        /// Guadeloupe.
        case gp = "GP"
        /// Guatemala.
        case gt = "GT"
        /// Guernsey.
        case gg = "GG"
        /// Guinea.
        case gn = "GN"
        /// Guinea-Bissau.
        case gw = "GW"
        /// Guyana.
        case gy = "GY"
        /// Haiti.
        case ht = "HT"
        /// Heard & McDonald Islands.
        case hm = "HM"
        /// Vatican City.
        case va = "VA"
        /// Honduras.
        case hn = "HN"
        /// Hong Kong SAR.
        case hk = "HK"
        /// Hungary.
        case hu = "HU"
        /// Iceland.
        case `is` = "IS"
        /// India.
        case `in` = "IN"
        /// Indonesia.
        case id = "ID"
        /// Iran.
        case ir = "IR"
        /// Iraq.
        case iq = "IQ"
        /// Ireland.
        case ie = "IE"
        /// Isle of Man.
        case im = "IM"
        /// Israel.
        case il = "IL"
        /// Italy.
        case it = "IT"
        /// Jamaica.
        case jm = "JM"
        /// Japan.
        case jp = "JP"
        /// Jersey.
        case je = "JE"
        /// Jordan.
        case jo = "JO"
        /// Kazakhstan.
        case kz = "KZ"
        /// Kenya.
        case ke = "KE"
        /// Kiribati.
        case ki = "KI"
        /// North Korea.
        case kp = "KP"
        /// Kosovo.
        case xk = "XK"
        /// Kuwait.
        case kw = "KW"
        /// Kyrgyzstan.
        case kg = "KG"
        /// Laos.
        case la = "LA"
        /// Latvia.
        case lv = "LV"
        /// Lebanon.
        case lb = "LB"
        /// Lesotho.
        case ls = "LS"
        /// Liberia.
        case lr = "LR"
        /// Libya.
        case ly = "LY"
        /// Liechtenstein.
        case li = "LI"
        /// Lithuania.
        case lt = "LT"
        /// Luxembourg.
        case lu = "LU"
        /// Macao SAR.
        case mo = "MO"
        /// Madagascar.
        case mg = "MG"
        /// Malawi.
        case mw = "MW"
        /// Malaysia.
        case my = "MY"
        /// Maldives.
        case mv = "MV"
        /// Mali.
        case ml = "ML"
        /// Malta.
        case mt = "MT"
        /// Martinique.
        case mq = "MQ"
        /// Mauritania.
        case mr = "MR"
        /// Mauritius.
        case mu = "MU"
        /// Mayotte.
        case yt = "YT"
        /// Mexico.
        case mx = "MX"
        /// Moldova.
        case md = "MD"
        /// Monaco.
        case mc = "MC"
        /// Mongolia.
        case mn = "MN"
        /// Montenegro.
        case me = "ME"
        /// Montserrat.
        case ms = "MS"
        /// Morocco.
        case ma = "MA"
        /// Mozambique.
        case mz = "MZ"
        /// Myanmar (Burma).
        case mm = "MM"
        /// Namibia.
        case na = "NA"
        /// Nauru.
        case nr = "NR"
        /// Nepal.
        case np = "NP"
        /// Netherlands.
        case nl = "NL"
        /// Netherlands Antilles.
        case an = "AN"
        /// New Caledonia.
        case nc = "NC"
        /// New Zealand.
        case nz = "NZ"
        /// Nicaragua.
        case ni = "NI"
        /// Niger.
        case ne = "NE"
        /// Nigeria.
        case ng = "NG"
        /// Niue.
        case nu = "NU"
        /// Norfolk Island.
        case nf = "NF"
        /// North Macedonia.
        case mk = "MK"
        /// Norway.
        case no = "NO"
        /// Oman.
        case om = "OM"
        /// Pakistan.
        case pk = "PK"
        /// Palestinian Territories.
        case ps = "PS"
        /// Panama.
        case pa = "PA"
        /// Papua New Guinea.
        case pg = "PG"
        /// Paraguay.
        case py = "PY"
        /// Peru.
        case pe = "PE"
        /// Philippines.
        case ph = "PH"
        /// Pitcairn Islands.
        case pn = "PN"
        /// Poland.
        case pl = "PL"
        /// Portugal.
        case pt = "PT"
        /// Qatar.
        case qa = "QA"
        /// Cameroon.
        case cm = "CM"
        /// Réunion.
        case re = "RE"
        /// Romania.
        case ro = "RO"
        /// Russia.
        case ru = "RU"
        /// Rwanda.
        case rw = "RW"
        /// St. Barthélemy.
        case bl = "BL"
        /// St. Helena.
        case sh = "SH"
        /// St. Kitts & Nevis.
        case kn = "KN"
        /// St. Lucia.
        case lc = "LC"
        /// St. Martin.
        case mf = "MF"
        /// St. Pierre & Miquelon.
        case pm = "PM"
        /// Samoa.
        case ws = "WS"
        /// San Marino.
        case sm = "SM"
        /// São Tomé & Príncipe.
        case st = "ST"
        /// Saudi Arabia.
        case sa = "SA"
        /// Senegal.
        case sn = "SN"
        /// Serbia.
        case rs = "RS"
        /// Seychelles.
        case sc = "SC"
        /// Sierra Leone.
        case sl = "SL"
        /// Singapore.
        case sg = "SG"
        /// Sint Maarten.
        case sx = "SX"
        /// Slovakia.
        case sk = "SK"
        /// Slovenia.
        case si = "SI"
        /// Solomon Islands.
        case sb = "SB"
        /// Somalia.
        case so = "SO"
        /// South Africa.
        case za = "ZA"
        /// South Georgia & South Sandwich Islands.
        case gs = "GS"
        /// South Korea.
        case kr = "KR"
        /// South Sudan.
        case ss = "SS"
        /// Spain.
        case es = "ES"
        /// Sri Lanka.
        case lk = "LK"
        /// St. Vincent & Grenadines.
        case vc = "VC"
        /// Sudan.
        case sd = "SD"
        /// Suriname.
        case sr = "SR"
        /// Svalbard & Jan Mayen.
        case sj = "SJ"
        /// Sweden.
        case se = "SE"
        /// Switzerland.
        case ch = "CH"
        /// Syria.
        case sy = "SY"
        /// Taiwan.
        case tw = "TW"
        /// Tajikistan.
        case tj = "TJ"
        /// Tanzania.
        case tz = "TZ"
        /// Thailand.
        case th = "TH"
        /// Timor-Leste.
        case tl = "TL"
        /// Togo.
        case tg = "TG"
        /// Tokelau.
        case tk = "TK"
        /// Tonga.
        case to = "TO"
        /// Trinidad & Tobago.
        case tt = "TT"
        /// Tristan da Cunha.
        case ta = "TA"
        /// Tunisia.
        case tn = "TN"
        /// Türkiye.
        case tr = "TR"
        /// Turkmenistan.
        case tm = "TM"
        /// Turks & Caicos Islands.
        case tc = "TC"
        /// Tuvalu.
        case tv = "TV"
        /// Uganda.
        case ug = "UG"
        /// Ukraine.
        case ua = "UA"
        /// United Arab Emirates.
        case ae = "AE"
        /// United Kingdom.
        case gb = "GB"
        /// United States.
        case us = "US"
        /// U.S. Outlying Islands.
        case um = "UM"
        /// Uruguay.
        case uy = "UY"
        /// Uzbekistan.
        case uz = "UZ"
        /// Vanuatu.
        case vu = "VU"
        /// Venezuela.
        case ve = "VE"
        /// Vietnam.
        case vn = "VN"
        /// British Virgin Islands.
        case vg = "VG"
        /// Wallis & Futuna.
        case wf = "WF"
        /// Western Sahara.
        case eh = "EH"
        /// Yemen.
        case ye = "YE"
        /// Zambia.
        case zm = "ZM"
        /// Zimbabwe.
        case zw = "ZW"
        /// Unknown Region.
        case zz = "ZZ"
    }
}
