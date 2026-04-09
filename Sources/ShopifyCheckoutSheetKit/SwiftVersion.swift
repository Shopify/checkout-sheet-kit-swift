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

/// Compile-time resolved Swift language and compiler version information.
/// These ladders use `#if swift(>=X.Y)` and `#if compiler(>=X.Y)` checks
/// which are forward-compatible — future compilers will match the highest
/// applicable condition.
enum SwiftVersion {
    /// The Swift language version the code is compiled under.
    /// Determined by `-swift-version` flag or compiler default.
    static var languageVersion: String {
        #if swift(>=7.0)
        return "7.0"
        #elseif swift(>=6.5)
        return "6.5"
        #elseif swift(>=6.4)
        return "6.4"
        #elseif swift(>=6.3)
        return "6.3"
        #elseif swift(>=6.2)
        return "6.2"
        #elseif swift(>=6.1)
        return "6.1"
        #elseif swift(>=6.0)
        return "6.0"
        #elseif swift(>=5.10)
        return "5.10"
        #elseif swift(>=5.9)
        return "5.9"
        #elseif swift(>=5.8)
        return "5.8"
        #elseif swift(>=5.7)
        return "5.7"
        #elseif swift(>=5.6)
        return "5.6"
        #elseif swift(>=5.5)
        return "5.5"
        #elseif swift(>=5.4)
        return "5.4"
        #elseif swift(>=5.3)
        return "5.3"
        #else
        return "unknown"
        #endif
    }

    /// The Swift compiler (toolchain) version used to build the code.
    static var compilerVersion: String {
        #if compiler(>=7.0)
        return "7.0"
        #elseif compiler(>=6.5)
        return "6.5"
        #elseif compiler(>=6.4)
        return "6.4"
        #elseif compiler(>=6.3)
        return "6.3"
        #elseif compiler(>=6.2)
        return "6.2"
        #elseif compiler(>=6.1)
        return "6.1"
        #elseif compiler(>=6.0)
        return "6.0"
        #elseif compiler(>=5.10)
        return "5.10"
        #elseif compiler(>=5.9)
        return "5.9"
        #elseif compiler(>=5.8)
        return "5.8"
        #elseif compiler(>=5.7)
        return "5.7"
        #elseif compiler(>=5.6)
        return "5.6"
        #elseif compiler(>=5.5)
        return "5.5"
        #elseif compiler(>=5.4)
        return "5.4"
        #elseif compiler(>=5.3)
        return "5.3"
        #else
        return "unknown"
        #endif
    }
}
