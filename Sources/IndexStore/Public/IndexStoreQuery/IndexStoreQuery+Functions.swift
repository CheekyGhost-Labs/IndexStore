//
//  File.swift
//  
//
//  Created by Michael O'Brien on 25/4/2023.
//

import Foundation

public extension IndexStoreQuery {

    // MARK: - Functions

    /// Will return a query configured to search for functions whose name matches the given query.
    ///
    /// Defaults to:
    /// - kinds:  [``SourceKind/instanceMethod``, ``SourceKind/function``, ``SourceKind/staticMethod``, ``SourceKind/classMethod``]
    /// - roles: [``SourceRole/definition``, ``SourceRole/declaration``, ``SourceRole/childOf``, ``SourceRole/canonical``]
    /// - anchorStart: `false`
    /// - anchorEnd: `false`
    /// - includeSubsequence: `true`
    /// - ignoreCase: `false`
    /// - Parameter query: The type name to search for.
    /// - Returns: ``IndexStoreQuery``
    static func functions(_ query: String) -> IndexStoreQuery {
        IndexStoreQuery(query: query)
            .withKinds(SourceKind.allFunctions)
            .withRoles([.definition, .childOf, .canonical])
            .withAnchorStart(false)
            .withAnchorEnd(false)
            .withInlcudeSubsequences(true)
            .withIgnoringCase(false)
    }

    /// Will return a query configured to search for functions within the given source files.
    ///
    /// Defaults to:
    /// - kinds:  [``SourceKind/instanceMethod``, ``SourceKind/function``, ``SourceKind/staticMethod``, ``SourceKind/classMethod``]
    /// - roles: [``SourceRole/definition``, ``SourceRole/declaration``, ``SourceRole/childOf``, ``SourceRole/canonical``]
    /// - anchorStart: `false`
    /// - anchorEnd: `false`
    /// - includeSubsequence: `true`
    /// - ignoreCase: `false`
    /// - Parameters:
    ///   - sourceFiles: Array of source files to search for functions in.
    ///   - query: Optional type name to search for.
    /// - Returns: ``IndexStoreQuery``
    static func functions(in sourceFiles: [String], matching query: String? = nil) -> IndexStoreQuery {
        IndexStoreQuery(sourceFiles: sourceFiles)
            .withQuery(query)
            .withKinds(SourceKind.allFunctions)
            .withRoles([.definition, .childOf, .canonical])
            .withAnchorStart(false)
            .withAnchorEnd(false)
            .withInlcudeSubsequences(true)
            .withIgnoringCase(false)
    }
}
