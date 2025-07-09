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
//  GraphQLDocument+Queries.swift
//  ShopifyAcceleratedCheckouts
//

extension GraphQLDocument {
    enum Queries: String {
        case cart = """
        query GetCart($id: ID!) {
          cart(id: $id) {
            ...CartFragment
          }
        }
        """

        case products = """
        query GetProducts($first: Int = 10) {
          products(first: $first) {
            nodes {
              id
              title
              variants(first: 10) {
                nodes {
                  id
                  title
                  requiresShipping
                  price {
                    amount
                    currencyCode
                  }
                }
              }
            }
          }
        }
        """

        case shop = """
        query GetShop {
          shop {
            name
            description
            primaryDomain {
              host
              sslEnabled
              url
            }
            shipsToCountries
            paymentSettings {
              supportedDigitalWallets
              acceptedCardBrands
              countryCode
            }
            moneyFormat
          }
        }
        """
    }
}
