//
//  InvocationTestCase.swift
//
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import XCTest

class SampleTestCase: XCTestCase {

    var baseProperty: String = ""

    static var basePropertyTwo: String = ""
}

extension XCTestCase {

    func extendedMethod() {
        // no-op
    }
}

final class InvocationTestCase: SampleTestCase {

    let instance: FunctionClass = .init()

    func test_invokingMethod() throws {
        instance.standardTestCaseInvocation()
    }
}

final class StandardTestCase: XCTestCase {

    let instance: FunctionClass.NestedFunctionClass = .init()

    func test_invokingMethod() throws {
        instance.subclassTestCaseInvocation()
    }
}
