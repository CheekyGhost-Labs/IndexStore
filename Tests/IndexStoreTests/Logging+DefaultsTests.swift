//
//  LoggingDefaultsTests.swift
//  IndexStoreTests
//
//  Created by CheekyGhost Labs on 19/4/2023.
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import XCTest
import Logging
@testable import IndexStore

final class LoggingDefaultsTests: XCTestCase {

    // MARK: - Tests

    func test_default_willReturnExpectedLogger() {
        XCTAssertEqual(Logger.default.label, "com.cheekyghost.IndexStore")
    }
}
