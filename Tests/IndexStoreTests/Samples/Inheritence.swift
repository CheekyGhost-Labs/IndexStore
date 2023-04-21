import Foundation

struct InheritenceStruct: ProtocolWithSystemInheritence, RootProtocol {

    let name: String = "name"
}

class InheritenceClass: RootProtocol, ProtocolWithSystemInheritence {

    let name: String = "name"

    public static func == (lhs: InheritenceClass, rhs: InheritenceClass) -> Bool {
        true
    }
}

struct CustomInheritenceStruct: ProtocolWithInheritence, RootProtocol {

    let name: String = "name"
}

class CustomInheritenceClass: RootProtocol, ProtocolWithInheritence {

    let name: String = "name"

    public static func == (lhs: CustomInheritenceClass, rhs: CustomInheritenceClass) -> Bool {
        true
    }
}
