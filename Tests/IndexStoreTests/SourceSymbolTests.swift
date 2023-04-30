//
//  SourceSymbolTests.swift
//  IndexStoreTests
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import XCTest

@testable import IndexStore

final class SourceSymbolTests: XCTestCase {

    // MARK: - Properties

    var indexStore: IndexStore!

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        try super.setUpWithError()
        let configPath = "\(Bundle.module.resourcePath ?? "")/Configurations/test_configuration.json"
        let configuration = try IndexStore.Configuration.fromJson(at: configPath)
        indexStore = IndexStore(configuration: configuration, logger: .test)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        indexStore = nil
    }

    // MARK: - Tests

    func test_description_returnsExpectedValue() {
        let location = SourceLocation(
            path: "test-path",
            moduleName: "test-module",
            line: 123,
            column: 12,
            offset: 12,
            isSystem: false,
            isStale: true
        )
        let details = SourceSymbol(name: "test-name", usr: "test-usr", sourceKind: .enum, roles: .declaration, location: location)
        XCTAssertEqual(details.description, "test-name - enum | test-module::test-path::123::12")
    }

    func test_id_returnsExpectedValue() {
        let location = SourceLocation(
            path: "test-path",
            moduleName: "test-module",
            line: 123,
            column: 12,
            offset: 12,
            isSystem: false,
            isStale: true
        )
        let details = SourceSymbol(name: "test-name", usr: "test-usr", sourceKind: .enum, roles: .declaration, location: location)
        XCTAssertEqual(details.id, "test-usr::test-name::test-path::123::12")
    }

    func test_sourceSymbols_parentIterator_willReturnExpectedValue() throws {
        let results = indexStore.querySymbols(.structDeclarations(matching: "DoubleNestedStruct"))
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
