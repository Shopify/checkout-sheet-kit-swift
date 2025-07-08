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

//
//  GraphQLDocument+Mutations.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 24/06/2025.
//

extension GraphQLDocument {
    enum Mutations: String, CaseIterable {
        case cartCreate = """
        mutation CartCreate($input: CartInput!) {
          cartCreate(input: $input) {
            cart {
              ...CartFragment
            }
            userErrors {
              ...CartUserErrorFragment
            }
          }
        }
        """

        case cartBuyerIdentityUpdate = """
        mutation CartBuyerIdentityUpdate($cartId: ID!, $buyerIdentity: CartBuyerIdentityInput!) {
          cartBuyerIdentityUpdate(cartId: $cartId, buyerIdentity: $buyerIdentity) {
            cart {
              ...CartFragment
            }
            userErrors {
              ...CartUserErrorFragment
            }
          }
        }
        """

        case cartDeliveryAddressesAdd = """
        mutation CartDeliveryAddressesAdd($cartId: ID!, $addresses: [CartSelectableAddressInput!]!) {
          cartDeliveryAddressesAdd(cartId: $cartId, addresses: $addresses) {
            cart {
              ...CartFragment
            }
            userErrors {
              ...CartUserErrorFragment
            }
          }
        }
        """

        case cartDeliveryAddressesUpdate = """
        mutation CartDeliveryAddressesUpdate($cartId: ID!, $addresses: [CartSelectableAddressUpdateInput!]!) {
          cartDeliveryAddressesUpdate(cartId: $cartId, addresses: $addresses) {
            cart {
              ...CartFragment
            }
            userErrors {
              ...CartUserErrorFragment
            }
          }
        }
        """

        case cartSelectedDeliveryOptionsUpdate = """
        mutation CartSelectedDeliveryOptionsUpdate($cartId: ID!, $selectedDeliveryOptions: [CartSelectedDeliveryOptionInput!]!) {
          cartSelectedDeliveryOptionsUpdate(cartId: $cartId, selectedDeliveryOptions: $selectedDeliveryOptions) {
            cart {
              ...CartFragment
            }
            userErrors {
              ...CartUserErrorFragment
            }
          }
        }
        """

        case cartPaymentUpdate = """
        mutation CartPaymentUpdate($cartId: ID!, $payment: CartPaymentInput!) {
          cartPaymentUpdate(cartId: $cartId, payment: $payment) {
            cart {
              ...CartFragment
            }
            userErrors {
              ...CartUserErrorFragment
            }
          }
        }
        """

        case cartRemovePersonalData = """
        mutation CartRemovePersonalData($cartId: ID!) {
          cartRemovePersonalData(cartId: $cartId) {
            cart {
              ...CartFragment
            }
            userErrors {
              ...CartUserErrorFragment
            }
          }
        }
        """

        case cartPrepareForCompletion = """
        mutation CartPrepareForCompletion($cartId: ID!) {
          cartPrepareForCompletion(cartId: $cartId) {
            result {
              __typename
                                          ... on CartStatusReady {
                cart {
                  ...CartFragment
                }
              }
              ... on CartThrottled {
                pollAfter
              }
              ... on CartStatusNotReady {
                cart {
                  ...CartFragment
                }
                errors {
                  code
                  message
                }
              }
            }
            userErrors {
              ...CartUserErrorFragment
            }
          }
        }
        """

        case cartSubmitForCompletion = """
        mutation CartSubmitForCompletion($cartId: ID!, $attemptToken: String!) {
          cartSubmitForCompletion(cartId: $cartId, attemptToken: $attemptToken) {
            result {
              __typename
                            ... on SubmitSuccess {
                    redirectUrl
                  }
              ... on SubmitFailed {
                checkoutUrl
                errors {
                  code
                  message
                }
              }
              ... on SubmitAlreadyAccepted {
                attemptId
              }
              ... on SubmitThrottled {
                pollAfter
              }
            }
            userErrors {
              ...CartUserErrorFragment
            }
          }
        }
        """
    }
}
