//
//  IndexStoreQueryTests.swift
//
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import IndexStore
import XCTest

final class IndexStoreQueryTests: XCTestCase {
    // MARK: - Tests: Standard

    func test_builder_query_willAssignExpectedValues() throws {
        var instanceUnderTest = IndexStoreQuery(query: "test")
        XCTAssertEqual(instanceUnderTest.query, "test")
        instanceUnderTest = instanceUnderTest
            .withQuery("other")
            .withSourceFiles(["test"])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withIgnoringCase(true)
            .withInlcudeSubsequences(true)
            .withRestrictingToProjectDirectory(true)
        XCTAssertEqual(instanceUnderTest.query, "other")
        XCTAssertEqual(instanceUnderTest.sourceFiles, ["test"])
        XCTAssertTrue(instanceUnderTest.anchorStart)
        XCTAssertTrue(instanceUnderTest.anchorEnd)
        XCTAssertTrue(instanceUnderTest.ignoreCase)
        XCTAssertTrue(instanceUnderTest.includeSubsequence)
        XCTAssertTrue(instanceUnderTest.restrictToProjectDirectory)
        instanceUnderTest = instanceUnderTest
            .withQuery(nil)
            .withSourceFiles(nil)
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withIgnoringCase(true)
            .withInlcudeSubsequences(true)
            .withRestrictingToProjectDirectory(true)
        XCTAssertNil(instanceUnderTest.query)
        XCTAssertNil(instanceUnderTest.sourceFiles)
        XCTAssertTrue(instanceUnderTest.anchorStart)
        XCTAssertTrue(instanceUnderTest.anchorEnd)
        XCTAssertTrue(instanceUnderTest.ignoreCase)
        XCTAssertTrue(instanceUnderTest.includeSubsequence)
        XCTAssertTrue(instanceUnderTest.restrictToProjectDirectory)
    }

    func test_builder_sourceFiles_willAssignExpectedValues() throws {
        var instanceUnderTest = IndexStoreQuery(sourceFiles: ["test"])
        XCTAssertEqual(instanceUnderTest.sourceFiles, ["test"])
        instanceUnderTest = instanceUnderTest
            .withQuery("query")
            .withSourceFiles(["other"])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withIgnoringCase(true)
            .withInlcudeSubsequences(true)
            .withRestrictingToProjectDirectory(true)
        XCTAssertEqual(instanceUnderTest.query, "query")
        XCTAssertEqual(instanceUnderTest.sourceFiles, ["other"])
        XCTAssertTrue(instanceUnderTest.anchorStart)
        XCTAssertTrue(instanceUnderTest.anchorEnd)
        XCTAssertTrue(instanceUnderTest.ignoreCase)
        XCTAssertTrue(instanceUnderTest.includeSubsequence)
        XCTAssertTrue(instanceUnderTest.restrictToProjectDirectory)
        instanceUnderTest = instanceUnderTest
            .withQuery(nil)
            .withSourceFiles(nil)
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withIgnoringCase(true)
            .withInlcudeSubsequences(true)
            .withRestrictingToProjectDirectory(true)
        XCTAssertNil(instanceUnderTest.query)
        XCTAssertNil(instanceUnderTest.sourceFiles)
        XCTAssertTrue(instanceUnderTest.anchorStart)
        XCTAssertTrue(instanceUnderTest.anchorEnd)
        XCTAssertTrue(instanceUnderTest.ignoreCase)
        XCTAssertTrue(instanceUnderTest.includeSubsequence)
        XCTAssertTrue(instanceUnderTest.restrictToProjectDirectory)
    }

    // MARK: - Tests: Conveniences: Function

