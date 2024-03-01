//
//  Fragment+CheckoutQuery.swift
//  Storefront
//
//  Created by Shopify.
//  Copyright (c) 2017 Shopify Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Buy

extension Storefront.CheckoutQuery {
    
    @discardableResult
    func fragmentForCheckout() -> Storefront.CheckoutQuery { return self
        .id()
        .ready()
        .requiresShipping()
        .taxesIncluded()
        .email()
        
        .discountApplications(first: 250) { $0
            .edges { $0
                .node { $0
                    .fragmentForDiscountApplication()
                }
            }
        }
        
        .shippingDiscountAllocations { $0
            .fragmentForDiscountAllocation()
        }
        
        .appliedGiftCards { $0
            .id()
            .balance { $0
                .amount()
                .currencyCode()
            }
            .amountUsed { $0
                .amount()
                .currencyCode()
            }
            .lastCharacters()
        }
        
        .shippingAddress { $0
            .firstName()
            .lastName()
            .phone()
            .address1()
            .address2()
            .city()
            .country()
            .countryCodeV2()
            .province()
            .provinceCode()
            .zip()
        }
        
        .shippingLine { $0
            .handle()
            .title()
            .price { $0
                .amount()
                .currencyCode()
            }
        }
        
        .note()
        .lineItems(first: 250) { $0
            .edges { $0
                .cursor()
                .node { $0
                    .variant { $0
                        .id()
                        .price { $0
                            .amount()
                            .currencyCode()
                        }
                    }
                    .title()
                    .quantity()
                    .discountAllocations { $0
                        .fragmentForDiscountAllocation()
                    }
                }
            }
        }
        .totalDuties { $0
            .amount()
            .currencyCode()
        }
        .webUrl()
        .currencyCode()
        .subtotalPrice { $0
            .amount()
            .currencyCode()
        }
        .totalTax { $0
            .amount()
            .currencyCode()
        }
        .totalPrice { $0
            .amount()
            .currencyCode()
        }
        .paymentDue { $0
            .amount()
            .currencyCode()
        }
    }
}
