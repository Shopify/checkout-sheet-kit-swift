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

import Foundation

public enum MetaData {
    /// The version of the `ShopifyCheckoutSheetKit` library.
    package static let version = "3.4.0-rc.8"
    /// The schema version of the CheckoutSheetProtocol.
    package static let schemaVersion = "8.1"

    /// In time this will be used to track the top level package that is
    /// making API calls or is the initiator of CSK.
    /// For now this is exclusive to AcceleratedCheckouts to ensure backwards
    /// compatibility.
    public enum EntryPoint: String {
        case acceleratedCheckouts = "AcceleratedCheckouts"
    }

    public enum Platform: String {
        case iOS
        case reactNative = "ReactNative"
    }
}
