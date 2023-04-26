//
//  SourceRoleTests.swift
//  
//
//  Created by Michael O'Brien on 27/4/2023.
//

import XCTest
import IndexStore

final class SourceRoleTests: XCTestCase {

    func test_description_willReturnExpectedValues() throws {
        XCTAssertEqual(SourceRole.declaration.description, "declaration")
        XCTAssertEqual(SourceRole.definition.description, "definition")
        XCTAssertEqual(SourceRole.reference.description, "reference")
        XCTAssertEqual(SourceRole.read.description, "read")
        XCTAssertEqual(SourceRole.write.description, "write")
        XCTAssertEqual(SourceRole.call.description, "call")
        XCTAssertEqual(SourceRole.dynamic.description, "dynamic")
        XCTAssertEqual(SourceRole.addressOf.description, "addressOf")
        XCTAssertEqual(SourceRole.implicit.description, "implicit")
        XCTAssertEqual(SourceRole.childOf.description, "childOf")
        XCTAssertEqual(SourceRole.baseOf.description, "baseOf")
        XCTAssertEqual(SourceRole.overrideOf.description, "overrideOf")
        XCTAssertEqual(SourceRole.receivedBy.description, "receivedBy")
        XCTAssertEqual(SourceRole.calledBy.description, "calledBy")
        XCTAssertEqual(SourceRole.extendedBy.description, "extendedBy")
        XCTAssertEqual(SourceRole.accessorOf.description, "accessorOf")
        XCTAssertEqual(SourceRole.containedBy.description, "containedBy")
        XCTAssertEqual(SourceRole.ibTypeOf.description, "ibTypeOf")
        XCTAssertEqual(SourceRole.specializationOf.description, "specializationOf")
    }

    func test_debugDescription_willReturnExpectedValues() throws {
        XCTAssertEqual(SourceRole.declaration.debugDescription, "declaration")
        XCTAssertEqual(SourceRole.definition.debugDescription, "definition")
        XCTAssertEqual(SourceRole.reference.debugDescription, "reference")
        XCTAssertEqual(SourceRole.read.debugDescription, "read")
        XCTAssertEqual(SourceRole.write.debugDescription, "write")
        XCTAssertEqual(SourceRole.call.debugDescription, "call")
        XCTAssertEqual(SourceRole.dynamic.debugDescription, "dynamic")
        XCTAssertEqual(SourceRole.addressOf.debugDescription, "addressOf")
        XCTAssertEqual(SourceRole.implicit.debugDescription, "implicit")
        XCTAssertEqual(SourceRole.childOf.debugDescription, "childOf")
        XCTAssertEqual(SourceRole.baseOf.debugDescription, "baseOf")
        XCTAssertEqual(SourceRole.overrideOf.debugDescription, "overrideOf")
        XCTAssertEqual(SourceRole.receivedBy.debugDescription, "receivedBy")
        XCTAssertEqual(SourceRole.calledBy.debugDescription, "calledBy")
        XCTAssertEqual(SourceRole.extendedBy.debugDescription, "extendedBy")
        XCTAssertEqual(SourceRole.accessorOf.debugDescription, "accessorOf")
        XCTAssertEqual(SourceRole.containedBy.debugDescription, "containedBy")
        XCTAssertEqual(SourceRole.ibTypeOf.debugDescription, "ibTypeOf")
        XCTAssertEqual(SourceRole.specializationOf.debugDescription, "specializationOf")
    }
}
