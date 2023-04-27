//
//  InvocationTestCase.swift
//
//
//  Created by Michael O'Brien on 26/4/2023.
//

import XCTest

class SampleTestCase: XCTestCase {

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
