// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    /// The preferred delivery methods such as shipping, local pickup or through pickup points.
    enum PreferenceDeliveryMethodType: String, EnumType {
        /// A delivery method used to send items directly to a buyer’s specified address.
        case shipping = "SHIPPING"
        /// A delivery method used to let buyers receive items directly from a specific location within an area.
        case pickUp = "PICK_UP"
        /// A delivery method used to let buyers collect purchases at designated locations like parcel lockers.
        case pickupPoint = "PICKUP_POINT"
    }
}
