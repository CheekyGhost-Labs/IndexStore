//
//  SourceRole.swift
//
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Foundation
import IndexStoreDB

/// Enumeration of supported roles a source declaration can contain.
///
/// **Note: ** These are mapped from the `IndexStoreDB.SymbolRole` option set.
public struct SourceRole: OptionSet, Hashable, Equatable, CustomStringConvertible, CustomDebugStringConvertible, Sendable {
    public var rawValue: UInt64

    // Primary Roles

    /// Represents a symbol that is being introduced, specifying the name, type, and potentially other attributes.
    /// The symbol has no complete implementation, e.g., protocol requirements or methods to be overridden in subclasses.
    public static let declaration: SourceRole = .init(rawValue: SymbolRole.declaration.rawValue)

    /// Represents a symbol that provides a complete implementation, e.g., class, struct, enum, or function body.
    public static let definition: SourceRole = .init(rawValue: SymbolRole.definition.rawValue)

    /// Represents a reference to a symbol, such as using a type, variable, or calling a function.
    public static let reference: SourceRole = .init(rawValue: SymbolRole.reference.rawValue)

    /// Represents a read access to a variable or property.
    public static let read: SourceRole = .init(rawValue: SymbolRole.read.rawValue)

    /// Represents a write access to a variable or property.
    public static let write: SourceRole = .init(rawValue: SymbolRole.write.rawValue)

    /// Represents a call to a function or method.
    public static let call: SourceRole = .init(rawValue: SymbolRole.call.rawValue)

    /// Represents a dynamic method dispatch, often found in Objective-C code or Swift code that uses `@objc`.
    public static let dynamic: SourceRole = .init(rawValue: SymbolRole.dynamic.rawValue)

    /// Represents a symbol that is the target of an address-of operation, such as `&variable`.
    public static let addressOf: SourceRole = .init(rawValue: SymbolRole.addressOf.rawValue)

    /// Represents an implicit reference to a symbol, such as compiler-generated code or synthesized properties.
    public static let implicit: SourceRole = .init(rawValue: SymbolRole.implicit.rawValue)

    // Relationship Roles

    /// Represents a symbol that is a child of another symbol, such as a method within a class or a variable within a struct.
    public static let childOf: SourceRole = .init(rawValue: SymbolRole.childOf.rawValue)

    /// Represents a symbol that serves as a base class or protocol for another symbol.
    public static let baseOf: SourceRole = .init(rawValue: SymbolRole.baseOf.rawValue)

    /// Represents a method that overrides a method from its superclass or conforms to a protocol requirement.
    public static let overrideOf: SourceRole = .init(rawValue: SymbolRole.overrideOf.rawValue)

    /// Represents a symbol that receives a message, such as a method being called or an event being handled.
    public static let receivedBy: SourceRole = .init(rawValue: SymbolRole.receivedBy.rawValue)

    /// Represents a symbol that is called by another symbol, such as a method being called by a function.
    public static let calledBy: SourceRole = .init(rawValue: SymbolRole.calledBy.rawValue)

    /// Represents a symbol that is extended by another symbol, such as a class being extended by a subclass or a protocol being conformed to by a type.
    public static let extendedBy: SourceRole = .init(rawValue: SymbolRole.extendedBy.rawValue)

    /// Represents a property accessor (getter or setter) of a property.
    public static let accessorOf: SourceRole = .init(rawValue: SymbolRole.accessorOf.rawValue)

    /// Represents a symbol that is contained by another symbol, such as a local variable within a function or a nested type within a type.
    public static let containedBy: SourceRole = .init(rawValue: SymbolRole.containedBy.rawValue)

    /// Represents a symbol that is a type of an Interface Builder (IB) outlet, action, or other user interface-related property.
    public static let ibTypeOf: SourceRole = .init(rawValue: SymbolRole.ibTypeOf.rawValue)

    /// Represents a symbol that is a specialized version of another symbol, such as a generic function or type being specialized with specific type arguments.
    public static let specializationOf: SourceRole = .init(rawValue: SymbolRole.specializationOf.rawValue)

    /// Represents a symbol that is the canonical occurrence of a symbol, which is the preferred location for displaying information about the symbol.
    public static let canonical: SourceRole = .init(rawValue: SymbolRole.canonical.rawValue)

    /// Convenience set that includes all available roles
    public static let all: SourceRole = .init(rawValue: SymbolRole.all.rawValue)

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
        let joined = results.joined(separator: "|")
        return results.count == 1 ? joined : "[\(joined)]"
    }

    public var debugDescription: String { description }
}
