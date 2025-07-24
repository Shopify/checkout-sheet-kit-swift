// swift-tools-version: 5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShopifyCheckoutSheetKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ShopifyCheckoutSheetKit",
            targets: ["ShopifyCheckoutSheetKit"]
        ),
        .library(
            name: "ShopifyAcceleratedCheckouts",
            targets: ["ShopifyAcceleratedCheckouts"]
        ),
        .library(
            name: "Common",
            targets: ["Common"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/lukepistrol/SwiftLintPlugin", from: "0.2.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Common",
            dependencies: []
        ),
        .target(
            name: "ShopifyCheckoutSheetKit",
            dependencies: ["Common"]
        ),
        .target(
            name: "ShopifyAcceleratedCheckouts",
            dependencies: ["ShopifyCheckoutSheetKit", "Common"],
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "CommonTests",
            dependencies: ["Common"],
            plugins: [
                .plugin(name: "SwiftLint", package: "SwiftLintPlugin")
            ]
        ),
        .testTarget(
            name: "ShopifyCheckoutSheetKitTests",
            dependencies: ["ShopifyCheckoutSheetKit"],
            plugins: [
                .plugin(name: "SwiftLint", package: "SwiftLintPlugin")
            ]
        ),
        .testTarget(
            name: "ShopifyAcceleratedCheckoutsTests",
            dependencies: ["ShopifyAcceleratedCheckouts"],
            plugins: [
                .plugin(name: "SwiftLint", package: "SwiftLintPlugin")
            ]
        )
    ]
)
