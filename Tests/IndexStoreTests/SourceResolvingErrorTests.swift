//
//  SourceResolvingErrorTests.swift
//  IndexStoreTests
//
//  Created by CheekyGhost Labs on 19/4/2023.
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import XCTest
@testable import IndexStore

final class SourceResolvingErrorTests: XCTestCase {

    // MARK: - Properties
    let errors: [SourceResolvingError] = [
        .sourcePathDoesNotExist(path: "test-path"),
        .sourceContentsIsEmpty(path: "test-path"),
        .unableToReadContents(path: "test-path", cause: "test-cause"),
        .unableToResolveSourceLine(name: "test-name", path: "test-path", line: 123),
    ]

    // MARK: - Tests

    func test_code_returnsExpectedValue() {
        var expectedCode: Int = 0
        errors.forEach {
            XCTAssertEqual($0.code, expectedCode)
            expectedCode += 1
        }
    }

    func test_failureReason_returnsExpectedValue() {
        let expectedFailureReasons = [
            "No source file exists for path: `test-path`",
            "Source contents is empty for file at path: `test-path`",
            "Unable to read contents empty for file at path: `test-path`. Cause: `test-cause`",
            "Unable to resolve declaration line `123` for `test-name` in file at path: `test-path`.",
        ]
        for (index, error) in errors.enumerated() {
            XCTAssertEqual(error.errorDescription, expectedFailureReasons[index])
            XCTAssertEqual(error.failureReason, expectedFailureReasons[index])
        }
    }

    func test_recoverySuggestion_returnsExpectedValue() {
        let expectedFailureReasons = [
            "The source reference is probably cached in the index but the file has been removed. Please restore the file or ignore the declaration",
            "The contents of the resolved source path is empty. The source reference is probably cached in the index but the contents has been removed. This is treated as an error due to the reference not being present.",
            "The contents of the resolved source path was not able to be read. Please review the `cause` and ensure adequate permissions are granted.",
            "The contents of the resolved source path were found but the line in the source details instance was not resolvable. The reference is probably a cached reference but the file has been modified. Please ensure any indexing has completed and try again.",
        ]
        for (index, error) in errors.enumerated() {
            XCTAssertEqual(error.recoverySuggestion, expectedFailureReasons[index])
        }
    }
}
