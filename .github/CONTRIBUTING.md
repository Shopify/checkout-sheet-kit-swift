# Contributing

The following is a set of guidelines for contributing to the project. Please take a moment to read through them before submitting your first PR.

## Code of Conduct

This project and everyone participating in it are governed by the [Code of Conduct](/.github/CODE_OF_CONDUCT.md).
By participating, you are expected to uphold this code. Please report unacceptable
behavior to [opensource@shopify.com](mailto:opensource@shopify.com).

## Welcomed Contributions

- Reporting issues with existing features
- Bug fixes
- Performance improvements
- Documentation
- Usability Improvements

## Things we won't merge

- Additional dependencies that limit sdk use (e.g. swift dependencies)
- Any changes that break existing tests
- Any changes without sufficient tests

## Proposing Features

When in doubt about whether we will be interested in including a new feature in this project, please open an issue to propose the feature so we can confirm the feature should be in scope for the project before it is implemented.

**NOTE**: Issues that have not been active for 30 days will be marked as stale, and subsequently closed after a further 7 days of inactivity.

## How To Contribute

1. Fork the repo and branch off of main
2. Create a feature branch in your fork
3. Make changes and add any relevant relevant tests
4. Verify the changes locally (e.g. via the sample app)
5. Commit your changes and push
6. Ensure all checks (e.g. tests) are passing in GitHub
7. Create a new pull request with a detailed description of what is changing and why

## Releasing a new version

### Preparing for a release

Before creating a release, ensure the following version strings are updated and synchronized:

1. Bump the [package version](https://github.com/Shopify/checkout-sheet-kit-swift/blob/main/Sources/ShopifyCheckoutSheetKit/ShopifyCheckoutSheetKit.swift#L27)
2. Bump the [podspec version](https://github.com/Shopify/checkout-sheet-kit-swift/blob/main/ShopifyCheckoutSheetKit.podspec#L2)
3. Add an entry to the top of the [CHANGELOG](../CHANGELOG.md)

**Important**: All three version strings must match exactly, including any pre-release suffixes (e.g., `-beta.1`, `-rc.1`).

### Version format

- **Production releases**: `X.Y.Z` (e.g., `3.4.0`)
- **Pre-releases**: `X.Y.Z-{alpha|beta|rc}.N` (e.g., `3.4.0-beta.1`, `3.4.0-rc.2`)

Pre-release suffixes ensure:
- CocoaPods users must explicitly opt-in to install pre-release versions
- Swift Package Manager doesn't treat them as the default "latest" version

### Creating a release

Navigate to https://github.com/Shopify/checkout-sheet-kit-swift/releases and click "Draft a new release", then complete the following steps:

#### For production releases (from `main` branch):

1. Ensure you're on the `main` branch
2. Create a tag for the new version (e.g., `3.4.0`)
3. Use the same tag as the release title
4. Document the full list of changes since the previous release, tagging merged pull requests where applicable
5. ✅ Check "Set as the latest release" to ensure Swift Package Manager identifies this as the latest release
6. Click "Publish release"

#### For pre-releases (from non-`main` branch):

1. Ensure you're on a feature/release branch (NOT `main`)
2. Create a tag with a pre-release suffix (e.g., `3.4.0-beta.1`, `3.4.0-rc.2`)
3. Use the same tag as the release title
4. Document the changes being tested in this pre-release
5. ✅ Check "Set as a pre-release" (NOT "Set as the latest release")
6. Click "Publish release"

### What happens after publishing

When you publish a release (production or pre-release), the [publish workflow](https://github.com/Shopify/checkout-sheet-kit-swift/actions/workflows/publish.yml) will automatically:

1. **Validate versions**: Ensures podspec, Swift package, and git tag versions all match
2. **Deploy to CocoaPods**: Publishes the version to CocoaPods trunk
3. **Swift Package Manager**: Automatically works from the git tag (no deployment needed)

### Using pre-releases

For users to install a pre-release version:

**CocoaPods** - Must specify the exact version in Podfile:
```ruby
pod 'ShopifyCheckoutSheetKit', '3.4.0-beta.1'
```

**Swift Package Manager** - Must specify the exact version:
```swift
.package(url: "https://github.com/Shopify/checkout-sheet-kit-swift", exact: "3.4.0-beta.1")
```
