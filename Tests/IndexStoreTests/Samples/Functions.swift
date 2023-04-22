import Foundation

class FunctionClass {

    func performOperation(withName: String) {}

    class NestedFunctionClass {

        func performOperation(withAge: Int) {}

        class DoubleNestedFunctionClass {

            func performOperation(withName: String, age: Int) {}
        }
    }
}

protocol FunctionRootProtocol {
    func performOperation(withName: String)
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
