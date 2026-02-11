// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShopifyCheckoutSheetKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ShopifyCheckoutSheetKit",
            targets: ["ShopifyCheckoutSheetKit"]
        ),
        // TODO: [UCP Migration] Re-enable after migrating AcceleratedCheckouts to CheckoutBridgeHandler
        // .library(
        //     name: "ShopifyAcceleratedCheckouts",
        //     targets: ["ShopifyAcceleratedCheckouts"]
        // )
    ],
    dependencies: [
        .package(url: "https://github.com/lukepistrol/SwiftLintPlugin", from: "0.2.2"),
        // .package(url: "https://github.com/nalexn/ViewInspector", from: "0.10.0")
    ],
    targets: [
        .target(
            name: "ShopifyCheckoutSheetKit",
            dependencies: [],
            resources: [.process("Assets.xcassets")]
        ),
        // TODO: [UCP Migration] Re-enable after migrating AcceleratedCheckouts to CheckoutBridgeHandler
        // .target(
        //     name: "ShopifyAcceleratedCheckouts",
        //     dependencies: ["ShopifyCheckoutSheetKit"],
        //     resources: [.process("Localizable.xcstrings"), .process("Media.xcassets")]
        // ),
        .testTarget(
            name: "ShopifyCheckoutSheetKitTests",
            dependencies: ["ShopifyCheckoutSheetKit"],
            plugins: [
                .plugin(name: "SwiftLint", package: "SwiftLintPlugin")
            ]
        ),
        // TODO: [UCP Migration] Re-enable after migrating AcceleratedCheckouts to CheckoutBridgeHandler
        // .testTarget(
        //     name: "ShopifyAcceleratedCheckoutsTests",
        //     dependencies: [
        //         "ShopifyAcceleratedCheckouts",
        //         .product(name: "ViewInspector", package: "ViewInspector")
        //     ],
        //     plugins: [
        //         .plugin(name: "SwiftLint", package: "SwiftLintPlugin")
        //     ]
        // )
    ]
)
