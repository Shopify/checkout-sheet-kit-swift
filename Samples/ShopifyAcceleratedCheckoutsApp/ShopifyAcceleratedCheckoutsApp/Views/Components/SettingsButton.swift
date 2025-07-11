//
//  SettingsButton.swift
//  ShopifyAcceleratedCheckoutsApp
//

import ShopifyAcceleratedCheckouts
import SwiftUI

struct SettingsButton: View {
    @Binding var applePayConfiguration: ShopifyAcceleratedCheckouts.ApplePayConfiguration

    var body: some View {
        NavigationLink(
            destination: SettingsView(applePayConfiguration: $applePayConfiguration)
        ) {
            Text("Settings")
        }
    }
}
