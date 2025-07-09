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

/// The code designating a country/region, which generally follows ISO 3166-1 alpha-2 guidelines.
/// If a territory doesn't have a country code value in the `CountryCode` enum, then it might be considered a subdivision
/// of another country. For example, the territories associated with Spain are represented by the country code `ES`,
/// and the territories associated with the United States of America are represented by the country code `US`.
enum CountryCode: String, CaseIterable, Codable {
    /// Afghanistan
    case AF
    /// Åland Islands
    case AX
    /// Albania
    case AL
    /// Algeria
    case DZ
    /// Andorra
    case AD
    /// Angola
    case AO
    /// Anguilla
    case AI
    /// Antigua & Barbuda
    case AG
    /// Argentina
    case AR
    /// Armenia
    case AM
    /// Aruba
    case AW
    /// Ascension Island
    case AC
    /// Australia
    case AU
    /// Austria
    case AT
    /// Azerbaijan
    case AZ
    /// Bahamas
    case BS
    /// Bahrain
    case BH
    /// Bangladesh
    case BD
    /// Barbados
    case BB
    /// Belarus
    case BY
    /// Belgium
    case BE
    /// Belize
    case BZ
    /// Benin
    case BJ
    /// Bermuda
    case BM
    /// Bhutan
    case BT
    /// Bolivia
    case BO
    /// Bosnia & Herzegovina
    case BA
    /// Botswana
    case BW
    /// Bouvet Island
    case BV
    /// Brazil
    case BR
    /// British Indian Ocean Territory
    case IO
    /// Brunei
    case BN
    /// Bulgaria
    case BG
    /// Burkina Faso
    case BF
    /// Burundi
    case BI
    /// Cambodia
    case KH
    /// Canada
    case CA
    /// Cape Verde
    case CV
    /// Caribbean Netherlands
    case BQ
    /// Cayman Islands
    case KY
    /// Central African Republic
    case CF
    /// Chad
    case TD
    /// Chile
    case CL
    /// China
    case CN
    /// Christmas Island
    case CX
    /// Cocos (Keeling) Islands
    case CC
    /// Colombia
    case CO
    /// Comoros
    case KM
    /// Congo - Brazzaville
    case CG
    /// Congo - Kinshasa
    case CD
    /// Cook Islands
    case CK
    /// Costa Rica
    case CR
    /// Croatia
    case HR
    /// Cuba
    case CU
    /// Curaçao
    case CW
    /// Cyprus
    case CY
    /// Czechia
    case CZ
    /// Côte d'Ivoire
    case CI
    /// Denmark
    case DK
    /// Djibouti
    case DJ
    /// Dominica
    case DM
    /// Dominican Republic
    case DO
    /// Ecuador
    case EC
    /// Egypt
    case EG
    /// El Salvador
    case SV
    /// Equatorial Guinea
    case GQ
    /// Eritrea
    case ER
    /// Estonia
    case EE
    /// Eswatini
    case SZ
    /// Ethiopia
    case ET
    /// Falkland Islands
    case FK
    /// Faroe Islands
    case FO
    /// Fiji
    case FJ
    /// Finland
    case FI
    /// France
    case FR
    /// French Guiana
    case GF
    /// French Polynesia
    case PF
    /// French Southern Territories
    case TF
    /// Gabon
    case GA
    /// Gambia
    case GM
    /// Georgia
    case GE
    /// Germany
    case DE
    /// Ghana
    case GH
    /// Gibraltar
    case GI
    /// Greece
    case GR
    /// Greenland
    case GL
    /// Grenada
    case GD
    /// Guadeloupe
    case GP
    /// Guatemala
    case GT
    /// Guernsey
    case GG
    /// Guinea
    case GN
    /// Guinea-Bissau
    case GW
    /// Guyana
    case GY
    /// Haiti
    case HT
    /// Heard & McDonald Islands
    case HM
    /// Vatican City
    case VA
    /// Honduras
    case HN
    /// Hong Kong SAR
    case HK
    /// Hungary
    case HU
    /// Iceland
    case IS
    /// India
    case IN
    /// Indonesia
    case ID
    /// Iran
    case IR
    /// Iraq
    case IQ
    /// Ireland
    case IE
    /// Isle of Man
    case IM
    /// Israel
    case IL
    /// Italy
    case IT
    /// Jamaica
    case JM
    /// Japan
    case JP
    /// Jersey
    case JE
    /// Jordan
    case JO
    /// Kazakhstan
    case KZ
    /// Kenya
    case KE
    /// Kiribati
    case KI
    /// North Korea
    case KP
    /// Kosovo
    case XK
    /// Kuwait
    case KW
    /// Kyrgyzstan
    case KG
    /// Laos
    case LA
    /// Latvia
    case LV
    /// Lebanon
    case LB
    /// Lesotho
    case LS
    /// Liberia
    case LR
    /// Libya
    case LY
    /// Liechtenstein
    case LI
    /// Lithuania
    case LT
    /// Luxembourg
    case LU
    /// Macao SAR
    case MO
    /// Madagascar
    case MG
    /// Malawi
    case MW
    /// Malaysia
    case MY
    /// Maldives
    case MV
    /// Mali
    case ML
    /// Malta
    case MT
    /// Martinique
    case MQ
    /// Mauritania
    case MR
    /// Mauritius
    case MU
    /// Mayotte
    case YT
    /// Mexico
    case MX
    /// Moldova
    case MD
    /// Monaco
    case MC
    /// Mongolia
    case MN
    /// Montenegro
    case ME
    /// Montserrat
    case MS
    /// Morocco
    case MA
    /// Mozambique
    case MZ
    /// Myanmar (Burma)
    case MM
    /// Namibia
    case NA
    /// Nauru
    case NR
    /// Nepal
    case NP
    /// Netherlands
    case NL
    /// Netherlands Antilles
    case AN
    /// New Caledonia
    case NC
    /// New Zealand
    case NZ
    /// Nicaragua
    case NI
    /// Niger
    case NE
    /// Nigeria
    case NG
    /// Niue
    case NU
    /// Norfolk Island
    case NF
    /// North Macedonia
    case MK
    /// Norway
    case NO
    /// Oman
    case OM
    /// Pakistan
    case PK
    /// Palestinian Territories
    case PS
    /// Panama
    case PA
    /// Papua New Guinea
    case PG
    /// Paraguay
    case PY
    /// Peru
    case PE
    /// Philippines
    case PH
    /// Pitcairn Islands
    case PN
    /// Poland
    case PL
    /// Portugal
    case PT
    /// Qatar
    case QA
    /// Cameroon
    case CM
    /// Réunion
    case RE
    /// Romania
    case RO
    /// Russia
    case RU
    /// Rwanda
    case RW
    /// St. Barthélemy
    case BL
    /// St. Helena
    case SH
    /// St. Kitts & Nevis
    case KN
    /// St. Lucia
    case LC
    /// St. Martin
    case MF
    /// St. Pierre & Miquelon
    case PM
    /// Samoa
    case WS
    /// San Marino
    case SM
    /// São Tomé & Príncipe
    case ST
    /// Saudi Arabia
    case SA
    /// Senegal
    case SN
    /// Serbia
    case RS
    /// Seychelles
    case SC
    /// Sierra Leone
    case SL
    /// Singapore
    case SG
    /// Sint Maarten
    case SX
    /// Slovakia
    case SK
    /// Slovenia
    case SI
    /// Solomon Islands
    case SB
    /// Somalia
    case SO
    /// South Africa
    case ZA
    /// South Georgia & South Sandwich Islands
    case GS
    /// South Korea
    case KR
    /// South Sudan
    case SS
    /// Spain
    case ES
    /// Sri Lanka
    case LK
    /// St. Vincent & Grenadines
    case VC
    /// Sudan
    case SD
    /// Suriname
    case SR
    /// Svalbard & Jan Mayen
    case SJ
    /// Sweden
    case SE
    /// Switzerland
    case CH
    /// Syria
    case SY
    /// Taiwan
    case TW
    /// Tajikistan
    case TJ
    /// Tanzania
    case TZ
    /// Thailand
    case TH
    /// Timor-Leste
    case TL
    /// Togo
    case TG
    /// Tokelau
    case TK
    /// Tonga
    case TO
    /// Trinidad & Tobago
    case TT
    /// Tristan da Cunha
    case TA
    /// Tunisia
    case TN
    /// Türkiye
    case TR
    /// Turkmenistan
    case TM
    /// Turks & Caicos Islands
    case TC
    /// Tuvalu
    case TV
    /// Uganda
    case UG
    /// Ukraine
    case UA
    /// United Arab Emirates
    case AE
    /// United Kingdom
    case GB
    /// United States
    case US
    /// U.S. Outlying Islands
    case UM
    /// Uruguay
    case UY
    /// Uzbekistan
    case UZ
    /// Vanuatu
    case VU
    /// Venezuela
    case VE
    /// Vietnam
    case VN
    /// British Virgin Islands
    case VG
    /// Wallis & Futuna
    case WF
    /// Western Sahara
    case EH
    /// Yemen
    case YE
    /// Zambia
    case ZM
    /// Zimbabwe
    case ZW
    /// Unknown Region
    case ZZ
}
