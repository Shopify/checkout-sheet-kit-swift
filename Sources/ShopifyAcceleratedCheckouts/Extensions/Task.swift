//
//  Task.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 03/06/2025.
//

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
        operation: @Sendable @escaping () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            for attempt in 0 ..< maxRetryCount {
                do {
                    return try await operation()
                } catch {
                    try await Task<Never, Never>.sleep(
                        nanoseconds: exponentialDelay(for: attempt, with: retryDelay))

                    continue
                }
            }

            try Task<Never, Never>.checkCancellation()
            return try await operation()
        }
    }
}
