//
//  File.swift
//
//
//  Created by Michael O'Brien on 25/4/2023.
//

import Foundation

extension IndexStoreQuery {

    // MARK: - All Declarations

    /// Will return a query configured to search for declarations with ``SourceKind`` matching `.protocol`, `.class`, `.enum`, `.struct`, or `.typealias` source kinds.
    ///
    /// Defaults to:
    /// - kinds: [``SourceKind/protocol``, ``SourceKind/class``, ``SourceKind/enum``, ``SourceKind/struct``, ``SourceKind/typealias``]
    /// - roles: [``SourceRole/definition``]
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameter query: The type name to search for.
    /// - Returns: ``IndexStoreQuery``
    public static func allDeclarations(matching query: String) -> IndexStoreQuery {
        IndexStoreQuery(query: query)
            .withKinds(SourceKind.declarations)
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search within the given source files for declarations with ``SourceKind`` matching
    /// `.protocol`, `.class`, `.enum`, `.struct`, or `.typealias`.
    ///
    /// Defaults to:
    /// - kinds: [``SourceKind/protocol``, ``SourceKind/class``, ``SourceKind/enum``, ``SourceKind/struct``, ``SourceKind/typealias``]
    /// - roles: [``SourceRole/definition``]
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameters:
    ///   - sourceFiles: Array of source files to search for declarations in.
    ///   - query: Optional type name to search for.
    /// - Returns: ``IndexStoreQuery``
    public static func allDeclarations(in sourceFiles: [String], matching query: String? = nil) -> IndexStoreQuery {
        IndexStoreQuery(sourceFiles: sourceFiles)
            .withQuery(query)
            .withKinds(SourceKind.declarations)
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for `SourceKind.class` declarations.
    ///
    /// Defaults to:
    /// - kinds: [``SourceKind/class``]
    /// - roles: [``SourceRole/definition``]
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameter query: The type name to search for.
    /// - Returns: ``IndexStoreQuery``
    public static func classDeclarations(matching query: String) -> IndexStoreQuery {
        IndexStoreQuery(query: query)
            .withKinds([.class])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for `SourceKind.class` declarations within the given source files.
    ///
    /// Defaults to:
    /// - kinds: [``SourceKind/class``]
    /// - roles: [``SourceRole/definition``]
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameters:
    ///   - sourceFiles: Array of source files to search for declarations in.
    ///   - query: Optional type name to search for.
    /// - Returns: ``IndexStoreQuery``
    public static func classDeclarations(in sourceFiles: [String], matching query: String? = nil) -> IndexStoreQuery {
        IndexStoreQuery(sourceFiles: sourceFiles)
            .withQuery(query)
            .withKinds([.class])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for `SourceKind.struct` declarations.
    ///
    /// Defaults to:
    /// - kinds: [``SourceKind/struct``]
    /// - roles: [``SourceRole/definition``]
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameter query: The type name to search for.
    /// - Returns: ``IndexStoreQuery``
    public static func structDeclarations(matching query: String) -> IndexStoreQuery {
        IndexStoreQuery(query: query)
            .withKinds([.struct])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for `SourceKind.struct` declarations in the given source files.
    ///
    /// Defaults to:
    /// - kinds: [``SourceKind/struct``]
    /// - roles: [``SourceRole/definition``]
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameters:
    ///   - sourceFiles: Array of source files to search for declarations in.
    ///   - query: Optional type name to search for.
    /// - Returns: ``IndexStoreQuery``
    public static func structDeclarations(in sourceFiles: [String], matching query: String? = nil) -> IndexStoreQuery {
        IndexStoreQuery(sourceFiles: sourceFiles)
            .withQuery(query)
            .withKinds([.struct])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for `SourceKind.enum` declarations.
    ///
    /// Defaults to:
    /// - kinds: [``SourceKind/enum``]
    /// - roles: [``SourceRole/definition``]
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameter query: The type name to search for.
    /// - Returns: ``IndexStoreQuery``
    public static func enumDeclarations(matching query: String) -> IndexStoreQuery {
        IndexStoreQuery(query: query)
            .withKinds([.enum])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for `SourceKind.enum` declarations in the given source files.
    ///
    /// Defaults to:
    /// - kinds: [``SourceKind/enum``]
    /// - roles: [``SourceRole/definition``]
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameters:
    ///   - sourceFiles: Array of source files to search for declarations in.
    ///   - query: Optional type name to search for.
    /// - Returns: ``IndexStoreQuery``
    public static func enumDeclarations(in sourceFiles: [String], matching query: String? = nil) -> IndexStoreQuery {
        IndexStoreQuery(sourceFiles: sourceFiles)
            .withQuery(query)
            .withKinds([.enum])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for `SourceKind.typealias` declarations.
    ///
    /// Defaults to:
    /// - kinds: [``SourceKind/typealias``]
    /// - roles: [``SourceRole/definition``]
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameter query: The type name to search for.
    /// - Returns: ``IndexStoreQuery``
    public static func typealiasDeclarations(matching query: String) -> IndexStoreQuery {
        IndexStoreQuery(query: query)
            .withKinds([.typealias])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for `SourceKind.typealias` declarations in the given source files.
    ///
    /// Defaults to:
    /// - kinds: [``SourceKind/typealias``]
    /// - roles: [``SourceRole/definition``]
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameters:
    ///   - sourceFiles: Array of source files to search for declarations in.
    ///   - query: Optional type name to search for.
    /// - Returns: ``IndexStoreQuery``
    public static func typealiasDeclarations(in sourceFiles: [String], matching query: String? = nil) -> IndexStoreQuery {
        IndexStoreQuery(sourceFiles: sourceFiles)
            .withQuery(query)
            .withKinds([.typealias])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for `SourceKind.protocol` declarations.
    ///
    /// Defaults to:
    /// - kinds: [``SourceKind/protocol``]
    /// - roles: [``SourceRole/definition``]
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameter query: The type name to search for.
    /// - Returns: ``IndexStoreQuery``
    public static func protocolDeclarations(matching query: String) -> IndexStoreQuery {
        IndexStoreQuery(query: query)
            .withKinds([.protocol])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for `SourceKind.protocol` declarations in the given source files.
    ///
    /// Defaults to:
    /// - kinds: [``SourceKind/protocol``]
    /// - roles: [``SourceRole/definition``]
    /// - anchorStart: `true`
    /// - anchorEnd: `true`
    /// - includeSubsequence: `false`
    /// - ignoreCase: `false`
    /// - Parameters:
    ///   - sourceFiles: Array of source files to search for declarations in.
    ///   - query: Optional type name to search for.
    /// - Returns: ``IndexStoreQuery``
    public static func protocolDeclarations(in sourceFiles: [String], matching query: String? = nil) -> IndexStoreQuery {
        IndexStoreQuery(sourceFiles: sourceFiles)
            .withQuery(query)
            .withKinds([.protocol])
            .withRoles([.definition])
            .withAnchorStart(true)
            .withAnchorEnd(true)
            .withInlcudeSubsequences(false)
            .withIgnoringCase(false)
    }
}
