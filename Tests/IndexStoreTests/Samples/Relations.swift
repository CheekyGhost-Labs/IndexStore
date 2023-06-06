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
    }

    func example() {
        _ = CustomClass()
    }

    var relation: RelatedEnum = .sample

    func testThing() {
        relation = .sample
    }
}

enum RelatedEnum {
    case sample
}
