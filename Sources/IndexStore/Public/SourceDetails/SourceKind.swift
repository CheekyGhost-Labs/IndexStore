//
//  SourceKind.swift
//  IndexStore
//
//  Created by CheekyGhost Labs on 19/4/2023.
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation
import IndexStoreDB

/// Enumeration of declaration types source kinds utilised when resolving source types.
public enum SourceKind: String, CaseIterable, Equatable {
    case unsupported
    case module
    case namespace
    case namespaceAlias
    case macro
    case `enum`
    case `struct`
    case `class`
    case `protocol`
    case `extension`
    case union
    case `typealias`
    case function
    case variable
    case field
    case enumConstant
    case instanceMethod
    case classMethod
    case staticMethod
    case instanceProperty
    case classProperty
    case staticProperty
    case constructor
    case destructor
    case conversionFunction
    case parameter
    case using
    case concept
    case commentTag

    // MARK: - Convenience

    public static var excludingExtensions: [SourceKind] {
        allCases.filter { $0 != .extension }
    }

    public static var excludingUnsupported: [SourceKind] {
        allCases.filter { $0 != .unsupported }
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
            self = .extension
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
