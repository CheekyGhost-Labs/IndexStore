//
//  ProcessInfoExtensionTests.swift
//  IndexStoreTests
//
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import XCTest

@testable import IndexStore

final class ProcessInfoExtensionTests: XCTestCase {

    func test_missingEnvironmentKey_willThrowExpectedError() throws {
        let expectedError = ProcessInfoError.unableToFindValueForKey("missing")
        XCTAssertThrowsError(try ProcessInfo().environmentVariable(name: "missing")) { error in
            XCTAssertEqual(error as? ProcessInfoError, expectedError)
        }
    }

    func test_presentEnvironmentKey_willReturnExpectedValue() throws {
        let result = try? ProcessInfo().environmentVariable(name: EnvironmentKeys.PWD)
        XCTAssertNotNil(result)
    }
}
