//
//  Typealias.swift
//  IndexStoreTests
//
//  Created by CheekyGhost Labs on 19/4/2023.
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

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
