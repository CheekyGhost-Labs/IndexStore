//
//  File.swift
//
//
//  Created by Michael O'Brien on 19/4/2023.
//

import Foundation
import IndexStoreDB

/// Enumeration of supported roles a source declaration can contain.
///
/// **Note: ** These are mapped from the ``IndexStoreDB.SymbolRole`` option set.
public struct SourceRole: OptionSet, Hashable {
    public var rawValue: UInt64
    // Primary Roles
    public static let declaration: SourceRole = SourceRole(rawValue: SymbolRole.declaration.rawValue)
    public static let definition: SourceRole = SourceRole(rawValue: SymbolRole.definition.rawValue)
    public static let reference: SourceRole = SourceRole(rawValue: SymbolRole.reference.rawValue)
    public static let read: SourceRole = SourceRole(rawValue: SymbolRole.read.rawValue)
    public static let write: SourceRole = SourceRole(rawValue: SymbolRole.write.rawValue)
    public static let call: SourceRole = SourceRole(rawValue: SymbolRole.call.rawValue)
    public static let `dynamic`: SourceRole = SourceRole(rawValue: SymbolRole.dynamic.rawValue)
    public static let addressOf: SourceRole = SourceRole(rawValue: SymbolRole.addressOf.rawValue)
    public static let implicit: SourceRole = SourceRole(rawValue: SymbolRole.implicit.rawValue)
    // Relationship Roles
    public static let childOf: SourceRole = SourceRole(rawValue: SymbolRole.childOf.rawValue)
    public static let baseOf: SourceRole = SourceRole(rawValue: SymbolRole.baseOf.rawValue)
    public static let overrideOf: SourceRole = SourceRole(rawValue: SymbolRole.overrideOf.rawValue)
    public static let receivedBy: SourceRole = SourceRole(rawValue: SymbolRole.receivedBy.rawValue)
    public static let calledBy: SourceRole = SourceRole(rawValue: SymbolRole.calledBy.rawValue)
    public static let extendedBy: SourceRole = SourceRole(rawValue: SymbolRole.extendedBy.rawValue)
    public static let accessorOf: SourceRole = SourceRole(rawValue: SymbolRole.accessorOf.rawValue)
    public static let containedBy: SourceRole = SourceRole(rawValue: SymbolRole.containedBy.rawValue)
    public static let ibTypeOf: SourceRole = SourceRole(rawValue: SymbolRole.ibTypeOf.rawValue)
    public static let specializationOf: SourceRole = SourceRole(rawValue: SymbolRole.specializationOf.rawValue)
    // Additionals
    public static let canonical: SymbolRole = SymbolRole(rawValue: SymbolRole.canonical.rawValue)

    // Convenience
    public static let all: SymbolRole = SymbolRole(rawValue: ~0)

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
}
