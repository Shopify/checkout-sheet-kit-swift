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

extension GraphQLDocument {
    enum Fragments: String, CaseIterable {
        case cart = """
        fragment CartFragment on Cart {
          id
          checkoutUrl
          totalQuantity
          buyerIdentity {
            email
            phone
            customer {
                email
                phone
            }
          }
          deliveryGroups(first: 10) {
            nodes {
              ...CartDeliveryGroupFragment
            }
          }
          delivery {
            addresses {
              id
              selected
              address {
                ... on CartDeliveryAddress {
                  address1
                  address2
                  city
                  countryCode
                  firstName
                  lastName
                  phone
                  provinceCode
                  zip
                }
              }
            }
          }
          lines(first: 250) {
            nodes {
              ...CartLineFragment
            }
          }
          cost {
            totalAmount {
              amount
              currencyCode
            }
            subtotalAmount {
              amount
              currencyCode
            }
            totalTaxAmount {
              amount
              currencyCode
            }
            totalDutyAmount {
              amount
              currencyCode
            }
          }
          discountCodes {
            applicable
            code
          }
          discountAllocations {
            __typename
            ... on CartAutomaticDiscountAllocation {
              discountedAmount {
                amount
                currencyCode
              }
              targetType
              discountApplication {
                targetSelection
                targetType
                value {
                  __typename
                  ... on MoneyV2 {
                    amount
                    currencyCode
                  }
                  ... on PricingPercentageValue {
                    percentage
                  }
                }
              }
            }
            ... on CartCodeDiscountAllocation {
              code
              discountedAmount {
                amount
                currencyCode
              }
              targetType
              discountApplication {
                targetSelection
                targetType
                value {
                  __typename
                  ... on MoneyV2 {
                    amount
                    currencyCode
                  }
                  ... on PricingPercentageValue {
                    percentage
                  }
                }
              }
            }
            ... on CartCustomDiscountAllocation {
              discountedAmount {
                amount
                currencyCode
              }
              targetType
              discountApplication {
                targetSelection
                targetType
                value {
                  __typename
                  ... on MoneyV2 {
                    amount
                    currencyCode
                  }
                  ... on PricingPercentageValue {
                    percentage
                  }
                }
              }
            }
          }
        }
        """

        case cartDeliveryGroup = """
        fragment CartDeliveryGroupFragment on CartDeliveryGroup {
          id
          groupType
          deliveryOptions {
            handle
            title
            code
            deliveryMethodType
            description
            estimatedCost {
              amount
              currencyCode
            }
          }
          selectedDeliveryOption {
            handle
            title
            code
            deliveryMethodType
            description
            estimatedCost {
              amount
              currencyCode
            }
          }
        }
        """

        case cartLine = """
        fragment CartLineFragment on BaseCartLine {
          id
          quantity
          merchandise {
            ... on ProductVariant {
              id
              title
              price {
                amount
                currencyCode
              }
              product {
                title
                vendor
                featuredImage {
                  url
                }
              }
              requiresShipping
            }
          }
          cost {
            totalAmount {
              amount
              currencyCode
            }
            subtotalAmount {
              amount
              currencyCode
            }
          }
          discountAllocations {
            __typename
            ... on CartAutomaticDiscountAllocation {
              discountedAmount {
                amount
                currencyCode
              }
              targetType
              discountApplication {
                targetSelection
                targetType
                value {
                  __typename
                  ... on MoneyV2 {
                    amount
                    currencyCode
                  }
                  ... on PricingPercentageValue {
                    percentage
                  }
                }
              }
            }
            ... on CartCodeDiscountAllocation {
              code
              discountedAmount {
                amount
                currencyCode
              }
              targetType
              discountApplication {
                targetSelection
                targetType
                value {
                  __typename
                  ... on MoneyV2 {
                    amount
                    currencyCode
                  }
                  ... on PricingPercentageValue {
                    percentage
                  }
                }
              }
            }
            ... on CartCustomDiscountAllocation {
              discountedAmount {
                amount
                currencyCode
              }
              targetType
              discountApplication {
                targetSelection
                targetType
                value {
                  __typename
                  ... on MoneyV2 {
                    amount
                    currencyCode
                  }
                  ... on PricingPercentageValue {
                    percentage
                  }
                }
              }
            }
          }
        }
        """

        case cartUserError = """
        fragment CartUserErrorFragment on CartUserError {
          code
          message
          field
        }
        """

        static var all: String {
            allCases.map(\.rawValue).joined(separator: "\n\n")
        }
    }
}
