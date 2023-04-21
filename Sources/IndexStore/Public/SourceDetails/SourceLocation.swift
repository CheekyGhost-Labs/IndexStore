//
//  SourceLocation.swift
//  IndexStore
//
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

    /// `Bool` indicating whether the `path` resolves to a stale or missing location.
    public let isStale: Bool

    // MARK: - Lifecycle

    public init(path: String, line: Int, column: Int, offset: Int, isStale: Bool) {
        self.path = path
        self.line = line
        self.column = column
        self.offset = offset
        self.isStale = isStale
    }

    public init(symbol: SymbolOccurrence) {
        path = symbol.location.path
        line = symbol.location.line
        column = symbol.location.utf8Column
        offset = symbol.location.utf8Column
        isStale = FileManager.default.fileExists(atPath: path)
    }

    // MARK: - Conformance: CustomStringConvertible

    public var description: String {
        "\(path):\(line):\(column)"
    }
}
