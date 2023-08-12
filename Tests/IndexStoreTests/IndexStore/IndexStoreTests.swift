//
//  IndexStoreTests.swift
//  IndexStoreTests
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import XCTest

@testable import IndexStore

final class IndexStoreTests: XCTestCase {
    // MARK: - Properties

    var instanceUnderTest: IndexStore!

    var sampleSourceFilePaths: [String] {
        instanceUnderTest.swiftSourceFiles().filter {
            $0.contains("IndexStoreTests/Samples") && !$0.contains("InvocationTestCase")
        }
    }

    var sampleTestCaseFiles: [String] {
        instanceUnderTest.swiftSourceFiles().filter {
            $0.contains("IndexStoreTests/Samples") && $0.contains("InvocationTestCase")
        }
    }

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        try super.setUpWithError()
        let configPath = "\(Bundle.module.resourcePath ?? "")/Configurations/test_configuration.json"
        let configuration = try IndexStore.Configuration.fromJson(at: configPath)
        instanceUnderTest = IndexStore(configuration: configuration, logger: .test)
        instanceUnderTest.pollForChangesAndWait()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        instanceUnderTest = nil
    }

    // MARK: - Helpers

    func pathSuffix(_ sourceName: String) -> String {
        "IndexStore/Tests/IndexStoreTests/Samples/\(sourceName)"
    }

    // MARK: - Tests: Direct

    // NOTE: Expensive task time wise
    func test_querySymbols_inSourceFiles_classes_willReturnExpectedValues() throws {
        let query = IndexStoreQuery.classDeclarations(in: sampleSourceFilePaths)
        let results = instanceUnderTest.querySymbols(query)
        XCTAssertEqual(results.count, 16)
        var result = results[0]
        XCTAssertNil(result.parent)
        XCTAssertEqual(result.name, "RootClass")
        XCTAssertEqual(result.sourceKind, .class)
        XCTAssertTrue(result.location.path.hasSuffix(pathSuffix("Classes.swift")))
        XCTAssertEqual(result.location.line, 3)
        XCTAssertEqual(result.location.column, 7)
        XCTAssertEqual(result.location.offset, 7)
        result = results[1]
        XCTAssertEqual(result.name, "NestedClass")
        XCTAssertEqual(result.sourceKind, .class)
        XCTAssertTrue(result.location.path.hasSuffix(pathSuffix("Classes.swift")))
        XCTAssertEqual(result.location.line, 5)
        XCTAssertEqual(result.location.column, 11)
        XCTAssertEqual(result.location.offset, 11)
        XCTAssertEqual(result.parent?.name, "RootClass")
        // add remainder
    }

    func test_querySymbols_inSourceFiles_rootClass_willReturnExpectedValues() throws {
        let sourceFiles = instanceUnderTest.swiftSourceFiles().filter { $0.contains("IndexStoreTests/Samples") }
        let query = IndexStoreQuery.classDeclarations(in: sourceFiles, matching: "RootClass")
        let results = instanceUnderTest.querySymbols(query)
        XCTAssertEqual(results.count, 1)
        let result = results[0]
        XCTAssertNil(result.parent)
        XCTAssertEqual(result.name, "RootClass")
        XCTAssertEqual(result.sourceKind, .class)
        XCTAssertTrue(result.location.path.hasSuffix(pathSuffix("Classes.swift")))
        XCTAssertEqual(result.location.line, 3)
        XCTAssertEqual(result.location.column, 7)
        XCTAssertEqual(result.location.offset, 7)
    }

    // MARK: - Declarations: Classes

    func test_querySymbols_classes_root_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.classDeclarations(matching: "RootClass"))
        let expectedPathSuffix = pathSuffix("Classes.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "RootClass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 3)
        XCTAssertEqual(targetResult.location.column, 7)
        XCTAssertEqual(targetResult.location.offset, 7)
    }

    func test_querySymbols_classes_nested_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.classDeclarations(matching: "NestedClass"))
        let expectedPathSuffix = pathSuffix("Classes.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertEqual(targetResult.parent?.name, "RootClass")
        XCTAssertEqual(targetResult.parent?.sourceKind, .class)
        XCTAssertEqual(targetResult.name, "NestedClass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 5)
        XCTAssertEqual(targetResult.location.column, 11)
        XCTAssertEqual(targetResult.location.offset, 11)
    }

    func test_querySymbols_classes_doubleNested_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.classDeclarations(matching: "DoubleNestedClass"))
        let expectedPathSuffix = pathSuffix("Classes.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertEqual(targetResult.parent?.name, "NestedClass")
        XCTAssertEqual(targetResult.parent?.sourceKind, .class)
        XCTAssertEqual(targetResult.parent?.parent?.name, "RootClass")
        XCTAssertEqual(targetResult.parent?.parent?.sourceKind, .class)
        XCTAssertEqual(targetResult.name, "DoubleNestedClass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 7)
        XCTAssertEqual(targetResult.location.column, 15)
        XCTAssertEqual(targetResult.location.offset, 15)
    }

    func test_querySymbols_classes_notClassType_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.classDeclarations(matching: "RootStruct"))
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Tests: Declarations: Structs

    func test_querySymbols_structs_root_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.structDeclarations(matching: "RootStruct"))
        let expectedPathSuffix = pathSuffix("Structs.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "RootStruct")
        XCTAssertEqual(targetResult.sourceKind, .struct)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 3)
        XCTAssertEqual(targetResult.location.column, 8)
        XCTAssertEqual(targetResult.location.offset, 8)
    }

    func test_querySymbols_structs_nested_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.structDeclarations(matching: "NestedStruct"))
        let expectedPathSuffix = pathSuffix("Structs.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertEqual(targetResult.parent?.name, "RootStruct")
        XCTAssertEqual(targetResult.parent?.sourceKind, .struct)
        XCTAssertEqual(targetResult.name, "NestedStruct")
        XCTAssertEqual(targetResult.sourceKind, .struct)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 5)
        XCTAssertEqual(targetResult.location.column, 12)
        XCTAssertEqual(targetResult.location.offset, 12)
    }

    func test_querySymbols_structs_doubleNested_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.structDeclarations(matching: "DoubleNestedStruct"))
        let expectedPathSuffix = pathSuffix("Structs.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertEqual(targetResult.parent?.name, "NestedStruct")
        XCTAssertEqual(targetResult.parent?.sourceKind, .struct)
        XCTAssertEqual(targetResult.parent?.parent?.name, "RootStruct")
        XCTAssertEqual(targetResult.parent?.parent?.sourceKind, .struct)
        XCTAssertEqual(targetResult.name, "DoubleNestedStruct")
        XCTAssertEqual(targetResult.sourceKind, .struct)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 7)
        XCTAssertEqual(targetResult.location.column, 16)
        XCTAssertEqual(targetResult.location.offset, 16)
    }

    func test_querySymbols_structs_Inheritance_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.structDeclarations(matching: "InheritanceStruct"))
        let expectedPathSuffix = pathSuffix("Inheritance.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertEqual(targetResult.name, "InheritanceStruct")
        XCTAssertEqual(targetResult.sourceKind, .struct)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 3)
        XCTAssertEqual(targetResult.location.column, 8)
        XCTAssertEqual(targetResult.location.offset, 8)
        XCTAssertEqual(targetResult.inheritance.count, 2)
        var nextInheritance = targetResult.inheritance[0]
        XCTAssertEqual(nextInheritance.name, "ProtocolWithSystemInheritance")
        XCTAssertEqual(nextInheritance.sourceKind, .protocol)
        XCTAssertEqual(nextInheritance.location.line, 5)
        XCTAssertEqual(nextInheritance.location.column, 10)
        XCTAssertEqual(nextInheritance.location.offset, 10)
        XCTAssertTrue(nextInheritance.location.path.hasSuffix("Protocols.swift"))
        nextInheritance = targetResult.inheritance[1]
        XCTAssertEqual(nextInheritance.name, "RootProtocol")
        XCTAssertEqual(nextInheritance.sourceKind, .protocol)
        XCTAssertEqual(nextInheritance.location.line, 3)
        XCTAssertEqual(nextInheritance.location.column, 10)
        XCTAssertEqual(nextInheritance.location.offset, 10)
        XCTAssertTrue(nextInheritance.location.path.hasSuffix("Protocols.swift"))
    }

    func test_querySymbols_structs_notStructType_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.structDeclarations(matching: "RootClass"))
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Tests: Declarations: Enums

    func test_querySymbols_enums_root_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.enumDeclarations(matching: "RootEnum"))
        let expectedPathSuffix = pathSuffix("Enums.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "RootEnum")
        XCTAssertEqual(targetResult.sourceKind, .enum)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 3)
        XCTAssertEqual(targetResult.location.column, 6)
        XCTAssertEqual(targetResult.location.offset, 6)
    }

    func test_querySymbols_enums_nested_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.enumDeclarations(matching: "NestedEnum"))
        let expectedPathSuffix = pathSuffix("Enums.swift")
        XCTAssertEqual(results.count, 3)
        let nestedEnum = results[0]
        XCTAssertEqual(nestedEnum.parent?.name, "RootEnum")
        XCTAssertEqual(nestedEnum.parent?.sourceKind, .enum)
        XCTAssertEqual(nestedEnum.name, "NestedEnum")
        XCTAssertEqual(nestedEnum.sourceKind, .enum)
        XCTAssertTrue(nestedEnum.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(nestedEnum.location.line, 5)
        XCTAssertEqual(nestedEnum.location.column, 10)
        XCTAssertEqual(nestedEnum.location.offset, 10)
        let structEnum = results[1]
        XCTAssertEqual(structEnum.parent?.name, "EnumStruct")
        XCTAssertEqual(structEnum.parent?.sourceKind, .struct)
        XCTAssertEqual(structEnum.name, "NestedEnum")
        XCTAssertEqual(structEnum.sourceKind, .enum)
        XCTAssertTrue(structEnum.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(structEnum.location.line, 15)
        XCTAssertEqual(structEnum.location.column, 10)
        XCTAssertEqual(structEnum.location.offset, 10)
        let classEnum = results[2]
        XCTAssertEqual(classEnum.parent?.name, "ClassEnum")
        XCTAssertEqual(classEnum.parent?.sourceKind, .class)
        XCTAssertEqual(classEnum.name, "NestedEnum")
        XCTAssertEqual(classEnum.sourceKind, .enum)
        XCTAssertTrue(classEnum.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(classEnum.location.line, 22)
        XCTAssertEqual(classEnum.location.column, 10)
        XCTAssertEqual(classEnum.location.offset, 10)
    }

    func test_querySymbols_enums_doubleNested_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.enumDeclarations(matching: "DoubleNestedEnum"))
        let expectedPathSuffix = pathSuffix("Enums.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertEqual(targetResult.parent?.name, "NestedEnum")
        XCTAssertEqual(targetResult.parent?.sourceKind, .enum)
        XCTAssertEqual(targetResult.parent?.parent?.name, "RootEnum")
        XCTAssertEqual(targetResult.parent?.parent?.sourceKind, .enum)
        XCTAssertEqual(targetResult.name, "DoubleNestedEnum")
        XCTAssertEqual(targetResult.sourceKind, .enum)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 7)
        XCTAssertEqual(targetResult.location.column, 14)
        XCTAssertEqual(targetResult.location.offset, 14)
    }

    func test_querySymbols_enums_notEnumType_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.enumDeclarations(matching: "RootClass"))
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Tests: Declarations: Protocols

    func test_querySymbols_protocols_basic_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.protocolDeclarations(matching: "RootProtocol"))
        let expectedPathSuffix = pathSuffix("Protocols.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "RootProtocol")
        XCTAssertEqual(targetResult.sourceKind, .protocol)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 3)
        XCTAssertEqual(targetResult.location.column, 10)
        XCTAssertEqual(targetResult.location.offset, 10)
    }

    func test_querySymbols_protocols_system_inheritance_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.protocolDeclarations(matching: "ProtocolWithSystemInheritance"))
        let expectedPathSuffix = pathSuffix("Protocols.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "ProtocolWithSystemInheritance")
        XCTAssertEqual(targetResult.sourceKind, .protocol)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 5)
        XCTAssertEqual(targetResult.location.column, 10)
        XCTAssertEqual(targetResult.location.offset, 10)
    }

    func test_querySymbols_protocols_custom_inheritance_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.protocolDeclarations(matching: "ProtocolWithInheritance"))
        let expectedPathSuffix = pathSuffix("Protocols.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "ProtocolWithInheritance")
        XCTAssertEqual(targetResult.sourceKind, .protocol)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 9)
        XCTAssertEqual(targetResult.location.column, 10)
        XCTAssertEqual(targetResult.location.offset, 10)
    }

    func test_querySymbols_protocols_notProtocolType_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.protocolDeclarations(matching: "ProtocolName"))
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Tests: Extension

    func test_querySymbols_extension_class_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.extensions(ofType: "RootClass"))
        let expectedPathSuffix = pathSuffix("Extensions.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "RootClass")
        XCTAssertEqual(targetResult.sourceKind, .extension)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 8)
        XCTAssertEqual(targetResult.location.column, 11)
        XCTAssertEqual(targetResult.location.offset, 11)
    }

    func test_querySymbols_extension_class_inSourceFiles_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.extensions(in: sampleTestCaseFiles, matching: "XCTestCase"))
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "XCTestCase")
        XCTAssertEqual(targetResult.sourceKind, .extension)
        XCTAssertTrue(targetResult.location.path.hasSuffix(pathSuffix("InvocationTestCase.swift")))
        XCTAssertEqual(targetResult.location.line, 17)
        XCTAssertEqual(targetResult.location.column, 11)
        XCTAssertEqual(targetResult.location.offset, 11)
    }

    func test_querySymbols_extension_systemClass_inSourceFiles_additionalKinds_valid_willReturnExpectedResults() throws {
        let kinds = [SourceKind.extension] + SourceKind.declarations
        let query = IndexStoreQuery.extensions(in: sampleTestCaseFiles, matching: "XCTestCase").withKinds(kinds)
        let results = instanceUnderTest.querySymbols(query)
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "XCTestCase")
        XCTAssertEqual(targetResult.sourceKind, .extension)
        XCTAssertTrue(targetResult.location.path.hasSuffix(pathSuffix("InvocationTestCase.swift")))
        XCTAssertEqual(targetResult.location.line, 17)
        XCTAssertEqual(targetResult.location.column, 11)
        XCTAssertEqual(targetResult.location.offset, 11)
    }

    func test_querySymbols_extension_customClass_inSourceFiles_additionalKinds_noMatchesInSource_willReturnEmptyValues() throws {
        let query = IndexStoreQuery.extensions(in: sampleTestCaseFiles, matching: "RootClass").withKinds([.extension, .class]).withSourceFiles(sampleTestCaseFiles)
        let results = instanceUnderTest.querySymbols(query)
        XCTAssertEqual(results, [])
    }

    func test_querySymbols_extension_customClass_inSourceFiles_additionalKinds_matchesInSource_willReturnEmptyValues() throws {
        let query = IndexStoreQuery.extensions(in: sampleSourceFilePaths, matching: "RootClass").withKinds([.extension, .class])
        let results = instanceUnderTest.querySymbols(query)
        XCTAssertEqual(results.count, 2)
        var targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "RootClass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Classes.swift"))
        XCTAssertEqual(targetResult.location.line, 3)
        XCTAssertEqual(targetResult.location.column, 7)
        XCTAssertEqual(targetResult.location.offset, 7)
        targetResult = results[1]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "RootClass")
        XCTAssertEqual(targetResult.sourceKind, .extension)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Extensions.swift"))
        XCTAssertEqual(targetResult.location.line, 8)
        XCTAssertEqual(targetResult.location.column, 11)
        XCTAssertEqual(targetResult.location.offset, 11)
    }

    func test_querySymbols_extension_customClass_additionalKinds_partialMatches_willReturnEmptyValues() throws {
        let query = IndexStoreQuery.extensions(ofType: "RootClass").withKinds([.extension, .struct])
        let results = instanceUnderTest.querySymbols(query)
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "RootClass")
        XCTAssertEqual(targetResult.sourceKind, .extension)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Extensions.swift"))
        XCTAssertEqual(targetResult.location.line, 8)
        XCTAssertEqual(targetResult.location.column, 11)
        XCTAssertEqual(targetResult.location.offset, 11)
    }

    func test_querySymbols_extension_customClass_additionalKinds_willReturnEmptyValues() throws {
        let query = IndexStoreQuery.extensions(ofType: "RootClass").withKinds([.extension, .class])
        let results = instanceUnderTest.querySymbols(query)
        XCTAssertEqual(results.count, 2)
        var targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "RootClass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Classes.swift"))
        XCTAssertEqual(targetResult.location.line, 3)
        XCTAssertEqual(targetResult.location.column, 7)
        XCTAssertEqual(targetResult.location.offset, 7)
        targetResult = results[1]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "RootClass")
        XCTAssertEqual(targetResult.sourceKind, .extension)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Extensions.swift"))
        XCTAssertEqual(targetResult.location.line, 8)
        XCTAssertEqual(targetResult.location.column, 11)
        XCTAssertEqual(targetResult.location.offset, 11)
    }

    func test_querySymbols_extension_struct_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.extensions(ofType: "RootStruct"))
        let expectedPathSuffix = pathSuffix("Extensions.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "RootStruct")
        XCTAssertEqual(targetResult.sourceKind, .extension)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 17)
        XCTAssertEqual(targetResult.location.column, 11)
        XCTAssertEqual(targetResult.location.offset, 11)
    }

    func test_querySymbols_extension_enum_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.extensions(ofType: "RootEnum"))
        let expectedPathSuffix = pathSuffix("Extensions.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "RootEnum")
        XCTAssertEqual(targetResult.sourceKind, .extension)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 25)
        XCTAssertEqual(targetResult.location.column, 11)
        XCTAssertEqual(targetResult.location.offset, 11)
    }

    func test_querySymbols_extension_protocol_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.extensions(ofType: "RootProtocol"))
        let expectedPathSuffix = pathSuffix("Extensions.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "RootProtocol")
        XCTAssertEqual(targetResult.sourceKind, .extension)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 34)
        XCTAssertEqual(targetResult.location.column, 11)
        XCTAssertEqual(targetResult.location.offset, 11)
    }

    func test_querySymbols_extension_multiple_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.extensions(ofType: "ProtocolWithSystemInheritance"))
        let expectedPathSuffix = pathSuffix("Extensions.swift")
        XCTAssertEqual(results.count, 2)
        let firstResult = results[0]
        XCTAssertNil(firstResult.parent)
        XCTAssertEqual(firstResult.name, "ProtocolWithSystemInheritance")
        XCTAssertEqual(firstResult.sourceKind, .extension)
        XCTAssertTrue(firstResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(firstResult.location.line, 42)
        XCTAssertEqual(firstResult.location.column, 11)
        XCTAssertEqual(firstResult.location.offset, 11)
        let lastResult = results[1]
        XCTAssertNil(lastResult.parent)
        XCTAssertEqual(lastResult.name, "ProtocolWithSystemInheritance")
        XCTAssertEqual(lastResult.sourceKind, .extension)
        XCTAssertTrue(lastResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(lastResult.location.line, 46)
        XCTAssertEqual(lastResult.location.column, 11)
        XCTAssertEqual(lastResult.location.offset, 11)
    }

    func test_sourceSymbolsExtendingType_willReturnExpectedValues() {
        let results = instanceUnderTest.querySymbols(.extensions(ofType: "ProtocolWithSystemInheritance"))
        let expectedPathSuffix = pathSuffix("Extensions.swift")
        XCTAssertEqual(results.count, 2)
        let firstResult = results[0]
        XCTAssertNil(firstResult.parent)
        XCTAssertEqual(firstResult.name, "ProtocolWithSystemInheritance")
        XCTAssertEqual(firstResult.sourceKind, .extension)
        XCTAssertTrue(firstResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(firstResult.location.line, 42)
        XCTAssertEqual(firstResult.location.column, 11)
        XCTAssertEqual(firstResult.location.offset, 11)
        let lastResult = results[1]
        XCTAssertNil(lastResult.parent)
        XCTAssertEqual(lastResult.name, "ProtocolWithSystemInheritance")
        XCTAssertEqual(lastResult.sourceKind, .extension)
        XCTAssertTrue(lastResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(lastResult.location.line, 46)
        XCTAssertEqual(lastResult.location.column, 11)
        XCTAssertEqual(lastResult.location.offset, 11)
    }

    // MARK: - Tests: TypeAlias

    func test_querySymbols_typeAlias_root_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.typealiasDeclarations(matching: "RootAlias"))
        let expectedPathSuffix = pathSuffix("Typealias.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "RootAlias")
        XCTAssertEqual(targetResult.sourceKind, .typealias)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 3)
        XCTAssertEqual(targetResult.location.column, 11)
        XCTAssertEqual(targetResult.location.offset, 11)
    }

    func test_querySymbols_typeAlias_nested_enum_many_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.typealiasDeclarations(matching: "NestedAlias"))
        let expectedPathSuffix = pathSuffix("Typealias.swift")
        XCTAssertEqual(results.count, 2)
        let fooResult = results[0]
        XCTAssertEqual(fooResult.parent?.name, "Foo")
        XCTAssertEqual(fooResult.parent?.sourceKind, .enum)
        XCTAssertEqual(fooResult.name, "NestedAlias")
        XCTAssertEqual(fooResult.sourceKind, .typealias)
        XCTAssertTrue(fooResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(fooResult.location.line, 7)
        XCTAssertEqual(fooResult.location.column, 15)
        XCTAssertEqual(fooResult.location.offset, 15)
        let barResult = results[1]
        XCTAssertEqual(barResult.parent?.name, "Bar")
        XCTAssertEqual(barResult.parent?.sourceKind, .enum)
        XCTAssertEqual(barResult.name, "NestedAlias")
        XCTAssertEqual(barResult.sourceKind, .typealias)
        XCTAssertTrue(barResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(barResult.location.line, 17)
        XCTAssertEqual(barResult.location.column, 15)
        XCTAssertEqual(barResult.location.offset, 15)
    }

    func test_querySymbols_typeAlias_nested_struct_single_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.typealiasDeclarations(matching: "StructAlias"))
        let expectedPathSuffix = pathSuffix("Typealias.swift")
        XCTAssertEqual(results.count, 1)
        let fooResult = results[0]
        XCTAssertEqual(fooResult.parent?.name, "FooBar")
        XCTAssertEqual(fooResult.parent?.sourceKind, .struct)
        XCTAssertEqual(fooResult.name, "StructAlias")
        XCTAssertEqual(fooResult.sourceKind, .typealias)
        XCTAssertTrue(fooResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(fooResult.location.line, 23)
        XCTAssertEqual(fooResult.location.column, 15)
        XCTAssertEqual(fooResult.location.offset, 15)
    }

    func test_querySymbols_typeAlias_nested_class_single_willReturnExpectedValues() throws {
        let results = instanceUnderTest.querySymbols(.typealiasDeclarations(matching: "ClassAlias"))
        let expectedPathSuffix = pathSuffix("Typealias.swift")
        XCTAssertEqual(results.count, 1)
        let fooResult = results[0]
        XCTAssertEqual(fooResult.parent?.name, "FooBarClass")
        XCTAssertEqual(fooResult.parent?.sourceKind, .class)
        XCTAssertEqual(fooResult.name, "ClassAlias")
        XCTAssertEqual(fooResult.sourceKind, .typealias)
        XCTAssertTrue(fooResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(fooResult.location.line, 28)
        XCTAssertEqual(fooResult.location.column, 15)
        XCTAssertEqual(fooResult.location.offset, 15)
    }

    func test_querySymbols_typeAlias_structName_willReturnNoResults() throws {
        let results = instanceUnderTest.querySymbols(.typealiasDeclarations(matching: "FooBar"))
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Tests: Properties

    func test_properties_matchingQuery_willReturnExpectedResults() throws {
        let results = instanceUnderTest.querySymbols(.properties("sampleProperty"))
        XCTAssertEqual(results.count, 5)
        var property = try XCTUnwrap(results.first)
        // PropertiesProtocol::sampleProperty
        XCTAssertEqual(property.name, "sampleProperty")
        XCTAssertEqual(property.sourceKind, .instanceProperty)
        XCTAssertTrue(property.inheritance.isEmpty)
        XCTAssertFalse(property.location.isSystem)
        XCTAssertEqual(property.location.moduleName, "IndexStoreTests")
        XCTAssertFalse(property.location.isStale)
        XCTAssertEqual(property.location.line, 12)
        XCTAssertEqual(property.location.column, 9)
        XCTAssertEqual(property.location.offset, 9)
        XCTAssertTrue(property.location.path.hasSuffix("Properties.swift"))
        // sampleProperty::PropertiesProtocol Parent
        var propertyParent = try XCTUnwrap(property.parent)
        XCTAssertEqual(propertyParent.name, "PropertiesProtocol")
        XCTAssertEqual(propertyParent.sourceKind, .protocol)
        XCTAssertFalse(propertyParent.location.isStale)
        XCTAssertFalse(propertyParent.location.isSystem)
        XCTAssertEqual(propertyParent.location.moduleName, "IndexStoreTests")
        XCTAssertEqual(propertyParent.location.line, 10)
        XCTAssertEqual(propertyParent.location.column, 10)
        XCTAssertEqual(propertyParent.location.offset, 10)
        XCTAssertTrue(propertyParent.location.path.hasSuffix("Properties.swift"))
        //
        property = results[1]
        // PropertiesStruct::sampleProperty
        XCTAssertEqual(property.name, "sampleProperty")
        XCTAssertEqual(property.sourceKind, .instanceProperty)
        XCTAssertTrue(property.inheritance.isEmpty)
        XCTAssertFalse(property.location.isSystem)
        XCTAssertEqual(property.location.moduleName, "IndexStoreTests")
        XCTAssertFalse(property.location.isStale)
        XCTAssertEqual(property.location.line, 19)
        XCTAssertEqual(property.location.column, 9)
        XCTAssertEqual(property.location.offset, 9)
        XCTAssertTrue(property.location.path.hasSuffix("Properties.swift"))
        // sampleProperty::PropertiesStruct Parent
        propertyParent = try XCTUnwrap(property.parent)
        XCTAssertEqual(propertyParent.name, "PropertiesStruct")
        XCTAssertEqual(propertyParent.sourceKind, .struct)
        XCTAssertFalse(propertyParent.location.isStale)
        XCTAssertFalse(propertyParent.location.isSystem)
        XCTAssertEqual(propertyParent.location.moduleName, "IndexStoreTests")
        XCTAssertEqual(propertyParent.location.line, 17)
        XCTAssertEqual(propertyParent.location.column, 8)
        XCTAssertEqual(propertyParent.location.offset, 8)
        XCTAssertTrue(propertyParent.location.path.hasSuffix("Properties.swift"))
        //
        property = results[2]
        // PropertiesStruct::sampleProperty
        XCTAssertEqual(property.name, "sampleProperty")
        XCTAssertEqual(property.sourceKind, .instanceProperty)
        XCTAssertTrue(property.inheritance.isEmpty)
        XCTAssertFalse(property.location.isStale)
        XCTAssertFalse(property.location.isSystem)
        XCTAssertEqual(property.location.moduleName, "IndexStoreTests")
        XCTAssertFalse(property.location.isStale)
        XCTAssertEqual(property.location.line, 26)
        XCTAssertEqual(property.location.column, 9)
        XCTAssertEqual(property.location.offset, 9)
        XCTAssertTrue(property.location.path.hasSuffix("Properties.swift"))
        // sampleProperty::PropertiesStruct Parent
        propertyParent = try XCTUnwrap(property.parent)
        XCTAssertEqual(propertyParent.name, "PropertiesClass")
        XCTAssertEqual(propertyParent.sourceKind, .class)
        XCTAssertFalse(propertyParent.location.isStale)
        XCTAssertFalse(propertyParent.location.isSystem)
        XCTAssertEqual(propertyParent.location.moduleName, "IndexStoreTests")
        XCTAssertEqual(propertyParent.location.line, 24)
        XCTAssertEqual(propertyParent.location.column, 7)
        XCTAssertEqual(propertyParent.location.offset, 7)
        XCTAssertTrue(propertyParent.location.path.hasSuffix("Properties.swift"))
        //
        property = results[3]
        // PropertiesConformance::sampleProperty
        XCTAssertEqual(property.name, "sampleProperty")
        XCTAssertEqual(property.sourceKind, .instanceProperty)
        XCTAssertTrue(property.inheritance.isEmpty)
        XCTAssertFalse(property.location.isSystem)
        XCTAssertEqual(property.location.moduleName, "IndexStoreTests")
        XCTAssertFalse(property.location.isStale)
        XCTAssertEqual(property.location.line, 34)
        XCTAssertEqual(property.location.column, 9)
        XCTAssertEqual(property.location.offset, 9)
        XCTAssertTrue(property.location.path.hasSuffix("Properties.swift"))
        // sampleProperty::PropertiesConformance Parent
        propertyParent = try XCTUnwrap(property.parent)
        XCTAssertEqual(propertyParent.name, "PropertiesConformance")
        XCTAssertEqual(propertyParent.sourceKind, .struct)
        XCTAssertFalse(propertyParent.location.isSystem)
        XCTAssertFalse(propertyParent.location.isStale)
        XCTAssertEqual(propertyParent.location.moduleName, "IndexStoreTests")
        XCTAssertEqual(propertyParent.location.line, 32)
        XCTAssertEqual(propertyParent.location.column, 8)
        XCTAssertEqual(propertyParent.location.offset, 8)
        XCTAssertTrue(propertyParent.location.path.hasSuffix("Properties.swift"))
        //
        property = results[4]
        // PropertiesConformance::sampleProperty
        XCTAssertEqual(property.name, "sampleProperty")
        XCTAssertEqual(property.sourceKind, .instanceProperty)
        XCTAssertTrue(property.inheritance.isEmpty)
        XCTAssertFalse(property.location.isSystem)
        XCTAssertEqual(property.location.moduleName, "IndexStoreTests")
        XCTAssertFalse(property.location.isStale)
        XCTAssertEqual(property.location.line, 45)
        XCTAssertEqual(property.location.column, 18)
        XCTAssertEqual(property.location.offset, 18)
        XCTAssertTrue(property.location.path.hasSuffix("Properties.swift"))
        // sampleProperty::PropertiesConformance Parent
        propertyParent = try XCTUnwrap(property.parent)
        XCTAssertEqual(propertyParent.name, "PropertiesSubclass")
        XCTAssertEqual(propertyParent.sourceKind, .class)
        XCTAssertFalse(propertyParent.location.isSystem)
        XCTAssertFalse(propertyParent.location.isStale)
        XCTAssertEqual(propertyParent.location.moduleName, "IndexStoreTests")
        XCTAssertEqual(propertyParent.location.line, 43)
        XCTAssertEqual(propertyParent.location.column, 7)
        XCTAssertEqual(propertyParent.location.offset, 7)
        XCTAssertTrue(propertyParent.location.path.hasSuffix("Properties.swift"))
    }

    func test_properties_inSourceFiles_matchingQuery_willReturnExpectedResults() throws {
        let results = instanceUnderTest.querySymbols(.properties(in: sampleTestCaseFiles, matching: "baseProperty"))
        XCTAssertEqual(results.count, 2)
        var property = results[0]
        // SampleTestCase::baseProperty
        XCTAssertEqual(property.name, "baseProperty")
        XCTAssertEqual(property.sourceKind, .instanceProperty)
        XCTAssertTrue(property.inheritance.isEmpty)
        XCTAssertFalse(property.location.isSystem)
        XCTAssertEqual(property.location.moduleName, "IndexStoreTests")
        XCTAssertFalse(property.location.isStale)
        XCTAssertEqual(property.location.line, 12)
        XCTAssertEqual(property.location.column, 9)
        XCTAssertEqual(property.location.offset, 9)
        XCTAssertTrue(property.location.path.hasSuffix("InvocationTestCase.swift"))
        // baseProperty::SampleTestCase Parent
        var propertyParent = try XCTUnwrap(property.parent)
        XCTAssertEqual(propertyParent.name, "SampleTestCase")
        XCTAssertEqual(propertyParent.sourceKind, .class)
        XCTAssertFalse(propertyParent.location.isStale)
        XCTAssertFalse(propertyParent.location.isSystem)
        XCTAssertEqual(propertyParent.location.moduleName, "IndexStoreTests")
        XCTAssertEqual(propertyParent.location.line, 10)
        XCTAssertEqual(propertyParent.location.column, 7)
        XCTAssertEqual(propertyParent.location.offset, 7)
        XCTAssertTrue(propertyParent.location.path.hasSuffix("InvocationTestCase.swift"))
        //
        property = results[1]
        // SampleTestCase::basePropertyTwo
        XCTAssertEqual(property.name, "basePropertyTwo")
        XCTAssertEqual(property.sourceKind, .staticProperty)
        XCTAssertTrue(property.inheritance.isEmpty)
        XCTAssertFalse(property.location.isSystem)
        XCTAssertEqual(property.location.moduleName, "IndexStoreTests")
        XCTAssertFalse(property.location.isStale)
        XCTAssertEqual(property.location.line, 14)
        XCTAssertEqual(property.location.column, 16)
        XCTAssertEqual(property.location.offset, 16)
        XCTAssertTrue(property.location.path.hasSuffix("InvocationTestCase.swift"))
        // basePropertyTwo::SampleTestCase Parent
        propertyParent = try XCTUnwrap(property.parent)
        XCTAssertEqual(propertyParent.name, "SampleTestCase")
        XCTAssertEqual(propertyParent.sourceKind, .class)
        XCTAssertFalse(propertyParent.location.isStale)
        XCTAssertFalse(propertyParent.location.isSystem)
        XCTAssertEqual(propertyParent.location.moduleName, "IndexStoreTests")
        XCTAssertEqual(propertyParent.location.line, 10)
        XCTAssertEqual(propertyParent.location.column, 7)
        XCTAssertEqual(propertyParent.location.offset, 7)
        XCTAssertTrue(propertyParent.location.path.hasSuffix("InvocationTestCase.swift"))
    }

    func test_properties_inSourceFiles_noQuery_willReturnExpectedResults() throws {
        let results = instanceUnderTest.querySymbols(.properties(in: sampleTestCaseFiles))
        XCTAssertEqual(results.count, 4)
        var property = results[0]
        // SampleTestCase::baseProperty
        XCTAssertEqual(property.name, "baseProperty")
        XCTAssertEqual(property.sourceKind, .instanceProperty)
        XCTAssertTrue(property.inheritance.isEmpty)
        XCTAssertFalse(property.location.isSystem)
        XCTAssertEqual(property.location.moduleName, "IndexStoreTests")
        XCTAssertFalse(property.location.isStale)
        XCTAssertEqual(property.location.line, 12)
        XCTAssertEqual(property.location.column, 9)
        XCTAssertEqual(property.location.offset, 9)
        XCTAssertTrue(property.location.path.hasSuffix("InvocationTestCase.swift"))
        // baseProperty::SampleTestCase Parent
        var propertyParent = try XCTUnwrap(property.parent)
        XCTAssertEqual(propertyParent.name, "SampleTestCase")
        XCTAssertEqual(propertyParent.sourceKind, .class)
        XCTAssertFalse(propertyParent.location.isStale)
        XCTAssertFalse(propertyParent.location.isSystem)
        XCTAssertEqual(propertyParent.location.moduleName, "IndexStoreTests")
        XCTAssertEqual(propertyParent.location.line, 10)
        XCTAssertEqual(propertyParent.location.column, 7)
        XCTAssertEqual(propertyParent.location.offset, 7)
        XCTAssertTrue(propertyParent.location.path.hasSuffix("InvocationTestCase.swift"))
        //
        property = results[1]
        // SampleTestCase::basePropertyTwo
        XCTAssertEqual(property.name, "basePropertyTwo")
        XCTAssertEqual(property.sourceKind, .staticProperty)
        XCTAssertTrue(property.inheritance.isEmpty)
        XCTAssertFalse(property.location.isSystem)
        XCTAssertEqual(property.location.moduleName, "IndexStoreTests")
        XCTAssertFalse(property.location.isStale)
        XCTAssertEqual(property.location.line, 14)
        XCTAssertEqual(property.location.column, 16)
        XCTAssertEqual(property.location.offset, 16)
        XCTAssertTrue(property.location.path.hasSuffix("InvocationTestCase.swift"))
        // basePropertyTwo::SampleTestCase Parent
        propertyParent = try XCTUnwrap(property.parent)
        XCTAssertEqual(propertyParent.name, "SampleTestCase")
        XCTAssertEqual(propertyParent.sourceKind, .class)
        XCTAssertFalse(propertyParent.location.isStale)
        XCTAssertFalse(propertyParent.location.isSystem)
        XCTAssertEqual(propertyParent.location.moduleName, "IndexStoreTests")
        XCTAssertEqual(propertyParent.location.line, 10)
        XCTAssertEqual(propertyParent.location.column, 7)
        XCTAssertEqual(propertyParent.location.offset, 7)
        XCTAssertTrue(propertyParent.location.path.hasSuffix("InvocationTestCase.swift"))
        //
        property = results[2]
        // InvocationTestCase::basePropertyTwo
        XCTAssertEqual(property.name, "instance")
        XCTAssertEqual(property.sourceKind, .instanceProperty)
        XCTAssertTrue(property.inheritance.isEmpty)
        XCTAssertFalse(property.location.isSystem)
        XCTAssertEqual(property.location.moduleName, "IndexStoreTests")
        XCTAssertFalse(property.location.isStale)
        XCTAssertEqual(property.location.line, 26)
        XCTAssertEqual(property.location.column, 9)
        XCTAssertEqual(property.location.offset, 9)
        XCTAssertTrue(property.location.path.hasSuffix("InvocationTestCase.swift"))
        // basePropertyTwo::InvocationTestCase Parent
        propertyParent = try XCTUnwrap(property.parent)
        XCTAssertEqual(propertyParent.name, "InvocationTestCase")
        XCTAssertEqual(propertyParent.sourceKind, .class)
        XCTAssertFalse(propertyParent.location.isStale)
        XCTAssertFalse(propertyParent.location.isSystem)
        XCTAssertEqual(propertyParent.location.moduleName, "IndexStoreTests")
        XCTAssertEqual(propertyParent.location.line, 24)
        XCTAssertEqual(propertyParent.location.column, 13)
        XCTAssertEqual(propertyParent.location.offset, 13)
        XCTAssertTrue(propertyParent.location.path.hasSuffix("InvocationTestCase.swift"))
        //
        property = results[3]
        // StandardTestCase::basePropertyTwo
        XCTAssertEqual(property.name, "instance")
        XCTAssertEqual(property.sourceKind, .instanceProperty)
        XCTAssertTrue(property.inheritance.isEmpty)
        XCTAssertFalse(property.location.isSystem)
        XCTAssertEqual(property.location.moduleName, "IndexStoreTests")
        XCTAssertFalse(property.location.isStale)
        XCTAssertEqual(property.location.line, 35)
        XCTAssertEqual(property.location.column, 9)
        XCTAssertEqual(property.location.offset, 9)
        XCTAssertTrue(property.location.path.hasSuffix("InvocationTestCase.swift"))
        // basePropertyTwo::StandardTestCase Parent
        propertyParent = try XCTUnwrap(property.parent)
        XCTAssertEqual(propertyParent.name, "StandardTestCase")
        XCTAssertEqual(propertyParent.sourceKind, .class)
        XCTAssertFalse(propertyParent.location.isStale)
        XCTAssertFalse(propertyParent.location.isSystem)
        XCTAssertEqual(propertyParent.location.moduleName, "IndexStoreTests")
        XCTAssertEqual(propertyParent.location.line, 33)
        XCTAssertEqual(propertyParent.location.column, 13)
        XCTAssertEqual(propertyParent.location.offset, 13)
        XCTAssertTrue(propertyParent.location.path.hasSuffix("InvocationTestCase.swift"))
    }

    // MARK: - Tests: Functions

    func test_functions_matchingQuery_willReturnExpectedResults() throws {
        let results = instanceUnderTest.querySymbols(.functions("executeOrder"))
        XCTAssertEqual(results.count, 2)
        var function = try XCTUnwrap(results.first)
        // Function
        XCTAssertEqual(function.name, "executeOrder()")
        XCTAssertEqual(function.sourceKind, .instanceMethod)
        XCTAssertEqual(function.location.line, 22)
        XCTAssertEqual(function.location.column, 10)
        XCTAssertEqual(function.location.offset, 10)
        XCTAssertTrue(function.location.path.hasSuffix("Functions.swift"))
        // Parent
        var functionParent = try XCTUnwrap(function.parent)
        XCTAssertEqual(functionParent.name, "FunctionRootProtocol")
        XCTAssertEqual(functionParent.sourceKind, .protocol)
        XCTAssertEqual(functionParent.location.line, 20)
        XCTAssertEqual(functionParent.location.column, 10)
        XCTAssertEqual(functionParent.location.offset, 10)
        XCTAssertTrue(functionParent.location.path.hasSuffix("Functions.swift"))
        function = try XCTUnwrap(results.last)
        // Function
        XCTAssertEqual(function.name, "executeOrder()")
        XCTAssertEqual(function.sourceKind, .instanceMethod)
        XCTAssertEqual(function.location.line, 69)
        XCTAssertEqual(function.location.column, 10)
        XCTAssertEqual(function.location.offset, 10)
        XCTAssertTrue(function.location.path.hasSuffix("Functions.swift"))
        // Parent
        functionParent = try XCTUnwrap(function.parent)
        XCTAssertEqual(functionParent.name, "InvocationsConformance")
        XCTAssertEqual(functionParent.sourceKind, .struct)
        XCTAssertEqual(functionParent.location.line, 58)
        XCTAssertEqual(functionParent.location.column, 8)
        XCTAssertEqual(functionParent.location.offset, 8)
        XCTAssertTrue(functionParent.location.path.hasSuffix("Functions.swift"))
    }

    func test_functions_inSourceFiles_withQuery_willReturnExpectedResults() throws {
        let results = instanceUnderTest.querySymbols(.functions(in: sampleSourceFilePaths, matching: "TestCaseInvocation"))
        XCTAssertEqual(results.count, 2)
        var function = results[0]
        // Function
        XCTAssertEqual(function.name, "standardTestCaseInvocation()")
        XCTAssertEqual(function.sourceKind, .instanceMethod)
        XCTAssertEqual(function.location.line, 7)
        XCTAssertEqual(function.location.column, 10)
        XCTAssertEqual(function.location.offset, 10)
        XCTAssertTrue(function.location.path.hasSuffix("Functions.swift"))
        // Parent
        var functionParent = try XCTUnwrap(function.parent)
        XCTAssertEqual(functionParent.name, "FunctionClass")
        XCTAssertEqual(functionParent.sourceKind, .class)
        XCTAssertEqual(functionParent.location.line, 3)
        XCTAssertEqual(functionParent.location.column, 7)
        XCTAssertEqual(functionParent.location.offset, 7)
        XCTAssertTrue(functionParent.location.path.hasSuffix("Functions.swift"))
        // Second Function
        function = results[1]
        XCTAssertEqual(function.name, "subclassTestCaseInvocation()")
        XCTAssertEqual(function.sourceKind, .instanceMethod)
        XCTAssertEqual(function.location.line, 11)
        XCTAssertEqual(function.location.column, 14)
        XCTAssertEqual(function.location.offset, 14)
        XCTAssertTrue(function.location.path.hasSuffix("Functions.swift"))
        // Second Function Parent
        functionParent = try XCTUnwrap(function.parent)
        XCTAssertEqual(functionParent.name, "NestedFunctionClass")
        XCTAssertEqual(functionParent.sourceKind, .class)
        XCTAssertEqual(functionParent.location.line, 9)
        XCTAssertEqual(functionParent.location.column, 11)
        XCTAssertEqual(functionParent.location.offset, 11)
        XCTAssertTrue(functionParent.location.path.hasSuffix("Functions.swift"))
    }

    #if swift(>=5.6)
    func test_functions_inSourceFiles_noQuery_willReturnExpectedResults() throws {
        let dir = instanceUnderTest.configuration.projectDirectory
        // Not going into inheritance checks etc as the other tests cover it. This is also not ideal, however, can
        // revisit once time allows to avoid the description match.
        let expected: [String] = [
            "sample() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Classes.swift::17::10",
            "test() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Extensions.swift::5::10",
            "test() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Extensions.swift::10::10",
            "test() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Extensions.swift::18::10",
            "test() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Extensions.swift::27::10",
            "test() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Extensions.swift::35::10",
            "test() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Extensions.swift::43::10",
            "testTwo() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Extensions.swift::47::10",
            "performFunction(withPerson:) - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::5::10",
            "standardTestCaseInvocation() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::7::10",
            "subclassTestCaseInvocation() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::11::14",
            "notInvokedInTestCase() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::15::18",
            "performOperation(withName:) - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::21::10",
            "executeOrder() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::22::10",
            "performOperation(withAge:) - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::27::10",
            "performOperation(withName:age:) - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::32::10",
            "performOperation(withName:age:handler:) - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::36::10",
            "getter:instance - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::41::9",
            "setter:instance - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::41::9",
            "getter:otherInstance - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::42::9",
            "setter:otherInstance - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::42::9",
            "sample() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::48::10",
            "sampleInvocation() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::60::10",
            "performOperation(withName:) - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::65::10",
            "isolatedFunction() - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::54::6",
            "executeOrder() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::69::10",
            "getter:name - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::5::9",
            "setter:name - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::5::9",
            "getter:name - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::10::9",
            "setter:name - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::10::9",
            "==(_:_:) - staticMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::12::24",
            "getter:name - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::19::9",
            "setter:name - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::19::9",
            "getter:name - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::24::9",
            "setter:name - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::24::9",
            "==(_:_:) - staticMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::26::24",
            "sample() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::33::10",
            "getter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::12::34",
            "setter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::12::38",
            "getter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::14::45",
            "setter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::14::49",
            "getter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::19::9",
            "setter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::19::9",
            "getter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::21::9",
            "setter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::21::9",
            "getter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::26::9",
            "setter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::26::9",
            "getter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::28::9",
            "setter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::28::9",
            "getter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::34::9",
            "setter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::34::9",
            "getter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::36::9",
            "setter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::36::9",
            "invocation() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::38::19",
            "getter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::46::9",
            "setter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::49::9",
            "getter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::53::9",
            "setter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::56::9",
            "invocation() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::59::10",
        ]
        let results = instanceUnderTest.querySymbols(.functions(in: sampleSourceFilePaths))
        let descriptions = results.map(\.description)
        XCTAssertEqual(descriptions, expected)
    }
    #else
    func test_functions_inSourceFiles_noQuery_willReturnExpectedResults() throws {
        let dir = instanceUnderTest.configuration.projectDirectory
        // Not going into inheritance checks etc as the other tests cover it. This is also not ideal, however, can
        // revisit once time allows to avoid the description match.
        let expected: [String] = [
            "sample() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Classes.swift::17::10",
            "test() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Extensions.swift::5::10",
            "test() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Extensions.swift::10::10",
            "test() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Extensions.swift::18::10",
            "test() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Extensions.swift::27::10",
            "test() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Extensions.swift::35::10",
            "test() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Extensions.swift::43::10",
            "testTwo() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Extensions.swift::47::10",
            "performFunction(withPerson:) - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::5::10",
            "getter:withPerson - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::5::26",
            "setter:withPerson - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::5::26",
            "standardTestCaseInvocation() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::7::10",
            "subclassTestCaseInvocation() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::11::14",
            "notInvokedInTestCase() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::15::18",
            "performOperation(withName:) - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::21::10",
            "getter:withName - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::21::27",
            "setter:withName - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::21::27",
            "executeOrder() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::22::10",
            "performOperation(withAge:) - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::27::10",
            "getter:withAge - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::27::27",
            "setter:withAge - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::27::27",
            "performOperation(withName:age:) - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::32::10",
            "getter:withName - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::32::27",
            "setter:withName - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::32::27",
            "getter:age - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::32::45",
            "setter:age - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::32::45",
            "performOperation(withName:age:handler:) - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::36::10",
            "getter:withName - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::36::27",
            "setter:withName - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::36::27",
            "getter:age - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::36::45",
            "setter:age - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::36::45",
            "getter:handler - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::36::55",
            "setter:handler - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::36::55",
            "getter:instance - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::41::9",
            "setter:instance - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::41::9",
            "getter:otherInstance - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::42::9",
            "setter:otherInstance - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::42::9",
            "sample() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::48::10",
            "sampleInvocation() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::60::10",
            "performOperation(withName:) - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::65::10",
            "isolatedFunction() - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::54::6",
            "getter:withName - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::65::27",
            "setter:withName - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::65::27",
            "executeOrder() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Functions.swift::69::10",
            "getter:name - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::5::9",
            "setter:name - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::5::9",
            "getter:name - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::10::9",
            "setter:name - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::10::9",
            "==(_:_:) - staticMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::12::24",
            "getter:lhs - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::12::28",
            "setter:lhs - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::12::28",
            "getter:rhs - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::12::51",
            "setter:rhs - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::12::51",
            "getter:name - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::19::9",
            "setter:name - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::19::9",
            "getter:name - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::24::9",
            "setter:name - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::24::9",
            "==(_:_:) - staticMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::26::24",
            "getter:lhs - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::26::28",
            "setter:lhs - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::26::28",
            "getter:rhs - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::26::57",
            "setter:rhs - function | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::26::57",
            "sample() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Inheritance.swift::33::10",
            "getter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::12::34",
            "setter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::12::38",
            "getter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::14::45",
            "setter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::14::49",
            "getter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::19::9",
            "setter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::19::9",
            "getter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::21::9",
            "setter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::21::9",
            "getter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::26::9",
            "setter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::26::9",
            "getter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::28::9",
            "setter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::28::9",
            "getter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::34::9",
            "setter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::34::9",
            "getter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::36::9",
            "setter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::36::9",
            "invocation() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::38::19",
            "getter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::46::9",
            "setter:sampleProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::49::9",
            "getter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::53::9",
            "setter:sampleClosureProperty - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::56::9",
            "invocation() - instanceMethod | IndexStoreTests::\(dir)/Tests/IndexStoreTests/Samples/Properties.swift::59::10"
        ]
        let results = instanceUnderTest.querySymbols(.functions(in: sampleSourceFilePaths))
        let descriptions = results.map(\.description)
        XCTAssertEqual(descriptions, expected)
    }
    #endif

    // MARK: - Tests: Source Getting

    func test_querySymbols_typealias_willReturnExpectedDeclaration() throws {
        let symbols = instanceUnderTest.querySymbols(.typealiasDeclarations(matching: "SourceAlias"))
        let sourceLines = try symbols.map { try instanceUnderTest.declarationSource(forSymbol: $0) }
        let expectedLines = [
            "    typealias SourceAlias = String",
            "    enum Bar { typealias SourceAlias = Int }",
        ]
        XCTAssertEqual(sourceLines, expectedLines)
    }

    func test_querySymbols_typealias_unresolvableLine_willThrowError() throws {
        let validDetails = instanceUnderTest.querySymbols(.typealiasDeclarations(matching: "SourceAlias"))[0]
        let location = SourceLocation(
            path: validDetails.location.path,
            moduleName: "IndexStoreTests",
            line: 100,
            column: 0,
            offset: 0,
            isSystem: false,
            isStale: false
        )
        let symbol = SourceSymbol(
            name: validDetails.name,
            usr: validDetails.usr,
            sourceKind: validDetails.sourceKind,
            roles: .declaration,
            location: location
        )
        let expectedError = SourceResolvingError.unableToResolveSourceLine(
            name: "SourceAlias",
            path: validDetails.location.path,
            line: 100
        )
        XCTAssertThrowsError(try instanceUnderTest.declarationSource(forSymbol: symbol)) { error in
            XCTAssertEqual(error as? SourceResolvingError, expectedError)
        }
    }

    func test_querySymbols_typealias_contents_willReturnExpectedDeclaration() throws {
        let expectedContents =
            #"""
            import Foundation

            enum SourceContents {
                typealias SourceAlias = String
                enum Bar { typealias SourceAlias = Int }
            }

            """#
        let symbol = instanceUnderTest.querySymbols(.typealiasDeclarations(matching: "SourceAlias"))[0]
        let sourceContents = try instanceUnderTest.sourceContents(forSymbol: symbol)
        XCTAssertEqual(sourceContents, expectedContents)
    }

    func test_querySymbols_typealias_missingFile_willThrowError() throws {
        let location = SourceLocation(
            path: "file://missing/file.swift",
            moduleName: "",
            line: 100,
            column: 0,
            offset: 0,
            isSystem: false,
            isStale: false
        )
        let symbol = SourceSymbol(
            name: "SourceAlias",
            usr: "",
            sourceKind: .typealias,
            roles: .declaration,
            location: location
        )
        let expectedError = SourceResolvingError.sourcePathDoesNotExist(path: location.path)
        XCTAssertThrowsError(try instanceUnderTest.sourceContents(forSymbol: symbol)) { error in
            XCTAssertEqual(error as? SourceResolvingError, expectedError)
        }
    }

    func test_querySymbols_typealias_emptyFile_willThrowError() throws {
        let validDetails = instanceUnderTest.querySymbols(.typealiasDeclarations(matching: "SourceAlias"))[0]
        let emptyPath = validDetails.location.path.replacingOccurrences(of: "SourceContents.swift", with: "EmptySource.swift")
        let location = SourceLocation(
            path: emptyPath,
            moduleName: "IndexStoreTests",
            line: 0,
            column: 0,
            offset: 0,
            isSystem: false,
            isStale: false
        )
        let symbol = SourceSymbol(
            name: "SourceAlias",
            usr: "",
            sourceKind: .typealias,
            roles: .declaration,
            location: location
        )
        let expectedError = SourceResolvingError.sourceContentsIsEmpty(path: emptyPath)
        XCTAssertThrowsError(try instanceUnderTest.sourceContents(forSymbol: symbol)) { error in
            XCTAssertEqual(error as? SourceResolvingError, expectedError)
        }
    }

    // MARK: Tests: Convenience: Protocol Conformance

    func test_typesConformingToProtocol_withSystemInheritance() throws {
        let results = instanceUnderTest.sourceSymbols(conformingToProtocol: "ProtocolWithSystemInheritance")
        XCTAssertEqual(results.count, 2)
        var targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "InheritanceStruct")
        XCTAssertEqual(targetResult.sourceKind, .struct)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Inheritance.swift"))
        XCTAssertEqual(targetResult.location.line, 3)
        XCTAssertEqual(targetResult.location.column, 8)
        XCTAssertEqual(targetResult.location.offset, 8)
        XCTAssertEqual(targetResult.inheritance.map(\.name), ["ProtocolWithSystemInheritance", "RootProtocol"])
        targetResult = results[1]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "InheritanceClass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Inheritance.swift"))
        XCTAssertEqual(targetResult.location.line, 8)
        XCTAssertEqual(targetResult.location.column, 7)
        XCTAssertEqual(targetResult.location.offset, 7)
        XCTAssertEqual(targetResult.inheritance.map(\.name), ["RootProtocol", "ProtocolWithSystemInheritance"])
    }

    func test_typesConformingToProtocol_inSourceFiles_withSystemInheritance() throws {
        let sourceFiles = instanceUnderTest.swiftSourceFiles().filter { $0.contains("IndexStoreTests/Samples") }
        let results = instanceUnderTest.sourceSymbols(conformingToProtocol: "ProtocolWithSystemInheritance", in: sourceFiles)
        XCTAssertEqual(results.count, 2)
        var targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "InheritanceStruct")
        XCTAssertEqual(targetResult.sourceKind, .struct)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Inheritance.swift"))
        XCTAssertEqual(targetResult.location.line, 3)
        XCTAssertEqual(targetResult.location.column, 8)
        XCTAssertEqual(targetResult.location.offset, 8)
        XCTAssertEqual(targetResult.inheritance.map(\.name), ["ProtocolWithSystemInheritance", "RootProtocol"])
        targetResult = results[1]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "InheritanceClass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Inheritance.swift"))
        XCTAssertEqual(targetResult.location.line, 8)
        XCTAssertEqual(targetResult.location.column, 7)
        XCTAssertEqual(targetResult.location.offset, 7)
        XCTAssertEqual(targetResult.inheritance.map(\.name), ["RootProtocol", "ProtocolWithSystemInheritance"])
    }

    func test_typesConformingToProtocol_withCustomInheritance() throws {
        let results = instanceUnderTest.sourceSymbols(conformingToProtocol: "ProtocolWithInheritance")
        XCTAssertEqual(results.count, 2)
        var targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "CustomInheritanceStruct")
        XCTAssertEqual(targetResult.sourceKind, .struct)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Inheritance.swift"))
        XCTAssertEqual(targetResult.location.line, 17)
        XCTAssertEqual(targetResult.location.column, 8)
        XCTAssertEqual(targetResult.location.offset, 8)
        XCTAssertEqual(targetResult.inheritance.map(\.name), ["ProtocolWithInheritance", "RootProtocol"])
        targetResult = results[1]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "CustomInheritanceClass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Inheritance.swift"))
        XCTAssertEqual(targetResult.location.line, 22)
        XCTAssertEqual(targetResult.location.column, 7)
        XCTAssertEqual(targetResult.location.offset, 7)
        XCTAssertEqual(targetResult.inheritance.map(\.name), ["RootProtocol", "ProtocolWithInheritance"])
        let inheritedInheritance = try XCTUnwrap(results[1].inheritance.last?.inheritance.first)
        XCTAssertNil(inheritedInheritance.parent)
        XCTAssertEqual(inheritedInheritance.name, "BaseProtocol")
        XCTAssertEqual(inheritedInheritance.sourceKind, .protocol)
        XCTAssertTrue(inheritedInheritance.location.path.hasSuffix("Protocols.swift"))
        XCTAssertEqual(inheritedInheritance.location.line, 7)
        XCTAssertEqual(inheritedInheritance.location.column, 10)
        XCTAssertEqual(inheritedInheritance.location.offset, 10)
        XCTAssertTrue(inheritedInheritance.inheritance.isEmpty)
    }

    // MARK: Tests: Convenience: Empty Extensions

    func test_sourceSymbolsForEmptyExtensionsOfType_willReturnExpectedValues() {
        let results = instanceUnderTest.sourceSymbols(forEmptyExtensionsMatching: .classDeclarations(matching: "RootClass"))
        let expectedPathSuffix = pathSuffix("Extensions.swift")
        XCTAssertEqual(results.count, 1)
        let firstResult = results[0]
        XCTAssertNil(firstResult.parent)
        XCTAssertEqual(firstResult.name, "RootClass")
        XCTAssertEqual(firstResult.sourceKind, .extension)
        XCTAssertTrue(firstResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(firstResult.location.line, 13)
        XCTAssertEqual(firstResult.location.column, 11)
        XCTAssertEqual(firstResult.location.offset, 11)
    }

    // MARK: Tests: Convenience: Function Invocations in Test Case

    func test_functions_inSourceFiles_invokedInTestCase_willReturnExpectedResults() throws {
        let results = instanceUnderTest.querySymbols(.functions(in: sampleSourceFilePaths))
        let invokedNames = ["standardTestCaseInvocation()", "subclassTestCaseInvocation()"]
        // Invoked
        results.filter { invokedNames.contains($0.name) }.forEach {
            XCTAssertTrue(instanceUnderTest.isSymbolInvokedByTestCase($0))
        }
        // Not Invoked
        results.filter { !invokedNames.contains($0.name) }.forEach {
            XCTAssertFalse(instanceUnderTest.isSymbolInvokedByTestCase($0))
        }
    }

    func test_function_invokedInTestCase() throws {
        let results = instanceUnderTest.querySymbols(.functions("standardTestCaseInvocation"))
        let function = try XCTUnwrap(results.first)
        XCTAssertTrue(instanceUnderTest.isSymbolInvokedByTestCase(function))
    }

    func test_function_invokedInTestCaseSubclass() throws {
        let results = instanceUnderTest.querySymbols(.functions("subclassTestCaseInvocation"))
        let function = try XCTUnwrap(results.first)
        XCTAssertTrue(instanceUnderTest.isSymbolInvokedByTestCase(function))
    }

    func test_function_notInvokedInTestCaseSubclass() throws {
        let results = instanceUnderTest.querySymbols(.functions("notInvokedInTestCase"))
        let function = try XCTUnwrap(results.first)
        XCTAssertFalse(instanceUnderTest.isSymbolInvokedByTestCase(function))
    }

    // MARK: Tests: Convenience: Subclasses of

    func test_sourceSymbolsSubclassing_query_willReturnExpectedResults() throws {
        let results = instanceUnderTest.sourceSymbols(subclassing: "InheritanceClass").sorted(by: { $0.name <= $1.name })
        XCTAssertEqual(results.count, 2)
        var targetResult = try XCTUnwrap(results.first)
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "InheritanceSubclass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Inheritance.swift"))
        XCTAssertEqual(targetResult.location.line, 31)
        XCTAssertEqual(targetResult.location.column, 7)
        XCTAssertEqual(targetResult.location.offset, 7)
        XCTAssertEqual(targetResult.inheritance.map(\.name), ["InheritanceClass"])
        targetResult = try XCTUnwrap(results.last)
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "OtherInheritanceSubclass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Classes.swift"))
        XCTAssertEqual(targetResult.location.line, 15)
        XCTAssertEqual(targetResult.location.column, 7)
        XCTAssertEqual(targetResult.location.offset, 7)
        XCTAssertEqual(targetResult.inheritance.map(\.name), ["InheritanceClass"])
    }

    func test_sourceSymbolsSubclassing_inSourceFiles_willReturnExpectedResults() throws {
        let results = instanceUnderTest.sourceSymbols(subclassing: "InheritanceClass", in: sampleSourceFilePaths)
        XCTAssertEqual(results.count, 2)
        var targetResult = try XCTUnwrap(results.first)
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "OtherInheritanceSubclass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Classes.swift"))
        XCTAssertEqual(targetResult.location.line, 15)
        XCTAssertEqual(targetResult.location.column, 7)
        XCTAssertEqual(targetResult.location.offset, 7)
        XCTAssertEqual(targetResult.inheritance.map(\.name), ["InheritanceClass"])

        targetResult = try XCTUnwrap(results.last)
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "InheritanceSubclass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Inheritance.swift"))
        XCTAssertEqual(targetResult.location.line, 31)
        XCTAssertEqual(targetResult.location.column, 7)
        XCTAssertEqual(targetResult.location.offset, 7)
        XCTAssertEqual(targetResult.inheritance.map(\.name), ["InheritanceClass"])
    }

    func test_sourceSymbolsSubclassing_systemInheritance_willReturnExpectedResults() throws {
        let results = instanceUnderTest.sourceSymbols(subclassing: "NSObject")
        XCTAssertEqual(results.count, 1)
        let targetResult = try XCTUnwrap(results.first)
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "SystemInheritanceSubclass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Inheritance.swift"))
        XCTAssertEqual(targetResult.location.line, 38)
        XCTAssertEqual(targetResult.location.column, 7)
        XCTAssertEqual(targetResult.location.offset, 7)
        XCTAssertEqual(targetResult.inheritance.map(\.name), ["NSObject"])
    }

    func test_sourceSymbolsSubclassing_inSourceFiles_systemInheritance_willReturnExpectedResults() throws {
        let results = instanceUnderTest.sourceSymbols(subclassing: "NSObject", in: sampleSourceFilePaths)
        XCTAssertEqual(results.count, 1)
        let targetResult = try XCTUnwrap(results.first)
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "SystemInheritanceSubclass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Inheritance.swift"))
        XCTAssertEqual(targetResult.location.line, 38)
        XCTAssertEqual(targetResult.location.column, 7)
        XCTAssertEqual(targetResult.location.offset, 7)
        XCTAssertEqual(targetResult.inheritance.map(\.name), ["NSObject"])
    }

    func test_sourceSymbolsSubclassing_withCustomInheritance() throws {
        let results = instanceUnderTest.sourceSymbols(subclassing: "InheritanceClass").sorted(by: { $0.name <= $1.name })
        XCTAssertEqual(results.count, 2)
        var targetResult = try XCTUnwrap(results.first)
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "InheritanceSubclass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Inheritance.swift"))
        XCTAssertEqual(targetResult.location.line, 31)
        XCTAssertEqual(targetResult.location.column, 7)
        XCTAssertEqual(targetResult.location.offset, 7)
        XCTAssertEqual(targetResult.inheritance.map(\.name), ["InheritanceClass"])
        targetResult = try XCTUnwrap(results.last)
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "OtherInheritanceSubclass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Classes.swift"))
        XCTAssertEqual(targetResult.location.line, 15)
        XCTAssertEqual(targetResult.location.column, 7)
        XCTAssertEqual(targetResult.location.offset, 7)
        XCTAssertEqual(targetResult.inheritance.map(\.name), ["InheritanceClass"])
    }

    // MARK: Tests: Convenience: Symbol Invocations

    func test_invocationsOfSymbols_functions_willReturnExpectedResults() throws {
        let functions = instanceUnderTest.querySymbols(.functions("sampleInvocation"))
        XCTAssertEqual(functions.count, 1)
        let function = try XCTUnwrap(functions.first)
        let invocations = instanceUnderTest.invocationsOfSymbol(function)
        XCTAssertEqual(invocations.count, 1)
        let invocation = try XCTUnwrap(invocations.first)
        XCTAssertEqual(invocation.name, "sampleInvocation()")
        XCTAssertEqual(invocation.sourceKind, .instanceMethod)
        XCTAssertEqual(invocation.location.moduleName, "IndexStoreTests")
        XCTAssertTrue(invocation.location.path.hasSuffix("Functions.swift"))
        XCTAssertEqual(invocation.location.line, 49)
        XCTAssertEqual(invocation.location.column, 23)
        XCTAssertEqual(invocation.location.offset, 23)
        // Parent (Function)
        var parent = try XCTUnwrap(invocation.parent)
        XCTAssertEqual(parent.name, "sample()")
        XCTAssertEqual(parent.sourceKind, .instanceMethod)
        XCTAssertEqual(parent.location.moduleName, "IndexStoreTests")
        XCTAssertTrue(parent.location.path.hasSuffix("Functions.swift"))
        XCTAssertEqual(parent.location.line, 48)
        XCTAssertEqual(parent.location.column, 10)
        XCTAssertEqual(parent.location.offset, 10)
        // Parent -> Parent (Struct)
        parent = try XCTUnwrap(parent.parent)
        XCTAssertNil(parent.parent)
        XCTAssertEqual(parent.name, "Invocations")
        XCTAssertEqual(parent.sourceKind, .struct)
        XCTAssertEqual(parent.location.moduleName, "IndexStoreTests")
        XCTAssertTrue(parent.location.path.hasSuffix("Functions.swift"))
        XCTAssertEqual(parent.location.line, 39)
        XCTAssertEqual(parent.location.column, 8)
        XCTAssertEqual(parent.location.offset, 8)
    }

    func test_invocationsOfSymbols_properties_willReturnExpectedResults() throws {
        let properties = instanceUnderTest.querySymbols(.properties("sampleProperty"))
        // Declarations (empty)
        XCTAssertEqual(instanceUnderTest.invocationsOfSymbol(properties[0]), [])
        XCTAssertEqual(instanceUnderTest.invocationsOfSymbol(properties[1]), [])
        XCTAssertEqual(instanceUnderTest.invocationsOfSymbol(properties[2]), [])
        //
        var invocations = instanceUnderTest.invocationsOfSymbol(properties[3])
        XCTAssertEqual(invocations.count, 1)
        var invocation = invocations[0]
        XCTAssertEqual(invocation.name, "sampleProperty")
        XCTAssertEqual(invocation.sourceKind, .instanceProperty)
        XCTAssertEqual(invocation.location.moduleName, "IndexStoreTests")
        XCTAssertEqual(invocation.location.line, 39)
        XCTAssertEqual(invocation.location.column, 9)
        XCTAssertEqual(invocation.location.offset, 9)
        XCTAssertTrue(invocation.location.path.hasSuffix("Properties.swift"))
        //
        invocations = instanceUnderTest.invocationsOfSymbol(properties[4])
        XCTAssertEqual(invocations.count, 1)
        invocation = invocations[0]
        XCTAssertEqual(invocation.name, "sampleProperty")
        XCTAssertEqual(invocation.sourceKind, .instanceProperty)
        XCTAssertEqual(invocation.location.moduleName, "IndexStoreTests")
        XCTAssertEqual(invocation.location.line, 60)
        XCTAssertEqual(invocation.location.column, 9)
        XCTAssertEqual(invocation.location.offset, 9)
        XCTAssertTrue(invocation.location.path.hasSuffix("Properties.swift"))
    }

    // MARK: - Tests: Invalid queries

    func test_invocationsOfSymbols_invalidKind_willReturnExpectedResults() throws {
        let results = instanceUnderTest.sourceSymbols(subclassing: "NSObject")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertEqual(instanceUnderTest.invocationsOfSymbol(targetResult), [])
    }

    func test_query_emptySourceFiles_willReturnEmptyResults() throws {
        XCTAssertEqual(instanceUnderTest.querySymbols(.classDeclarations(in: [])), [])
        XCTAssertEqual(instanceUnderTest.querySymbols(.classDeclarations(in: [], matching: "RootClass")), [])
        let query = IndexStoreQuery.classDeclarations(matching: "RootClass").withQuery(nil)
        XCTAssertEqual(instanceUnderTest.querySymbols(query), [])
    }
}
