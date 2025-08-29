Pod::Spec.new do |s|
  s.version = "3.4.0-rc.7"

  s.name    = "ShopifyCheckoutSheetKit"
  s.summary = "Enables Swift apps to embed the Shopify's highest converting, customizable, one-page checkout."
  s.author  = "Shopify Inc."

  s.homepage  = "https://github.com/Shopify/checkout-sheet-kit-swift"
  s.readme    = "https://github.com/Shopify/checkout-sheet-kit-swift/blob/main/README.md"
  s.changelog = "https://github.com/Shopify/checkout-sheet-kit-swift/releases"
  s.license   = { :type => "MIT", :file => "LICENSE" }

  s.source = {
    :git => "https://github.com/Shopify/checkout-sheet-kit-swift.git", :tag => s.version.to_s
  }

  s.swift_version = "5.0"

  s.ios.deployment_target = "13.0"

  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-package-name ShopifyCheckoutSheetKit -DCOCOAPODS'
  }

  s.default_subspecs = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = 'Sources/ShopifyCheckoutSheetKit/**/*.swift'
    core.resource_bundles = {
      'ShopifyCheckoutSheetKit' => ['Sources/ShopifyCheckoutSheetKit/Assets.xcassets']
    }
  end

  s.subspec 'AcceleratedCheckouts' do |accelerated|
    accelerated.source_files = 'Sources/ShopifyAcceleratedCheckouts/**/*.swift'
    accelerated.dependency 'ShopifyCheckoutSheetKit/Core'
    accelerated.resource_bundles = {
      'ShopifyAcceleratedCheckouts' => ['Sources/ShopifyAcceleratedCheckouts/Localizable.xcstrings', 'Sources/ShopifyAcceleratedCheckouts/Media.xcassets']
    }
  end
end
