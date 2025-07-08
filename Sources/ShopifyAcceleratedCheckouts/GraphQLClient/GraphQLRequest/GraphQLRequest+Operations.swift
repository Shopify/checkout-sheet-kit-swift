//
//  GraphQLRequest+Operations.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 27/06/2025.
//

enum Operations {
    static func cartCreate(
        variables: [String: Any] = [:]
    ) -> GraphQLRequest<StorefrontAPI.CartCreateResponse> {
        return GraphQLRequest(
            operation: .cartCreate,
            responseType: StorefrontAPI.CartCreateResponse.self,
            variables: variables
        )
    }

    static func cartBuyerIdentityUpdate(
        variables: [String: Any] = [:]
    ) -> GraphQLRequest<StorefrontAPI.CartBuyerIdentityUpdateResponse> {
        return GraphQLRequest(
            operation: .cartBuyerIdentityUpdate,
            responseType: StorefrontAPI.CartBuyerIdentityUpdateResponse.self,
            variables: variables
        )
    }

    static func cartDeliveryAddressesAdd(
        variables: [String: Any] = [:]
    ) -> GraphQLRequest<StorefrontAPI.CartDeliveryAddressesAddResponse> {
        return GraphQLRequest(
            operation: .cartDeliveryAddressesAdd,
            responseType: StorefrontAPI.CartDeliveryAddressesAddResponse.self,
            variables: variables
        )
    }

    static func cartDeliveryAddressesUpdate(
        variables: [String: Any] = [:]
    ) -> GraphQLRequest<StorefrontAPI.CartDeliveryAddressesUpdateResponse> {
        return GraphQLRequest(
            operation: .cartDeliveryAddressesUpdate,
            responseType: StorefrontAPI.CartDeliveryAddressesUpdateResponse.self,
            variables: variables
        )
    }

    static func cartSelectedDeliveryOptionsUpdate(
        variables: [String: Any] = [:]
    ) -> GraphQLRequest<StorefrontAPI.CartSelectedDeliveryOptionsUpdateResponse> {
        return GraphQLRequest(
            operation: .cartSelectedDeliveryOptionsUpdate,
            responseType: StorefrontAPI.CartSelectedDeliveryOptionsUpdateResponse.self,
            variables: variables
        )
    }

    static func cartPaymentUpdate(
        variables: [String: Any] = [:]
    ) -> GraphQLRequest<StorefrontAPI.CartPaymentUpdateResponse> {
        return GraphQLRequest(
            operation: .cartPaymentUpdate,
            responseType: StorefrontAPI.CartPaymentUpdateResponse.self,
            variables: variables
        )
    }

    static func cartRemovePersonalData(
        variables: [String: Any] = [:]
    ) -> GraphQLRequest<StorefrontAPI.CartRemovePersonalDataResponse> {
        return GraphQLRequest(
            operation: .cartRemovePersonalData,
            responseType: StorefrontAPI.CartRemovePersonalDataResponse.self,
            variables: variables
        )
    }

    static func cartPrepareForCompletion(
        variables: [String: Any] = [:]
    ) -> GraphQLRequest<StorefrontAPI.CartPrepareForCompletionResponse> {
        return GraphQLRequest(
            operation: .cartPrepareForCompletion,
            responseType: StorefrontAPI.CartPrepareForCompletionResponse.self,
            variables: variables
        )
    }

    static func cartSubmitForCompletion(
        variables: [String: Any] = [:]
    ) -> GraphQLRequest<StorefrontAPI.CartSubmitForCompletionResponse> {
        return GraphQLRequest(
            operation: .cartSubmitForCompletion,
            responseType: StorefrontAPI.CartSubmitForCompletionResponse.self,
            variables: variables
        )
    }

    static func getCart(
        variables: [String: Any] = [:]
    ) -> GraphQLRequest<StorefrontAPI.CartQueryResponse> {
        return GraphQLRequest(
            operation: .cart,
            responseType: StorefrontAPI.CartQueryResponse.self,
            variables: variables
        )
    }

    static func getProducts(
        variables: [String: Any] = [:]
    ) -> GraphQLRequest<StorefrontAPI.ProductsQueryResponse> {
        return GraphQLRequest(
            operation: .products,
            responseType: StorefrontAPI.ProductsQueryResponse.self,
            variables: variables
        )
    }

    static func getShop(
        variables: [String: Any] = [:]
    ) -> GraphQLRequest<StorefrontAPI.ShopQueryResponse> {
        return GraphQLRequest(
            operation: .shop,
            responseType: StorefrontAPI.ShopQueryResponse.self,
            variables: variables
        )
    }
}
