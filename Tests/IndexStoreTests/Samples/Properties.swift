//
//  Properties.swift
//  
//
//  Created by Michael O'Brien on 29/4/2023.
//

import Foundation

protocol PropertiesProtocol {

    var sampleProperty: String { get set }

    var sampleClosureProperty: () -> Void { get set }
}

struct PropertiesStruct {

    var sampleProperty: String = ""

    var sampleClosureProperty: () -> Void = {}
}

class PropertiesClass {

    var sampleProperty: String = "name"

    var sampleClosureProperty: () -> Void = {}

}

struct PropertiesConformance: PropertiesProtocol {

    var sampleProperty: String = ""

    var sampleClosureProperty: () -> Void = {}

    mutating func invocation() {
        sampleProperty = ""
    }
}

class PropertiesSubclass: PropertiesClass {

    override var sampleProperty: String {
        get {
            "name"
        }
        set {}
    }

    override var sampleClosureProperty: () -> Void {
        get {
            {}
        }
        set {}
    }

    func invocation() {
        sampleProperty = "test"
    }
}
