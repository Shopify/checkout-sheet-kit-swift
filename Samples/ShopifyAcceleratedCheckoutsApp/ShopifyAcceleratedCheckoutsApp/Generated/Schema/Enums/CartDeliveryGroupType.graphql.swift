// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    /// Defines what type of merchandise is in the delivery group.
    enum CartDeliveryGroupType: String, EnumType {
        /// The delivery group only contains subscription merchandise.
        case subscription = "SUBSCRIPTION"
        /// The delivery group only contains merchandise that is either a one time purchase or a first delivery of
        /// subscription merchandise.
        case oneTimePurchase = "ONE_TIME_PURCHASE"
    }
}
