import Foundation

public protocol Logger {
	func log(_ message: String)
}

public class NoOpLogger: Logger {
	public func log(_ message: String) {

	}
}

