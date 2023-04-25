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
/// **Note: ** These are mapped from the `IndexStoreDB.SymbolRole` option set.
public struct SourceRole: OptionSet, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
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
    public static let canonical: SourceRole = SourceRole(rawValue: SymbolRole.canonical.rawValue)

    // Convenience
    public static let all: SourceRole = SourceRole(rawValue: SymbolRole.all.rawValue)

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    // MARK: - Convenience

    public var description: String {
        var results: [String] = []
        if contains(.declaration) { results.append("declaration") }
        if contains(.definition) { results.append("definition") }
        if contains(.reference) { results.append("reference") }
        if contains(.read) { results.append("read") }
        if contains(.write) { results.append("write") }
        if contains(.call) { results.append("call") }
        if contains(.dynamic) { results.append("dynamic") }
        if contains(.addressOf) { results.append("addressOf") }
        if contains(.implicit) { results.append("implicit") }
        if contains(.childOf) { results.append("childOf") }
        if contains(.baseOf) { results.append("baseOf") }
        if contains(.overrideOf) { results.append("overrideOf") }
        if contains(.receivedBy) { results.append("receivedBy") }
        if contains(.calledBy) { results.append("calledBy") }
        if contains(.extendedBy) { results.append("extendedBy") }
        if contains(.accessorOf) { results.append("accessorOf") }
        if contains(.containedBy) { results.append("containedBy") }
        if contains(.ibTypeOf) { results.append("ibTypeOf") }
        if contains(.specializationOf) { results.append("specializationOf") }
        return results.joined(separator: ", ")
    }

    public var debugDescription: String { description }
}
