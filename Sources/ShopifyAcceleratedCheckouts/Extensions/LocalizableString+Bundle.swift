//
//  LocalizableString+Bundle.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 05/06/2025.
//

import SwiftUI

extension Bundle {
    func localizedString(forKey key: String) -> String {
        localizedString(forKey: key, value: nil, table: nil)
    }
}

extension String {
    var localizedString: String {
        Bundle.module.localizedString(forKey: self)
    }
}
