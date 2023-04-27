//
//  IndexStore+Extensions.swift
//
//
//  Created by Michael O'Brien on 25/4/2023.
//

import Foundation

extension IndexStoreQuery {

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
    public static func extensions(ofType query: String) -> IndexStoreQuery {
        IndexStoreQuery(query: query)
            .withKinds([.extension])
            .withRoles([.definition])
            .withAnchorStart(false)
            .withAnchorEnd(false)
            .withInlcudeSubsequences(true)
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
    public static func extensions(in sourceFiles: [String], matching query: String? = nil) -> IndexStoreQuery {
        IndexStoreQuery(sourceFiles: sourceFiles)
            .withQuery(query)
            .withKinds([.extension])
            .withRoles([.definition])
            .withAnchorStart(false)
            .withAnchorEnd(false)
            .withInlcudeSubsequences(true)
            .withIgnoringCase(false)
    }
}
