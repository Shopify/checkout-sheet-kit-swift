Pod::Spec.new do |s|
  s.version = "0.8.0"

  s.name    = "ShopifyCheckoutKit"
  s.summary = "Enables Swift apps to embed the Shopify's highest converting, customizable, one-page checkout."
  s.author  = "Shopify Inc."

  s.homepage  = "https://github.com/Shopify/checkout-kit-swift"
  s.readme    = "https://github.com/Shopify/checkout-kit-swift/blob/main/README.md"
  s.changelog = "https://github.com/Shopify/checkout-kit-swift/blob/main/CHANGELOG.md"
  s.license   = { :type => "MIT", :file => "LICENSE" }

  s.source = {
    :git => "https://github.com/Shopify/checkout-kit-swift.git", :tag => s.version.to_s
  }

  s.swift_version = "5.0"

  s.ios.deployment_target = "13.0"

  s.source_files = "Sources/ShopifyCheckoutKit/**/*.swift"

  s.resource_bundles = {
    "ShopifyCheckoutKit" => ["Sources/ShopifyCheckoutKit/Assets.xcassets"]
  }
end
