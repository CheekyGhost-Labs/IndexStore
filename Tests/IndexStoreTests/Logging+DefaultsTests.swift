//
//  LoggingDefaultsTests.swift
//  IndexStoreTests
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Logging
import XCTest

@testable import IndexStore

final class LoggingDefaultsTests: XCTestCase {
    // MARK: - Tests

    func test_default_willReturnExpectedLogger() {
        XCTAssertEqual(Logger.default.label, "com.cheekyghost.IndexStore")
    }
}
