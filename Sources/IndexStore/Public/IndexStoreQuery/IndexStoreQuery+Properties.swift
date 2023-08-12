//
//  IndexStore+Properties.swift
//
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Foundation

public extension IndexStoreQuery {
    // MARK: - Variables

    /// Will return a query configured to search for properties whose name matches the given query.
    ///
    /// Defaults to:
    /// - kinds:  [``SourceKind/variable``, ``SourceKind/instanceProperty``, ``SourceKind/staticProperty``, ``SourceKind/classProperty``]
    /// - roles: [``SourceRole/definition``, ``SourceRole/declaration``, ``SourceRole/childOf``, ``SourceRole/canonical``]
    /// - anchorStart: `false`
    /// - anchorEnd: `false`
    /// - includeSubsequence: `false` // will still include partial matches
    /// - ignoreCase: `false`
    /// - Parameter query: The type name to search for.
    /// - Returns: ``IndexStoreQuery``
    static func properties(_ query: String) -> IndexStoreQuery {
        IndexStoreQuery(query: query)
            .withKinds(SourceKind.properties)
            .withRoles([.definition, .childOf, .canonical])
            .withAnchorStart(false)
            .withAnchorEnd(false)
            .withIncludeSubsequences(false)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for properties within the given source files.
    ///
    /// Defaults to:
    /// - kinds:  [``SourceKind/variable``, ``SourceKind/instanceProperty``, ``SourceKind/staticProperty``, ``SourceKind/classProperty``]
    /// - roles: [``SourceRole/definition``, ``SourceRole/declaration``, ``SourceRole/childOf``, ``SourceRole/canonical``]
    /// - anchorStart: `false`
    /// - anchorEnd: `false`
    /// - includeSubsequence: `false` // will still include partial matches
    /// - ignoreCase: `false`
    /// - Parameters:
    ///   - sourceFiles: Array of source files to search for functions in.
    ///   - query: Optional type name to search for.
    /// - Returns: ``IndexStoreQuery``
    static func properties(in sourceFiles: [String], matching query: String? = nil) -> IndexStoreQuery {
        IndexStoreQuery(sourceFiles: sourceFiles)
            .withQuery(query)
            .withKinds(SourceKind.properties)
            .withRoles([.definition, .childOf, .canonical])
            .withAnchorStart(false)
            .withAnchorEnd(false)
            .withIncludeSubsequences(true)
            .withIgnoringCase(false)
    }
}
