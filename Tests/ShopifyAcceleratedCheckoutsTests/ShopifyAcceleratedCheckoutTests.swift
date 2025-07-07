@testable import ShopifyAcceleratedCheckouts
import XCTest

class ShopifyAcceleratedCheckoutsTests: XCTestCase {
    func testVersionIsPublic() {
        XCTAssertEqual(ShopifyAcceleratedCheckouts.version, "0.0.1")
    }
}
