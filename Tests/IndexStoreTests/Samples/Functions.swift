import Foundation

class FunctionClass {

    func performFunction(withPerson: (name: String, age: Int)) {}

    func standardTestCaseInvocation() {}

    class NestedFunctionClass {

        func subclassTestCaseInvocation() {}

        class DoubleNestedFunctionClass {

            func notInvokedInTestCase() {}
        }
    }
}

protocol FunctionRootProtocol {
    func performOperation(withName: String)
    func executeOrder()
}

protocol FunctionProtocolWithSystemInheritance: Equatable {

    func performOperation(withAge: Int)
}

protocol FunctionBaseProtocol {

    func performOperation(withName: String, age: Int)
}

protocol FunctionProtocolWithInheritance: FunctionBaseProtocol {
    func performOperation(withName: String, age: Int, handler: @escaping (() -> Void))
}

struct Invocations {

    let instance = FunctionClass()
    let otherInstance = InvocationsConformance()

    init() {
        instance.performFunction(withPerson: ("name", 20))
    }

    func sample() {
        otherInstance.sampleInvocation()
        otherInstance.performOperation(withName: "test")
    }
}

func isolatedFunction() {
    // no-op
}

struct InvocationsConformance: FunctionRootProtocol {

    func sampleInvocation() {
        let instance = FunctionClass()
        instance.performFunction(withPerson: ("name", 20))
    }

    func performOperation(withName: String) {
        // no-op
    }

    func executeOrder() {
        // no-op
    }
}
