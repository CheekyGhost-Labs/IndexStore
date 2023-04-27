//
//  SourceKind.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation
import IndexStoreDB

/// Enumeration of declaration types source kinds utilised when resolving source types.
public enum SourceKind: String, CaseIterable, Hashable, Equatable {
    /// Represents an unsupported or unknown source kind.
    case unsupported
    /// Represents a module, such as a Swift module or a C++ namespace.
    case module
    /// Represents a namespace, such as in C++ code.
    case namespace
    /// Represents a namespace alias, often found in C++ code.
    case namespaceAlias
    /// Represents a preprocessor macro.
    case macro
    /// Represents an enumeration type.
    case `enum`
    /// Represents a structure type.
    case `struct`
    /// Represents a class type.
    case `class`
    /// Represents a protocol or interface type.
    case `protocol`
    /// Represents an extension or category of a type.
    case `extension`
    /// Represents a union type, often found in C or C++ code.
    case union
    /// Represents a type alias, such as a `typealias` in Swift or a `typedef` in C++.
    case `typealias`
    /// Represents a function or method that does not belong to an instance or type.
    case function
    /// Represents a variable, such as a global variable or a local variable in a function.
    case variable
    /// Represents a field within a structure or class.
    case field
    /// Represents an enumeration constant.
    case enumConstant
    /// Represents an instance method of a class or structure.
    case instanceMethod
    /// Represents a class method, often marked with the `class` keyword in Swift or a static method in C++.
    case classMethod
    /// Represents a static method or function, often marked with the `static` keyword in Swift or C++.
    case staticMethod
    /// Represents an instance property of a class or structure.
    case instanceProperty
    /// Represents a class property, often marked with the `class` keyword in Swift.
    case classProperty
    /// Represents a static property, often marked with the `static` keyword in Swift or C++.
    case staticProperty
    /// Represents a constructor or initializer of a class or structure.
    case constructor
    /// Represents a destructor or deinitializer of a class or structure.
    case destructor
    /// Represents a conversion function, such as a custom type casting function.
    case conversionFunction
    /// Represents a function or method parameter.
    case parameter
    /// Represents a using declaration or directive, often found in C++ code.
    case using
    /// Represents a concept, often found in C++20 code.
    case concept
    /// Represents a documentation comment tag, such as a `@param` or `@return` tag in a documentation comment.
    case commentTag

    // MARK: - Convenience

    /// Will return all cases except the `unsupported` case.
    public static var supported: [SourceKind] {
        excluding([.unsupported])
    }

    /// Will return all source kind cases excluding the provided set.
    /// - Parameter exclusions: Array of source kinds to exclude.
    /// - Returns: Array of ``SourceKind`` cases.
    public static func excluding(_ exclusions: [SourceKind]) -> [SourceKind] {
        allCases.filter { !exclusions.contains($0) }
    }

    /// Will return all source kind cases representing common declarations.
    /// **Note: ** Valid function kinds are the following cases:
    /// - ``SourceKind/protocol``
    /// - ``SourceKind/class``
    /// - ``SourceKind/enum``
    /// - ``SourceKind/struct``
    /// - ``SourceKind/typealias``
    public static var declarations: [SourceKind] {
        [.protocol, .class, .enum, .struct, .typealias]
    }

    /// Will return all source kind cases representing functions.
    /// **Note: ** Valid function kinds are the following cases:
    /// - ``SourceKind/instanceMethod``
    /// - ``SourceKind/function``
    /// - ``SourceKind/staticMethod``
    /// - ``SourceKind/classMethod``
    public static var allFunctions: [SourceKind] {
        [.instanceMethod, .function, .staticMethod, .classMethod]
    }

    /// Will return all source kind cases representing properties.
    /// **Note: ** Valid function kinds are the following cases:
    /// - ``SourceKind/variable``
    /// - ``SourceKind/instanceProperty``
    /// - ``SourceKind/staticProperty``
    /// - ``SourceKind/classProperty``
    public static var properties: [SourceKind] {
        [.variable, .instanceProperty, .classProperty, .staticProperty]
    }

    // MARK: - Lifecycle

    public init(symbolKind: IndexSymbolKind) {
        switch symbolKind {
        case .unknown:
            self = .unsupported
        case .module:
            self = .module
        case .namespace:
            self = .namespace
        case .namespaceAlias:
            self = .namespaceAlias
        case .macro:
            self = .macro
        case .enum:
            self = .enum
        case .struct:
            self = .struct
        case .class:
            self = .class
        case .protocol:
            self = .protocol
        case .extension:
            self = .`extension`
        case .union:
            self = .union
        case .typealias:
            self = .typealias
        case .function:
            self = .function
        case .variable:
            self = .variable
        case .field:
            self = .field
        case .enumConstant:
            self = .enumConstant
        case .instanceMethod:
            self = .instanceMethod
        case .classMethod:
            self = .classMethod
        case .staticMethod:
            self = .staticMethod
        case .instanceProperty:
            self = .instanceProperty
        case .classProperty:
            self = .classProperty
        case .staticProperty:
            self = .staticProperty
        case .constructor:
            self = .constructor
        case .destructor:
            self = .destructor
        case .conversionFunction:
            self = .conversionFunction
        case .parameter:
            self = .parameter
        case .using:
            self = .using
        case .concept:
            self = .concept
        case .commentTag:
            self = .commentTag
        }
    }

    // MARK: - Convenience

    public var indexSymbolKind: IndexSymbolKind {
        switch self {
        case .unsupported:
            return .unknown
        case .module:
            return .module
        case .namespace:
            return .namespace
        case .namespaceAlias:
            return .namespaceAlias
        case .macro:
            return .macro
        case .enum:
            return .enum
        case .struct:
            return .struct
        case .class:
            return .class
        case .protocol:
            return .protocol
        case .extension:
            return .extension
        case .union:
            return .union
        case .typealias:
            return .typealias
        case .function:
            return .function
        case .variable:
            return .variable
        case .field:
            return .field
        case .enumConstant:
            return .enumConstant
        case .instanceMethod:
            return .instanceMethod
        case .classMethod:
            return .classMethod
        case .staticMethod:
            return .staticMethod
        case .instanceProperty:
            return .instanceProperty
        case .classProperty:
            return .classProperty
        case .staticProperty:
            return .staticProperty
        case .constructor:
            return .constructor
        case .destructor:
            return .destructor
        case .conversionFunction:
            return .conversionFunction
        case .parameter:
            return .parameter
        case .using:
            return .using
        case .concept:
            return .concept
        case .commentTag:
            return .commentTag
        }
    }
}
