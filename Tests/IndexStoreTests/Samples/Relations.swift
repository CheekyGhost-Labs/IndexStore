//
//  Relations.swift
//  
//
//  Created by Michael O'Brien on 5/6/2023.
//

import Foundation

class CustomClass {
    init() {}
}

class RelationClass {

    var customProperty: CustomClass

    init() {
        customProperty = CustomClass()
        thing = .derp
    }

    func example() {
        _ = CustomClass()
    }

    var relation: RelatedEnum = .sample

    func testThing() {
        relation = .sample
    }

    var thing: Thing
}

enum RelatedEnum {
    case sample
}


class Thing {
    class var derp: Thing { Thing() }
}
