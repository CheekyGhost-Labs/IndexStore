import Foundation

typealias RootAlias = String

enum Foo {

    typealias NestedAlias = String

    enum Bar {

        typealias DoubleNestedAlias = String
    }
}

enum Bar {

    typealias NestedAlias = Int

}

struct FooBar {

    typealias StructAlias = String
}

class FooBarClass {

    typealias ClassAlias = String
}
