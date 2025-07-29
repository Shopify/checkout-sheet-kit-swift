/*
 MIT License

 Copyright 2023 - Present, Shopify Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/// A protocol that enables fluent configuration of accelerated checkout components.
/// This protocol allows both programmatic and SwiftUI components to share configuration methods.
@available(iOS 17.0, *)
public protocol AcceleratedCheckoutConfigurable {
    /// Sets the corner radius for checkout buttons
    /// - Parameter cornerRadius: The corner radius to apply (negative values will use default)
    /// - Returns: Self for method chaining
    func cornerRadius(_ cornerRadius: CGFloat) -> Self
}

// MARK: - AcceleratedCheckoutViewController Configuration

@available(iOS 17.0, *)
extension AcceleratedCheckoutViewController: AcceleratedCheckoutConfigurable {
    /// Sets the corner radius for checkout buttons
    /// - Parameter cornerRadius: The corner radius to apply (negative values will use default)
    /// - Returns: Self for method chaining
    public func cornerRadius(_ cornerRadius: CGFloat) -> Self {
        // For the programmatic interface, corner radius would need to be stored and applied
        // when the wallet buttons are actually presented. This could be enhanced in the future.
        return self
    }
}