//
//  IndexStoreTests.swift
//  IndexStoreTests
//
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import XCTest

@testable import IndexStore

final class IndexStoreTests: XCTestCase {

    // MARK: - Properties
    var instanceUnderTest: IndexStore!

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        let configuration = try Configuration(projectDirectory: "")
        instanceUnderTest = IndexStore(configuration: configuration, logger: .test)
    }

    override func tearDownWithError() throws {
        instanceUnderTest = nil
    }

    // MARK: - Helpers

    func pathSuffix(_ sourceName: String) -> String {
        "IndexStore/Tests/IndexStoreTests/Samples/\(sourceName)"
    }

    // MARK: - Tests: Declarations

    func test_sourceDetailsForDeclarations_rootClass_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forDeclarationsMatching: "RootClass")
        XCTAssertEqual(results.count, 2)
        let targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "RootClass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix(pathSuffix("Classes.swift")))
        XCTAssertEqual(targetResult.location.line, 3)
        XCTAssertEqual(targetResult.location.column, 7)
        XCTAssertEqual(targetResult.location.offset, 7)
        let extensionResult = results[1]
        XCTAssertNil(extensionResult.parent)
        XCTAssertEqual(extensionResult.name, "RootClass")
        XCTAssertEqual(extensionResult.sourceKind, .extension)
        XCTAssertTrue(extensionResult.location.path.hasSuffix(pathSuffix("Extensions.swift")))
        XCTAssertEqual(extensionResult.location.line, 8)
        XCTAssertEqual(extensionResult.location.column, 11)
        XCTAssertEqual(extensionResult.location.offset, 11)
    }

    // MARK: - Declarations: Classes

    func test_sourceDetailsForClasses_root_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forClassesMatching: "RootClass")
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

    func test_sourceDetailsForClasses_nested_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forClassesMatching: "NestedClass")
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

    func test_sourceDetailsForClasses_doubleNested_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forClassesMatching: "DoubleNestedClass")
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

    func test_sourceDetailsForClasses_notClassType_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forClassesMatching: "RootStruct")
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Tests: Declarations: Structs

    func test_sourceDetailsForStructs_root_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forStructsMatching: "RootStruct")
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

    func test_sourceDetailsForStructs_nested_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forStructsMatching: "NestedStruct")
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

    func test_sourceDetailsForStructs_doubleNested_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forStructsMatching: "DoubleNestedStruct")
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

    func test_sourceDetailsForStructs_Inheritence_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forStructsMatching: "InheritenceStruct")
        let expectedPathSuffix = pathSuffix("Inheritence.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertEqual(targetResult.name, "InheritenceStruct")
        XCTAssertEqual(targetResult.sourceKind, .struct)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 3)
        XCTAssertEqual(targetResult.location.column, 8)
        XCTAssertEqual(targetResult.location.offset, 8)
        XCTAssertEqual(targetResult.inheritance.count, 2)
        var nextInheritence = targetResult.inheritance[0]
        XCTAssertEqual(nextInheritence.name, "ProtocolWithSystemInheritence")
        XCTAssertEqual(nextInheritence.sourceKind, .protocol)
        XCTAssertEqual(nextInheritence.location.line, 5)
        XCTAssertEqual(nextInheritence.location.column, 10)
        XCTAssertEqual(nextInheritence.location.offset, 10)
        XCTAssertTrue(nextInheritence.location.path.hasSuffix("Protocols.swift"))
        nextInheritence = targetResult.inheritance[1]
        XCTAssertEqual(nextInheritence.name, "RootProtocol")
        XCTAssertEqual(nextInheritence.sourceKind, .protocol)
        XCTAssertEqual(nextInheritence.location.line, 3)
        XCTAssertEqual(nextInheritence.location.column, 10)
        XCTAssertEqual(nextInheritence.location.offset, 10)
        XCTAssertTrue(nextInheritence.location.path.hasSuffix("Protocols.swift"))
    }

    func test_sourceDetailsForStructs_notStructType_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forStructsMatching: "RootClass")
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Tests: Declarations: Enums

    func test_sourceDetailsForEnumerations_root_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forEnumerationsMatching: "RootEnum")
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

    func test_sourceDetailsForEnumerations_nested_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forEnumerationsMatching: "NestedEnum")
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

    func test_sourceDetailsForEnumerations_doubleNested_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forEnumerationsMatching: "DoubleNestedEnum")
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

    func test_sourceDetailsForEnumerations_notEnumType_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forEnumerationsMatching: "RootClass")
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Tests: Declarations: Protocols

    func test_sourceDetailsForProtocols_basic_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forProtocolsMatching: "RootProtocol")
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

    func test_sourceDetailsForProtocols_system_inheritence_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forProtocolsMatching: "ProtocolWithSystemInheritence")
        let expectedPathSuffix = pathSuffix("Protocols.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "ProtocolWithSystemInheritence")
        XCTAssertEqual(targetResult.sourceKind, .protocol)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 5)
        XCTAssertEqual(targetResult.location.column, 10)
        XCTAssertEqual(targetResult.location.offset, 10)
    }

    func test_sourceDetailsForProtocols_custom_inheritence_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forProtocolsMatching: "ProtocolWithInheritence")
        let expectedPathSuffix = pathSuffix("Protocols.swift")
        XCTAssertEqual(results.count, 1)
        let targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "ProtocolWithInheritence")
        XCTAssertEqual(targetResult.sourceKind, .protocol)
        XCTAssertTrue(targetResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(targetResult.location.line, 11)
        XCTAssertEqual(targetResult.location.column, 10)
        XCTAssertEqual(targetResult.location.offset, 10)
    }

    func test_sourceDetailsForProtocols_notProtocolType_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(forProtocolsMatching: "ProtocolName")
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Tests: Extension

    func test_sourceDetailsForType_extension_class_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(
            matchingType: "RootClass",
            kinds: [.extension],
            roles: [.definition]
        )
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

    func test_sourceDetailsForType_extension_struct_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(
            matchingType: "RootStruct",
            kinds: [.extension],
            roles: [.definition]
        )
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

    func test_sourceDetailsForType_extension_enum_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(
            matchingType: "RootEnum",
            kinds: [.extension],
            roles: [.definition, .reference]
        )
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

    func test_sourceDetailsForType_extension_protocol_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(
            matchingType: "RootProtocol",
            kinds: [.extension],
            roles: [.definition]
        )
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

    func test_sourceDetailsForType_extension_multiple_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(
            matchingType: "ProtocolWithSystemInheritence",
            kinds: [.extension],
            roles: [.definition]
        )
        let expectedPathSuffix = pathSuffix("Extensions.swift")
        XCTAssertEqual(results.count, 2)
        let firstResult = results[0]
        XCTAssertNil(firstResult.parent)
        XCTAssertEqual(firstResult.name, "ProtocolWithSystemInheritence")
        XCTAssertEqual(firstResult.sourceKind, .extension)
        XCTAssertTrue(firstResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(firstResult.location.line, 42)
        XCTAssertEqual(firstResult.location.column, 11)
        XCTAssertEqual(firstResult.location.offset, 11)
        let lastResult = results[1]
        XCTAssertNil(lastResult.parent)
        XCTAssertEqual(lastResult.name, "ProtocolWithSystemInheritence")
        XCTAssertEqual(lastResult.sourceKind, .extension)
        XCTAssertTrue(lastResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(lastResult.location.line, 46)
        XCTAssertEqual(lastResult.location.column, 11)
        XCTAssertEqual(lastResult.location.offset, 11)
    }

    func test_sourcdeDetailsExtendingType_willReturnExptecedValues() {
        let results = instanceUnderTest.sourceDetails(forExtensionsOfType: "RootClass", includeEmptyExtensions: false)
        let expectedPathSuffix = pathSuffix("Extensions.swift")
        XCTAssertEqual(results.count, 2)
        let firstResult = results[0]
        XCTAssertNil(firstResult.parent)
        XCTAssertEqual(firstResult.name, "ProtocolWithSystemInheritence")
        XCTAssertEqual(firstResult.sourceKind, .extension)
        XCTAssertTrue(firstResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(firstResult.location.line, 42)
        XCTAssertEqual(firstResult.location.column, 11)
        XCTAssertEqual(firstResult.location.offset, 11)
        let lastResult = results[1]
        XCTAssertNil(lastResult.parent)
        XCTAssertEqual(lastResult.name, "ProtocolWithSystemInheritence")
        XCTAssertEqual(lastResult.sourceKind, .extension)
        XCTAssertTrue(lastResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(lastResult.location.line, 46)
        XCTAssertEqual(lastResult.location.column, 11)
        XCTAssertEqual(lastResult.location.offset, 11)
    }

    func test_sourceDetailsExtendingType_willReturnExptecedValues() {
        let results = instanceUnderTest.sourceDetails(forExtensionsOfType: "ProtocolWithSystemInheritence")
        let expectedPathSuffix = pathSuffix("Extensions.swift")
        XCTAssertEqual(results.count, 2)
        let firstResult = results[0]
        XCTAssertNil(firstResult.parent)
        XCTAssertEqual(firstResult.name, "ProtocolWithSystemInheritence")
        XCTAssertEqual(firstResult.sourceKind, .extension)
        XCTAssertTrue(firstResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(firstResult.location.line, 42)
        XCTAssertEqual(firstResult.location.column, 11)
        XCTAssertEqual(firstResult.location.offset, 11)
        let lastResult = results[1]
        XCTAssertNil(lastResult.parent)
        XCTAssertEqual(lastResult.name, "ProtocolWithSystemInheritence")
        XCTAssertEqual(lastResult.sourceKind, .extension)
        XCTAssertTrue(lastResult.location.path.hasSuffix(expectedPathSuffix))
        XCTAssertEqual(lastResult.location.line, 46)
        XCTAssertEqual(lastResult.location.column, 11)
        XCTAssertEqual(lastResult.location.offset, 11)
    }

    // MARK: - Tests: TypeAlias

    func test_sourceDetailsForType_typeAlias_root_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(matchingType: "RootAlias", kinds: [.typealias])
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

    func test_sourceDetailsForType_typeAlias_nested_enum_many_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(matchingType: "NestedAlias", kinds: [.typealias])
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

    func test_sourceDetailsForType_typeAlias_nested_struct_single_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(matchingType: "StructAlias", kinds: [.typealias])
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

    func test_sourceDetailsForType_typeAlias_nested_class_single_willReturnExpectedValues() throws {
        let results = instanceUnderTest.sourceDetails(matchingType: "ClassAlias", kinds: [.typealias])
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

    func test_sourceDetailsForType_typeAlias_structName_willReturnNoResults() throws {
        let results = instanceUnderTest.sourceDetails(matchingType: "FooBar", kinds: [.typealias])
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Tests: Source Getting

    func test_declarationSourceForDetails_willReturnExpectedDeclaration() throws {
        let details = instanceUnderTest.sourceDetails(matchingType: "SourceAlias", kinds: [.typealias])
        let sourceLines = try details.map(instanceUnderTest.declarationSourceForDetails)
        let expectedLines = [
            "    typealias SourceAlias = String",
            "    enum Bar { typealias SourceAlias = Int }",
        ]
        XCTAssertEqual(sourceLines, expectedLines)
    }

    func test_declarationSourceForDetails_unresolvableLine_willThrowError() throws {
        let validDetails = instanceUnderTest.sourceDetails(matchingType: "SourceAlias", kinds: [.typealias])[0]
        let location = SourceLocation(
            path: validDetails.location.path, line: 100, column: 0, offset: 0, isStale: false)
        let details = SourceDetails(
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
        XCTAssertThrowsError(try instanceUnderTest.declarationSourceForDetails(details)) { error in
            XCTAssertEqual(error as? SourceResolvingError, expectedError)
        }
    }

    func test_sourceContentsForDetails_willReturnExpectedDeclaration() throws {
        let expectedContents =
            #"""
            import Foundation

            enum SourceContents {
                typealias SourceAlias = String
                enum Bar { typealias SourceAlias = Int }
            }

            """#
        let details = instanceUnderTest.sourceDetails(matchingType: "SourceAlias", kinds: [.typealias])[0]
        let sourceContents = try instanceUnderTest.sourceContentsForDetails(details)
        XCTAssertEqual(sourceContents, expectedContents)
    }

    func test_sourceContentsForDetails_missingFile_willThrowError() throws {
        let location = SourceLocation(
            path: "file://missing/file.swift", line: 0, column: 0, offset: 0, isStale: false)
        let details = SourceDetails(
            name: "SourceAlias",
            usr: "",
            sourceKind: .typealias,
            roles: .declaration,
            location: location
        )
        let expectedError = SourceResolvingError.sourcePathDoesNotExist(path: location.path)
        XCTAssertThrowsError(try instanceUnderTest.sourceContentsForDetails(details)) { error in
            XCTAssertEqual(error as? SourceResolvingError, expectedError)
        }
    }

    func test_sourceContentsForDetails_emptyFile_willThrowError() throws {
        let validDetails = instanceUnderTest.sourceDetails(
            matchingType:
                "SourceAlias", kinds: [.typealias])[0]
        let emptyPath = validDetails.location.path.replacingOccurrences(
            of: "SourceContents.swift", with: "EmptySource.swift")
        let location = SourceLocation(path: emptyPath, line: 0, column: 0, offset: 0, isStale: false)
        let details = SourceDetails(
            name: "SourceAlias",
            usr: "",
            sourceKind: .typealias,
            roles: .declaration,
            location: location
        )
        let expectedError = SourceResolvingError.sourceContentsIsEmpty(path: emptyPath)
        XCTAssertThrowsError(try instanceUnderTest.sourceContentsForDetails(details)) { error in
            XCTAssertEqual(error as? SourceResolvingError, expectedError)
        }
    }

    // MARK: Tests: Convenience

    func test_typesConformingToProtocol_withSystemInheritence() throws {
        let results = instanceUnderTest.sourceDetails(conformingToProtocol: "ProtocolWithSystemInheritence")
        XCTAssertEqual(results.count, 2)
        var targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "InheritenceStruct")
        XCTAssertEqual(targetResult.sourceKind, .struct)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Inheritence.swift"))
        XCTAssertEqual(targetResult.location.line, 3)
        XCTAssertEqual(targetResult.location.column, 8)
        XCTAssertEqual(targetResult.location.offset, 8)
        XCTAssertEqual(
            targetResult.inheritance.map(\.name), ["ProtocolWithSystemInheritence", "RootProtocol"])
        targetResult = results[1]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "InheritenceClass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Inheritence.swift"))
        XCTAssertEqual(targetResult.location.line, 8)
        XCTAssertEqual(targetResult.location.column, 7)
        XCTAssertEqual(targetResult.location.offset, 7)
        XCTAssertEqual(
            targetResult.inheritance.map(\.name), ["RootProtocol", "ProtocolWithSystemInheritence"])
    }

    func test_typesConformingToProtocol_withCustomInheritence() throws {
        let results = instanceUnderTest.sourceDetails(conformingToProtocol: "ProtocolWithInheritence")
        XCTAssertEqual(results.count, 2)
        var targetResult = results[0]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "CustomInheritenceStruct")
        XCTAssertEqual(targetResult.sourceKind, .struct)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Inheritence.swift"))
        XCTAssertEqual(targetResult.location.line, 17)
        XCTAssertEqual(targetResult.location.column, 8)
        XCTAssertEqual(targetResult.location.offset, 8)
        XCTAssertEqual(
            targetResult.inheritance.map(\.name), ["ProtocolWithInheritence", "RootProtocol"])
        targetResult = results[1]
        XCTAssertNil(targetResult.parent)
        XCTAssertEqual(targetResult.name, "CustomInheritenceClass")
        XCTAssertEqual(targetResult.sourceKind, .class)
        XCTAssertTrue(targetResult.location.path.hasSuffix("Inheritence.swift"))
        XCTAssertEqual(targetResult.location.line, 22)
        XCTAssertEqual(targetResult.location.column, 7)
        XCTAssertEqual(targetResult.location.offset, 7)
        XCTAssertEqual(
            targetResult.inheritance.map(\.name), ["RootProtocol", "ProtocolWithInheritence"])
        let inheritedInheritence = try XCTUnwrap(results[1].inheritance.last?.inheritance.first)
        XCTAssertNil(inheritedInheritence.parent)
        XCTAssertEqual(inheritedInheritence.name, "BaseProtocol")
        XCTAssertEqual(inheritedInheritence.sourceKind, .protocol)
        XCTAssertTrue(inheritedInheritence.location.path.hasSuffix("Protocols.swift"))
        XCTAssertEqual(inheritedInheritence.location.line, 9)
        XCTAssertEqual(inheritedInheritence.location.column, 10)
        XCTAssertEqual(inheritedInheritence.location.offset, 10)
        XCTAssertTrue(inheritedInheritence.inheritance.isEmpty)
    }

    func test_sourceDetailsForFunctionsMatching_willReturnExpectedResults() throws {
        let results = instanceUnderTest.sourceDetails(forFunctionsMatching: "performOperation")

    }
}
