//
//  SourceSymbolCollectionTests.swift
//  IndexStoreTests
//
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import XCTest

@testable import IndexStore

final class SourceSymbolCollectionTests: XCTestCase {

    // MARK: - Tests

    func test_makeIterator_willReturnExpectedValue() throws {
        let location = SourceLocation(path: "path", line: 0, column: 0, offset: 0, isSystem: false, isStale: false)
        let items: [SourceSymbol] = [
            SourceSymbol(name: "0", usr: "0", sourceKind: .struct, roles: .declaration, location: location),
            SourceSymbol(name: "1", usr: "1", sourceKind: .struct, roles: .declaration, location: location),
            SourceSymbol(name: "2", usr: "2", sourceKind: .struct, roles: .declaration, location: location),
        ]
        let additional = SourceSymbol(name: "3", usr: "3", sourceKind: .struct, roles: .declaration, location: location)
        var collection = SourceDetailsCollection(items: items)
        collection.append(additional)
        XCTAssertEqual(collection.items, items + [additional])
        XCTAssertEqual(collection.count, 4)
        let instanceUnderTest = collection.makeIterator()
        XCTAssertEqual(instanceUnderTest.next()?.name, "0")
        XCTAssertEqual(instanceUnderTest.next()?.name, "1")
        XCTAssertEqual(instanceUnderTest.next()?.name, "2")
        XCTAssertEqual(instanceUnderTest.next()?.name, "3")
        let directIterator = SourceDetailsIterator(collection)
        XCTAssertEqual(directIterator.count, 4)
        let otherIterator = SourceDetailsIterator(collection)
        XCTAssertEqual(directIterator, otherIterator)
    }
}
