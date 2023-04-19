//
//  SourceLocation.swift
//  IndexStore
//
//  Created by CheekyGhost Labs on 19/4/2023.
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation
import IndexStoreDB

/// Struct representing the location of a source declaration.
public struct SourceLocation: Equatable, CustomStringConvertible {

    /// The absolute path for the source file.
    public let path: String

    /// The line the source declaration/type is on.
    public let line: Int

    /// The horizontal position of source declaration/type.
    public let column: Int

    /// The UTF-8 byte offset into the file where this location resides.
    public let offset: Int

    // MARK: - Lifecycle

    public init(path: String, line: Int, column: Int, offset: Int) {
        self.path = path
        self.line = line
        self.column = column
        self.offset = offset
    }

    public init(symbol: SymbolOccurrence) {
        path = symbol.location.path
        line = symbol.location.line
        column = symbol.location.utf8Column
        offset = symbol.location.utf8Column
    }

    // MARK: - Conformance: CustomStringConvertible

    public var description: String {
        "\(path):\(line):\(column)"
    }
}
