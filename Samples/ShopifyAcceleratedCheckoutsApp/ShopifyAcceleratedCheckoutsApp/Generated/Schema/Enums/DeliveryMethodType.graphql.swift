// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    /// List of different delivery method types.
    enum DeliveryMethodType: String, EnumType {
        /// Shipping.
        case shipping = "SHIPPING"
        /// Local Pickup.
        case pickUp = "PICK_UP"
        /// Retail.
        case retail = "RETAIL"
        /// Local Delivery.
        case local = "LOCAL"
        /// Shipping to a Pickup Point.
        case pickupPoint = "PICKUP_POINT"
        /// None.
        case none = "NONE"
    }
}
