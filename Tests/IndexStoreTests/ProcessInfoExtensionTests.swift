//
//  ProcessInfoExtensionTests.swift
//  IndexStoreTests
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
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

    func test_processInfoError_willOutputExpectedDescriptions() throws {
        let error = ProcessInfoError.unableToFindValueForKey("test")
        XCTAssertEqual(error.code, 0)
        XCTAssertEqual(error.failureReason, "Unable to resolve value for key: `test`")
        XCTAssertEqual(error.recoverySuggestion, "Review the `environment` property to ensure expected values are present. Environment values change depending on where the process is running from")
    }
}
