//
//  SourceLocationTests.swift
//  IndexStoreTests
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import XCTest

@testable import IndexStore

final class SourceLocationTests: XCTestCase {
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
        XCTAssertEqual(location.description, "test-module::test-path::123::12")
    }
}
