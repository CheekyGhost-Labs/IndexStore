//
//  File.swift
//  
//
//  Created by Michael O'Brien on 12/8/2023.
//

import Foundation
import AppKit

extension NSColor {
    static let helperColor: NSColor = .findHighlightColor
}

class Container {

    let colorOne: NSColor

    let colorTwo: NSColor

    let colorThree: NSColor

    init(color: NSColor = .white) {
        self.colorOne = color
        self.colorTwo = NSColor(white: 0.5, alpha: 0.5)
        self.colorThree = .helperColor
    }
}
