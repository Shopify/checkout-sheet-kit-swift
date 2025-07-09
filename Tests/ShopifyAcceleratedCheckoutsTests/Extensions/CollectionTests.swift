
import Foundation
@testable import ShopifyAcceleratedCheckouts
import XCTest

class CollectionTests: XCTestCase {
    // MARK: - Array Tests

    func testArraySafeSubscriptReturnsElementAtValidIndex() {
        let array = [1, 2, 3, 4, 5]

        XCTAssertEqual(array[safe: 0], 1)
        XCTAssertEqual(array[safe: 2], 3)
        XCTAssertEqual(array[safe: 4], 5)
    }

    func testArraySafeSubscriptReturnsNilForNegativeIndex() {
        let array = [1, 2, 3]

        XCTAssertNil(array[safe: -1])
        XCTAssertNil(array[safe: -5])
    }

    func testArraySafeSubscriptReturnsNilForOutOfBoundsIndex() {
        let array = [1, 2, 3]

        XCTAssertNil(array[safe: 3])
        XCTAssertNil(array[safe: 10])
    }

    func testArraySafeSubscriptWorksWithEmptyArray() {
        let array: [Int] = []

        XCTAssertNil(array[safe: 0])
        XCTAssertNil(array[safe: -1])
        XCTAssertNil(array[safe: 1])
    }

    func testArraySafeSubscriptWorksWithSingleElement() {
        let array = [42]

        XCTAssertEqual(array[safe: 0], 42)
        XCTAssertNil(array[safe: 1])
        XCTAssertNil(array[safe: -1])
    }

    // MARK: - String Tests

    func testStringSafeSubscriptReturnsCharacterAtValidIndex() {
        let string = "Hello"
        let startIndex = string.startIndex

        XCTAssertEqual(string[safe: startIndex], "H")
        XCTAssertEqual(string[safe: string.index(startIndex, offsetBy: 1)], "e")
        XCTAssertEqual(string[safe: string.index(startIndex, offsetBy: 4)], "o")
    }

    func testStringSafeSubscriptReturnsNilForInvalidIndex() {
        let string = "Hello"
        let endIndex = string.endIndex

        XCTAssertNil(string[safe: endIndex])
    }

    func testStringSafeSubscriptWorksWithEmptyString() {
        let string = ""
        let startIndex = string.startIndex

        XCTAssertNil(string[safe: startIndex])
    }

    // MARK: - Set Tests

    func testSetSafeSubscriptWorksCorrectly() {
        let set: Set<String> = ["apple", "banana", "cherry"]

        // For Set, we can only test with valid indices from the set itself
        if let firstIndex = set.indices.first {
            XCTAssertNotNil(set[safe: firstIndex])
            XCTAssertTrue(set.contains(set[safe: firstIndex]!))
        }
    }

    // MARK: - Dictionary Tests

    func testDictionarySafeSubscriptWorksCorrectly() {
        let dict = ["a": 1, "b": 2, "c": 3]

        // For Dictionary, we test with valid indices from the dictionary itself
        if let firstIndex = dict.indices.first {
            let keyValuePair = dict[safe: firstIndex]
            XCTAssertNotNil(keyValuePair)
            XCTAssertEqual(dict[keyValuePair!.key], keyValuePair!.value)
        }
    }

    // MARK: - Range Tests

    func testRangeSafeSubscriptWorksCorrectly() {
        let range = 1 ... 5
        let startIndex = range.startIndex

        XCTAssertEqual(range[safe: startIndex], 1)
        XCTAssertEqual(range[safe: range.index(startIndex, offsetBy: 2)], 3)
        XCTAssertEqual(range[safe: range.index(startIndex, offsetBy: 4)], 5)
    }

    // MARK: - Custom Collection Tests

    func testCustomCollectionSafeSubscriptWorksCorrectly() {
        // Test with ArraySlice (a view into an array)
        let array = [10, 20, 30, 40, 50]
        let slice = array[1 ... 3] // [20, 30, 40]

        let startIndex = slice.startIndex
        XCTAssertEqual(slice[safe: startIndex], 20)
        XCTAssertEqual(slice[safe: slice.index(startIndex, offsetBy: 1)], 30)

        XCTAssertEqual(slice[safe: slice.index(startIndex, offsetBy: 2)], 40)

        // Test out of bounds for slice
        let endIndex = slice.endIndex
        XCTAssertNil(slice[safe: endIndex])
    }

    // MARK: - Edge Cases

    func testArraySafeSubscriptWithDifferentTypes() {
        let stringArray = ["first", "second", "third"]
        let optionalArray: [String?] = ["a", nil, "c"]
        let objectArray = [NSObject(), NSObject()]

        XCTAssertEqual(stringArray[safe: 1], "second")

        // Test valid index with nil element - should return .some(nil)
        let elementAtIndex1 = optionalArray[safe: 1]
        XCTAssertNotNil(elementAtIndex1 as Any?) // The optional wrapper exists
        XCTAssertNil(elementAtIndex1!) // But the actual element is nil

        XCTAssertEqual(optionalArray[safe: 0], "a")
        let outOfBoundsElement = optionalArray[safe: 3]
        XCTAssertNil(outOfBoundsElement as Any?) // Out of bounds - returns .none
        XCTAssertNotNil(objectArray[safe: 0])
        XCTAssertNil(objectArray[safe: 2]) // Out of bounds
    }

    func testPerformanceWithLargeArray() {
        let largeArray = Array(0 ..< 10000)

        // Test various indices
        XCTAssertEqual(largeArray[safe: 0], 0)
        XCTAssertEqual(largeArray[safe: 5000], 5000)
        XCTAssertEqual(largeArray[safe: 9999], 9999)
        XCTAssertNil(largeArray[safe: 10000])
        XCTAssertNil(largeArray[safe: -1])
    }
}
