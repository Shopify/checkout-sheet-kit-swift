//
//  PaymentData.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 22/05/2025.
//

import PassKit

struct PaymentData: Codable {
    let data, signature: String
    let header: Header
    let version: String
}

struct Header: Codable {
    let transactionId: String
    let ephemeralPublicKey, publicKeyHash: String
}

func decodePaymentData(payment: PKPayment) -> PaymentData? {
    try? JSONDecoder().decode(
        PaymentData.self,
        from: payment.token.paymentData
    )
}
