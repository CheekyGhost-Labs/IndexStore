import Foundation

struct InheritanceStruct: ProtocolWithSystemInheritance, RootProtocol {

    let name: String = "name"
}

class InheritanceClass: RootProtocol, ProtocolWithSystemInheritance {

    let name: String = "name"

    public static func == (lhs: InheritanceClass, rhs: InheritanceClass) -> Bool {
        true
    }
}

struct CustomInheritanceStruct: ProtocolWithInheritance, RootProtocol {

    let name: String = "name"
}

class CustomInheritanceClass: RootProtocol, ProtocolWithInheritance {

    let name: String = "name"

    public static func == (lhs: CustomInheritanceClass, rhs: CustomInheritanceClass) -> Bool {
        true
    }
}

class InheritanceSubclass: InheritanceClass {

    func sample() {
        // no-op
    }
}

class SystemInheritanceSubclass: NSObject {

    override init() {
        super.init()
    }
}
