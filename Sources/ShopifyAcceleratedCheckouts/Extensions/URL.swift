//
//  URL.swift
//  ShopifyAcceleratedCheckouts
//

import Foundation

extension URL {
    func appendQueryParam(name: String?, value: String?) -> URL? {
        guard
            let name,
            var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false)
        else {
            return nil
        }

        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(URLQueryItem(name: name, value: value))
        urlComponents.queryItems = queryItems

        return urlComponents.url
    }
}