    func test_functions_query_willReturnExpectedResult() {
        let expected = IndexStoreQuery(query: "test")
            .withKinds(SourceKind.allFunctions)
            .withRoles([.definition, .childOf, .canonical])
            .withAnchorStart(false)
            .withAnchorEnd(false)
            .withInlcudeSubsequences(true)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.functions("test"), expected)
    }

    func test_functions_sourceFiles_willReturnExpectedResult() {
        let expectedFilesOnly = IndexStoreQuery(sourceFiles: ["test"])
            .withQuery(nil)
            .withKinds(SourceKind.allFunctions)
            .withRoles([.definition, .childOf, .canonical])
            .withAnchorStart(false)
            .withAnchorEnd(false)
            .withInlcudeSubsequences(true)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.functions(in: ["test"]), expectedFilesOnly)
        let expectedFilesAndQuery = IndexStoreQuery(query: "test")
            .withSourceFiles(["test"])
            .withKinds(SourceKind.allFunctions)
            .withRoles([.definition, .childOf, .canonical])
            .withAnchorStart(false)
            .withAnchorEnd(false)
            .withInlcudeSubsequences(true)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.functions(in: ["test"], matching: "test"), expectedFilesAndQuery)
    }

    // MARK: - Tests: Conveniences: Extension

    func test_extensions_query_willReturnExpectedResult() {
        let expected = IndexStoreQuery(query: "test")
            .withKinds([.extension])
            .withRoles([.definition])
            .withAnchorStart(false)
            .withAnchorEnd(false)
            .withInlcudeSubsequences(true)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.extensions(ofType: "test"), expected)
    }

    func test_extensions_sourceFiles_willReturnExpectedResult() {
        let expectedFilesOnly = IndexStoreQuery(sourceFiles: ["test"])
            .withQuery(nil)
            .withKinds([.extension])
            .withRoles([.definition])
            .withAnchorStart(false)
            .withAnchorEnd(false)
            .withInlcudeSubsequences(true)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.extensions(in: ["test"]), expectedFilesOnly)
        let expectedFilesAndQuery = IndexStoreQuery(query: "test")
            .withSourceFiles(["test"])
            .withKinds([.extension])
            .withRoles([.definition])
            .withAnchorStart(false)
            .withAnchorEnd(false)
            .withInlcudeSubsequences(true)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.extensions(in: ["test"], matching: "test"), expectedFilesAndQuery)
    }

    // MARK: - Tests: Conveniences: Declarations

    func test_allDeclarations_query_willReturnExpectedResult() {
        let expected = IndexStoreQuery(query: "test")
            .withKinds(SourceKind.declarations)
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.allDeclarations(matching: "test"), expected)
    }

    func test_allDeclarations_sourceFiles_willReturnExpectedResult() {
        let expectedFilesOnly = IndexStoreQuery(sourceFiles: ["test"])
            .withQuery(nil)
            .withKinds(SourceKind.declarations)
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.allDeclarations(in: ["test"]), expectedFilesOnly)
        let expectedFilesAndQuery = IndexStoreQuery(query: "test")
            .withSourceFiles(["test"])
            .withKinds(SourceKind.declarations)
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.allDeclarations(in: ["test"], matching: "test"), expectedFilesAndQuery)
    }

    // MARK: - Tests: Conveniences: Classes

    func test_classDeclarations_query_willReturnExpectedResult() {
        let expected = IndexStoreQuery(query: "test")
            .withKinds([.class])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.classDeclarations(matching: "test"), expected)
    }

    func test_classDeclarations_sourceFiles_willReturnExpectedResult() {
        let expectedFilesOnly = IndexStoreQuery(sourceFiles: ["test"])
            .withQuery(nil)
            .withKinds([.class])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.classDeclarations(in: ["test"]), expectedFilesOnly)
        let expectedFilesAndQuery = IndexStoreQuery(query: "test")
            .withSourceFiles(["test"])
            .withKinds([.class])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.classDeclarations(in: ["test"], matching: "test"), expectedFilesAndQuery)
    }

    // MARK: - Tests: Conveniences: Structs

    func test_structDeclarations_query_willReturnExpectedResult() {
        let expected = IndexStoreQuery(query: "test")
            .withKinds([.struct])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.structDeclarations(matching: "test"), expected)
    }

    func test_structDeclarations_sourceFiles_willReturnExpectedResult() {
        let expectedFilesOnly = IndexStoreQuery(sourceFiles: ["test"])
            .withQuery(nil)
            .withKinds([.struct])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.structDeclarations(in: ["test"]), expectedFilesOnly)
        let expectedFilesAndQuery = IndexStoreQuery(query: "test")
            .withSourceFiles(["test"])
            .withKinds([.struct])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.structDeclarations(in: ["test"], matching: "test"), expectedFilesAndQuery)
    }

    // MARK: - Tests: Conveniences: Enum

    func test_enumDeclarations_query_willReturnExpectedResult() {
        let expected = IndexStoreQuery(query: "test")
            .withKinds([.enum])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.enumDeclarations(matching: "test"), expected)
    }

    func test_enumDeclarations_sourceFiles_willReturnExpectedResult() {
        let expectedFilesOnly = IndexStoreQuery(sourceFiles: ["test"])
            .withQuery(nil)
            .withKinds([.enum])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.enumDeclarations(in: ["test"]), expectedFilesOnly)
        let expectedFilesAndQuery = IndexStoreQuery(query: "test")
            .withSourceFiles(["test"])
            .withKinds([.enum])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.enumDeclarations(in: ["test"], matching: "test"), expectedFilesAndQuery)
    }

    // MARK: - Tests: Conveniences: Typealias

    func test_typealiasDeclarations_query_willReturnExpectedResult() {
        let expected = IndexStoreQuery(query: "test")
            .withKinds([.typealias])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.typealiasDeclarations(matching: "test"), expected)
    }

    func test_typealiasDeclarations_sourceFiles_willReturnExpectedResult() {
        let expectedFilesOnly = IndexStoreQuery(sourceFiles: ["test"])
            .withQuery(nil)
            .withKinds([.typealias])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.typealiasDeclarations(in: ["test"]), expectedFilesOnly)
        let expectedFilesAndQuery = IndexStoreQuery(query: "test")
            .withSourceFiles(["test"])
            .withKinds([.typealias])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.typealiasDeclarations(in: ["test"], matching: "test"), expectedFilesAndQuery)
    }

    // MARK: - Tests: Conveniences: Protocols

    func test_protocolDeclarations_query_willReturnExpectedResult() {
        let expected = IndexStoreQuery(query: "test")
            .withKinds([.protocol])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.protocolDeclarations(matching: "test"), expected)
    }

    func test_protocolDeclarations_sourceFiles_willReturnExpectedResult() {
        let expectedFilesOnly = IndexStoreQuery(sourceFiles: ["test"])
            .withQuery(nil)
            .withKinds([.protocol])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.protocolDeclarations(in: ["test"]), expectedFilesOnly)
        let expectedFilesAndQuery = IndexStoreQuery(query: "test")
            .withSourceFiles(["test"])
            .withKinds([.protocol])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
        XCTAssertEqual(IndexStoreQuery.protocolDeclarations(in: ["test"], matching: "test"), expectedFilesAndQuery)
    }
}
