//
//  IndexStore+Extensions.swift
//
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Foundation

public extension IndexStoreQuery {
    // MARK: - Functions

    /// Will return a query configured to search for extensions whose name matches the given query.
    ///
    /// Defaults to:
    /// - kinds: [``SourceKind/extension``]
    /// - roles: [``SourceRole/definition``]
    /// - anchorStart: `false`
    /// - anchorEnd: `false`
    /// - includeSubsequence: `true`
    /// - ignoreCase: `false`
    /// - Parameter query: The type name to search for.
    /// - Returns: ``IndexStoreQuery``
    static func extensions(ofType query: String) -> IndexStoreQuery {
        IndexStoreQuery(query: query)
            .withKinds([.extension])
            .withRoles([.definition])
            .withAnchorStart(false)
            .withAnchorEnd(false)
            .withIncludeSubsequences(true)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for extensions within the given source files.
    ///
    /// Defaults to:
    /// - kinds: [``SourceKind/extension``]
    /// - roles: [``SourceRole/definition``]
    /// - anchorStart: `false`
    /// - anchorEnd: `false`
    /// - includeSubsequence: `true`
    /// - ignoreCase: `false`
    /// - Parameters:
    ///   - sourceFiles: Array of source files to search for extensions in.
    ///   - query: Optional type name to search for.
    /// - Returns: ``IndexStoreQuery``
    /// - Returns: ``IndexStoreQuery``
    static func extensions(in sourceFiles: [String], matching query: String? = nil) -> IndexStoreQuery {
        IndexStoreQuery(sourceFiles: sourceFiles)
            .withQuery(query)
            .withKinds([.extension])
            .withRoles([.definition])
            .withAnchorStart(false)
            .withAnchorEnd(false)
            .withIncludeSubsequences(true)
            .withIgnoringCase(false)
    }
}
