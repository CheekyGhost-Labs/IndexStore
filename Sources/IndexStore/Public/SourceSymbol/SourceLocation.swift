//
//  SourceLocation.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Foundation
import IndexStoreDB

/// Struct representing the location of a source declaration.
public struct SourceLocation: Equatable, Hashable, CustomStringConvertible {

    /// The absolute path for the source file.
    public let path: String

    /// The parent package module name.
    public let moduleName: String

    /// The line the source declaration/type is on.
    public let line: Int

    /// The horizontal position of source declaration/type.
    public let column: Int

    /// The UTF-8 byte offset into the file where this location resides.
    public let offset: Int

    /// `Bool` whether the source location is part of the system/platform.
    public let isSystem: Bool

    /// `Bool` indicating whether the `path` resolves to a stale or missing location.
    public let isStale: Bool

    // MARK: - Lifecycle

    public init(path: String, moduleName: String, line: Int, column: Int, offset: Int, isSystem: Bool, isStale: Bool) {
        self.path = path
        self.moduleName = moduleName
        self.line = line
        self.column = column
        self.offset = offset
        self.isSystem = isSystem
        self.isStale = isStale
    }

    public init(symbol: SymbolOccurrence) {
        path = symbol.location.path
        moduleName = symbol.location.moduleName
        line = symbol.location.line
        column = symbol.location.utf8Column
        offset = symbol.location.utf8Column
        isSystem = symbol.location.isSystem
        isStale = !FileManager.default.fileExists(atPath: path)
    }

    // MARK: - Conformance: CustomStringConvertible

    public var description: String {
        "\(moduleName)::\(path)::\(line)::\(column)"
    }
}
