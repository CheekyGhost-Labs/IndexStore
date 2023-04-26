import Foundation

class FunctionClass {

    func performOperation(withName: String) {}

    func doTheThingo() {}

    class NestedFunctionClass {

        func performOperation(withAge: Int) {}

        class DoubleNestedFunctionClass {

            func performOperation(withName: String, age: Int) {}
        }
    }
}

protocol FunctionRootProtocol {
    func performOperation(withName: String)
    func doTheThings()
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
        instance.doTheThingo()
    }
}

func isolatedFunction() {
    // no-op
}
