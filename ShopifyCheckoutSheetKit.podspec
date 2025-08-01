Pod::Spec.new do |s|
  s.version = "3.4.0-rc.1"

  s.name    = "ShopifyCheckoutSheetKit"
  s.summary = "Enables Swift apps to embed the Shopify's highest converting, customizable, one-page checkout."
  s.author  = "Shopify Inc."

  s.homepage  = "https://github.com/Shopify/checkout-sheet-kit-swift"
  s.readme    = "https://github.com/Shopify/checkout-sheet-kit-swift/blob/main/README.md"
  s.changelog = "https://github.com/Shopify/checkout-sheet-kit-swift/blob/main/CHANGELOG.md"
  s.license   = { :type => "MIT", :file => "LICENSE" }

  s.source = {
    :git => "https://github.com/Shopify/checkout-sheet-kit-swift.git", :tag => s.version.to_s
  }

  s.swift_version = "5.0"

  s.ios.deployment_target = "13.0"

  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-package-name ShopifyCheckoutSheetKit -module-alias Common=ShopifyCheckoutSheetKit'
  }

  s.source_files = "Sources/Common/**/*.swift", "Sources/ShopifyCheckoutSheetKit/**/*.swift"

  s.resource_bundles = {
    "ShopifyCheckoutSheetKit" => ["Sources/ShopifyCheckoutSheetKit/Assets.xcassets"]
  }
end
