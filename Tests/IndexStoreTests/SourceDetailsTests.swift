//
//  SourceDetailsTests.swift
//  IndexStoreTests
//
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import XCTest

@testable import IndexStore

final class SourceDetailsTests: XCTestCase {

    // MARK: - Tests

    func test_description_returnsExpectedValue() {
        let location = SourceLocation(path: "test-path", line: 123, column: 12, offset: 12, isStale: true)
        let details = SourceDetails(name: "test-name", usr: "test-usr", sourceKind: .enum, roles: .declaration, location: location)
        XCTAssertEqual(details.description, "test-name | enum | test-path:123:12")
    }

    func test_id_returnsExpectedValue() {
        let location = SourceLocation(path: "test-path", line: 123, column: 12, offset: 12, isStale: true)
        let details = SourceDetails(name: "test-name", usr: "test-usr", sourceKind: .enum, roles: .declaration, location: location)
        XCTAssertEqual(details.id, "test-usr:test-name:test-path:123:12")
    }

    func test_sourceDetails_parentIterator_willReturnExpectedValue() throws {
        let sourceResolver = try IndexStore(configuration: Configuration(projectDirectory: ""), logger: .test)
        let results = sourceResolver.sourceDetails(matchingType: "DoubleNestedStruct", kinds: [.struct])
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        let iterator = targetResult.parentsIterator
        var nextParent = iterator.next()
        XCTAssertEqual(nextParent?.name, "NestedStruct")
        XCTAssertEqual(nextParent?.sourceKind, .struct)
        XCTAssertEqual(nextParent?.location.line, 5)
        XCTAssertEqual(nextParent?.location.column, 12)
        XCTAssertEqual(nextParent?.location.offset, 12)
        nextParent = iterator.next()
        XCTAssertEqual(nextParent?.name, "RootStruct")
        XCTAssertEqual(nextParent?.sourceKind, .struct)
        XCTAssertEqual(nextParent?.location.line, 3)
        XCTAssertEqual(nextParent?.location.column, 8)
        XCTAssertEqual(nextParent?.location.offset, 8)
    }
}
