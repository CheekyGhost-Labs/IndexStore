//
//  File.swift
//  
//
//  Created by Michael O'Brien on 25/4/2023.
//

import Foundation

public extension IndexStoreQuery {

    // MARK: - All Declarations

    /// Will return a query configured to search for declarations with ``SourceKind`` matching `.protocol`, `.class`, `.enum`, `.struct`, or `.typealias` source kinds.
    ///
    /// Defaults to:
    /// - kinds: `[.protocol, .class, .enum, .struct, .typealias]`
    /// - roles: `[.definition]]`
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameter query: The type name to search for.
    /// - Returns: ``IndexStoreQuery``
    static func allDeclarations(_ query: String) -> IndexStoreQuery {
        IndexStoreQuery(query: query)
            .withKinds([.protocol, .class, .enum, .struct, .typealias])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for `SourceKind.class` declarations
    ///
    /// Defaults to:
    /// - kinds: `[.class]`
    /// - roles: `[.definition]]`
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameter query: The type name to search for.
    /// - Returns: ``IndexStoreQuery``
    static func classDeclarations(_ query: String) -> IndexStoreQuery {
        IndexStoreQuery(query: query)
            .withKinds([.class])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for `SourceKind.struct` declarations
    ///
    /// Defaults to:
    /// - kinds: `[.struct]`
    /// - roles: `[.definition]]`
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameter query: The type name to search for.
    /// - Returns: ``IndexStoreQuery``
    static func structDeclarations(_ query: String) -> IndexStoreQuery {
        IndexStoreQuery(query: query)
            .withKinds([.struct])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for `SourceKind.enum` declarations
    ///
    /// Defaults to:
    /// - kinds: `[.enum]`
    /// - roles: `[.definition]]`
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameter query: The type name to search for.
    /// - Returns: ``IndexStoreQuery``
    static func enumDeclarations(_ query: String) -> IndexStoreQuery {
        IndexStoreQuery(query: query)
            .withKinds([.enum])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for `SourceKind.typealias` declarations
    ///
    /// Defaults to:
    /// - kinds: `[.typealias]`
    /// - roles: `[.definition]]`
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameter query: The type name to search for.
    /// - Returns: ``IndexStoreQuery``
    static func typealiasDeclarations(_ query: String) -> IndexStoreQuery {
        IndexStoreQuery(query: query)
            .withKinds([.typealias])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for `SourceKind.protocol` declarations
    ///
    /// Defaults to:
    /// - kinds: `[.protocol]`
    /// - roles: `[.definition]]`
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameter query: The type name to search for.
    /// - Returns: ``IndexStoreQuery``
    static func protocolDeclarations(_ query: String) -> IndexStoreQuery {
        IndexStoreQuery(query: query)
            .withKinds([.protocol])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }
}
