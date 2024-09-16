// swift-tools-version: 5.7.1
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
    ],
    dependencies: [
        .package(url: "https://github.com/lukepistrol/SwiftLintPlugin", from: "0.2.2"),
        .package(url: "https://github.com/shopify/opentelemetry-swift", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ShopifyCheckoutSheetKit",
            dependencies: [
                .product(name: "OpenTelemetryApi", package: "opentelemetry-swift"),
                .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift")
            ]
        ),
        .testTarget(
            name: "ShopifyCheckoutSheetKitTests",
            dependencies: ["ShopifyCheckoutSheetKit"],
            plugins: [
                .plugin(name: "SwiftLint", package: "SwiftLintPlugin")
            ]
        )
    ]
)
