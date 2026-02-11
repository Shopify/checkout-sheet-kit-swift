import Foundation

public enum CheckoutErrorCode: String, Codable {
    case storefrontPasswordRequired = "storefront_password_required"
    case cartExpired = "cart_expired"
    case cartCompleted = "cart_completed"
    case invalidCart = "invalid_cart"
    case unknown

    public static func from(_ code: String?) -> CheckoutErrorCode {
        let fallback = CheckoutErrorCode.unknown

        guard let errorCode = code else {
            return fallback
        }

        return CheckoutErrorCode(rawValue: errorCode) ?? fallback
    }
}

public enum CheckoutUnavailable {
    case clientError(code: CheckoutErrorCode)
    case httpError(statusCode: Int)
}

public enum CheckoutError: Swift.Error {
    case sdkError(underlying: Swift.Error, recoverable: Bool = true)

    case checkoutUnavailable(message: String, code: CheckoutUnavailable, recoverable: Bool)

    case checkoutExpired(message: String, code: CheckoutErrorCode, recoverable: Bool = false)

    public var isRecoverable: Bool {
        switch self {
        case let .checkoutExpired(_, _, recoverable),
             let .checkoutUnavailable(_, _, recoverable),
             let .sdkError(_, recoverable):
            return recoverable
        }
    }
}
