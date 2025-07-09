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
import XCTest

@testable import ShopifyAcceleratedCheckouts

enum TestError: Error {
    case expected
    case different
}

actor CountActor {
    var attempts = 0

    func addAttempt() {
        attempts += 1
    }
}

class TaskTests: XCTestCase {
    func testTaskRetriesCorrectNumberOfTimes() async throws {
        let actor = CountActor()

        do {
            _ = try await Task.retrying(maxRetryCount: 3) {
                await actor.addAttempt()
                throw TestError.expected
            }.value
        } catch {
            // Expected to throw after all retries
        }

        // Ensure all actor updates have completed by yielding
        await Task.yield()

        // Should attempt first run + 3 retries = 4 total
        let attempts = await actor.attempts
        XCTAssertEqual(attempts, 4)
    }

    func testTaskSucceedsOnFirstAttempt() async throws {
        let actor = CountActor()

        let result = try await Task.retrying {
            await actor.addAttempt()
            return "success"
        }.value

        let attempts = await actor.attempts
        XCTAssertEqual(attempts, 1)
        XCTAssertEqual(result, "success")
    }

    func testTaskSucceedsOnSecondAttempt() async throws {
        let actor = CountActor()

        let result = try await Task.retrying {
            await actor.addAttempt()
            let currentAttempts = await actor.attempts
            if currentAttempts == 1 {
                throw TestError.expected
            }
            return "success"
        }.value

        let attempts = await actor.attempts
        XCTAssertEqual(attempts, 2)
        XCTAssertEqual(result, "success")
    }

    func testTaskRespectsCustomMaxRetryCount() async throws {
        let actor = CountActor()

        do {
            _ = try await Task.retrying(maxRetryCount: 2) {
                await actor.addAttempt()
                throw TestError.expected
            }.value
        } catch {
            // Expected to throw after all retries
        }

        // Ensure all actor updates have completed by yielding
        await Task.yield()

        // Should attempt first run + 2 retries = 3 total
        let attempts = await actor.attempts
        XCTAssertEqual(attempts, 3)
    }

    func testTaskWithZeroRetriesStillAttemptsOnce() async throws {
        let actor = CountActor()

        do {
            _ = try await Task.retrying(maxRetryCount: 0) {
                await actor.addAttempt()
                throw TestError.expected
            }.value
        } catch {
            // Expected to throw
        }

        // Ensure all actor updates have completed by yielding
        await Task.yield()

        // Should attempt 0 times in loop + 1 final attempt = 1 total
        let attempts = await actor.attempts
        XCTAssertEqual(attempts, 1)
    }

    func testTaskRetryDelayWorks() async throws {
        let startTime = Date()
        let actor = CountActor()

        do {
            _ = try await Task.retrying(maxRetryCount: 2, retryDelay: 0.1) {
                await actor.addAttempt()
                throw TestError.expected
            }.value
        } catch {
            // Expected to throw
        }

        let elapsed = Date().timeIntervalSince(startTime)

        // Ensure all actor updates have completed by yielding
        await Task.yield()

        // Should have waited at least 0.2 seconds (2 delays of 0.1 each)
        XCTAssertGreaterThanOrEqual(elapsed, 0.2)
        let attempts = await actor.attempts
        XCTAssertEqual(attempts, 3)
    }

    // Flaky
    func testTaskPropagatesCorrectError() async throws {
        do {
            _ = try await Task.retrying {
                throw TestError.different
            }.value

            XCTFail("Task should have thrown")
        } catch {
            XCTAssertTrue(error is TestError)
            // swiftlint:disable force_cast
            let error = error as! TestError
            // swiftlint:enable force_cast
            guard case .different = error else {
                XCTFail("Incorrect error thrown")
                return
            }
        }
    }

    // MARK: - Exponential Delay Tests

    func testExponentialDelayAttempt1BaseDelay1() {
        let delay = exponentialDelay(for: 1, with: 1.0)
        let oneSecond = TimeInterval(1_000_000_000)
        let expected = UInt64(2.0 * oneSecond)
        XCTAssertEqual(delay, expected, "Attempt 1 with base 1.0s should delay 2.0s")
    }

    func testExponentialDelayAttempt2BaseDelay1() {
        let delay = exponentialDelay(for: 2, with: 1.0)
        let oneSecond = TimeInterval(1_000_000_000)
        let expected = UInt64(4.0 * oneSecond)
        XCTAssertEqual(delay, expected, "Attempt 2 with base 1.0s should delay 4.0s")
    }

    func testExponentialDelayAttempt3BaseDelay1() {
        let delay = exponentialDelay(for: 3, with: 1.0)
        let oneSecond = TimeInterval(1_000_000_000)
        let expected = UInt64(8.0 * oneSecond)
        XCTAssertEqual(delay, expected, "Attempt 3 with base 1.0s should delay 8.0s")
    }

    func testExponentialDelayAttempt4BaseDelay1() {
        let delay = exponentialDelay(for: 4, with: 1.0)
        let oneSecond = TimeInterval(1_000_000_000)
        let expected = UInt64(16.0 * oneSecond)
        XCTAssertEqual(delay, expected, "Attempt 4 with base 1.0s should delay 16.0s")
    }

    func testExponentialDelayAttempt1BaseDelayPointOne() {
        let delay = exponentialDelay(for: 1, with: 0.1)
        let oneSecond = TimeInterval(1_000_000_000)
        let expected = UInt64(0.2 * oneSecond)
        XCTAssertEqual(delay, expected, "Attempt 1 with base 0.1s should delay 0.2s")
    }

    func testExponentialDelayAttempt2BaseDelayPointOne() {
        let delay = exponentialDelay(for: 2, with: 0.1)
        let oneSecond = TimeInterval(1_000_000_000)
        let expected = UInt64(0.4 * oneSecond)
        XCTAssertEqual(delay, expected, "Attempt 2 with base 0.1s should delay 0.4s")
    }

    func testExponentialDelayAttempt0BaseDelay1() {
        let delay = exponentialDelay(for: 0, with: 1.0)
        let oneSecond = TimeInterval(1_000_000_000)
        let expected = UInt64(1.0 * oneSecond)
        XCTAssertEqual(delay, expected, "Attempt 0 with base 1.0s should delay 1.0s")
    }

    func testExponentialDelayRespectsCap() {
        let baseDelay: TimeInterval = 10.0 // 10 seconds

        // At attempt 3: 10 * 2^3 = 80s, should be capped at 30s
        let delay = exponentialDelay(for: 3, with: baseDelay)
        let oneSecond = TimeInterval(1_000_000_000)

        XCTAssertEqual(delay, UInt64(30.0 * oneSecond))
    }

    func testExponentialDelayReturnsNanoseconds() {
        let baseDelay: TimeInterval = 1.0

        let delay = exponentialDelay(for: 1, with: baseDelay)

        // Should be 2 billion nanoseconds (2 seconds)
        XCTAssertEqual(delay, 2_000_000_000)
    }
}
