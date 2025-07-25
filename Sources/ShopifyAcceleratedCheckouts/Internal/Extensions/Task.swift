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

import Combine
import Foundation
import PassKit

let oneSecond = TimeInterval(1_000_000_000)

func exponentialDelay(for attempt: Int = 1, with retryDelay: TimeInterval) -> UInt64 {
    // Calculate exponential backoff: baseDelay * (2 ^ attempt)
    let backoffMultiplier = pow(2.0, Double(attempt))
    let delayInSeconds = retryDelay * backoffMultiplier

    // Cap the maximum delay at 30 seconds
    let cappedDelay = min(delayInSeconds, 30.0)

    // Convert to nanoseconds
    let delayInNanoseconds = cappedDelay * oneSecond

    return UInt64(delayInNanoseconds)
}

extension Task where Failure == Error {
    @discardableResult static func retrying(
        priority: TaskPriority? = nil,
        maxRetryCount: Int = 3,
        retryDelay: TimeInterval = 1,
        clock: Clock = SystemClock(),
        operation: @Sendable @escaping () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            for attempt in 0 ..< maxRetryCount {
                do {
                    return try await operation()
                } catch {
                    try await clock.sleep(
                        nanoseconds: exponentialDelay(for: attempt, with: retryDelay))

                    continue
                }
            }

            try Task<Never, Never>.checkCancellation()
            return try await operation()
        }
    }
}
