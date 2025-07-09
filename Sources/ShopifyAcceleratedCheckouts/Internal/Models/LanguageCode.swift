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

/// Language codes supported by Shopify
enum LanguageCode: String, CaseIterable, Codable {
    /// Afrikaans
    case AF
    /// Akan
    case AK
    /// Amharic
    case AM
    /// Arabic
    case AR
    /// Assamese
    case AS
    /// Azerbaijani
    case AZ
    /// Belarusian
    case BE
    /// Bulgarian
    case BG
    /// Bambara
    case BM
    /// Bangla
    case BN
    /// Tibetan
    case BO
    /// Breton
    case BR
    /// Bosnian
    case BS
    /// Catalan
    case CA
    /// Chechen
    case CE
    /// Central Kurdish
    case CKB
    /// Czech
    case CS
    /// Welsh
    case CY
    /// Danish
    case DA
    /// German
    case DE
    /// Dzongkha
    case DZ
    /// Ewe
    case EE
    /// Greek
    case EL
    /// English
    case EN
    /// Esperanto
    case EO
    /// Spanish
    case ES
    /// Estonian
    case ET
    /// Basque
    case EU
    /// Persian
    case FA
    /// Fulah
    case FF
    /// Finnish
    case FI
    /// Filipino
    case FIL
    /// Faroese
    case FO
    /// French
    case FR
    /// Western Frisian
    case FY
    /// Irish
    case GA
    /// Scottish Gaelic
    case GD
    /// Galician
    case GL
    /// Gujarati
    case GU
    /// Manx
    case GV
    /// Hausa
    case HA
    /// Hebrew
    case HE
    /// Hindi
    case HI
    /// Croatian
    case HR
    /// Hungarian
    case HU
    /// Armenian
    case HY
    /// Interlingua
    case IA
    /// Indonesian
    case ID
    /// Igbo
    case IG
    /// Sichuan Yi
    case II
    /// Icelandic
    case IS
    /// Italian
    case IT
    /// Japanese
    case JA
    /// Javanese
    case JV
    /// Georgian
    case KA
    /// Kikuyu
    case KI
    /// Kazakh
    case KK
    /// Kalaallisut
    case KL
    /// Khmer
    case KM
    /// Kannada
    case KN
    /// Korean
    case KO
    /// Kashmiri
    case KS
    /// Kurdish
    case KU
    /// Cornish
    case KW
    /// Kyrgyz
    case KY
    /// Luxembourgish
    case LB
    /// Ganda
    case LG
    /// Lingala
    case LN
    /// Lao
    case LO
    /// Lithuanian
    case LT
    /// Luba-Katanga
    case LU
    /// Latvian
    case LV
    /// Malagasy
    case MG
    /// Māori
    case MI
    /// Macedonian
    case MK
    /// Malayalam
    case ML
    /// Mongolian
    case MN
    /// Marathi
    case MR
    /// Malay
    case MS
    /// Maltese
    case MT
    /// Burmese
    case MY
    /// Norwegian (Bokmål)
    case NB
    /// North Ndebele
    case ND
    /// Nepali
    case NE
    /// Dutch
    case NL
    /// Norwegian Nynorsk
    case NN
    /// Norwegian
    case NO
    /// Oromo
    case OM
    /// Odia
    case OR
    /// Ossetic
    case OS
    /// Punjabi
    case PA
    /// Polish
    case PL
    /// Pashto
    case PS
    /// Portuguese (Brazil)
    case PT_BR
    /// Portuguese (Portugal)
    case PT_PT
    /// Quechua
    case QU
    /// Romansh
    case RM
    /// Rundi
    case RN
    /// Romanian
    case RO
    /// Russian
    case RU
    /// Kinyarwanda
    case RW
    /// Sanskrit
    case SA
    /// Sardinian
    case SC
    /// Sindhi
    case SD
    /// Northern Sami
    case SE
    /// Sango
    case SG
    /// Sinhala
    case SI
    /// Slovak
    case SK
    /// Slovenian
    case SL
    /// Shona
    case SN
    /// Somali
    case SO
    /// Albanian
    case SQ
    /// Serbian
    case SR
    /// Sundanese
    case SU
    /// Swedish
    case SV
    /// Swahili
    case SW
    /// Tamil
    case TA
    /// Telugu
    case TE
    /// Tajik
    case TG
    /// Thai
    case TH
    /// Tigrinya
    case TI
    /// Turkmen
    case TK
    /// Tongan
    case TO
    /// Turkish
    case TR
    /// Tatar
    case TT
    /// Uyghur
    case UG
    /// Ukrainian
    case UK
    /// Urdu
    case UR
    /// Uzbek
    case UZ
    /// Vietnamese
    case VI
    /// Wolof
    case WO
    /// Xhosa
    case XH
    /// Yiddish
    case YI
    /// Yoruba
    case YO
    /// Chinese (Simplified)
    case ZH_CN
    /// Chinese (Traditional)
    case ZH_TW
    /// Zulu
    case ZU
    /// Chinese
    case ZH
    /// Portuguese
    case PT
    /// Church Slavic
    case CU
    /// Volapük
    case VO
    /// Latin
    case LA
    /// Serbo-Croatian
    case SH
    /// Moldavian
    case MO
}
