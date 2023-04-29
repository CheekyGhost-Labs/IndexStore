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

protocol FunctionProtocolWithSystemInheritence: Equatable {

    func performOperation(withAge: Int)
}

protocol FunctionBaseProtocol {

    func performOperation(withName: String, age: Int)
}

protocol FunctionProtocolWithInheritence: FunctionBaseProtocol {
    func performOperation(withName: String, age: Int, handler: @escaping (() -> Void))
}

struct Invocations {

    let instance = FunctionClass()

    init() {
        instance.performFunction(withPerson: ("name", 20))
    }
}

func isolatedFunction() {
    // no-op
}
