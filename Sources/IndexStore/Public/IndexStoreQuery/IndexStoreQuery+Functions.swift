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
    /// - kinds: `[.instanceMethod]`
    /// - roles: `[.definition, .canonical]]`
    /// - anchorStart: `false`
    /// - anchorEnd: `false`
    /// - includeSubsequence: `true`
    /// - ignoreCase: `false`
    /// - Parameter query: The type name to search for.
    /// - Returns: ``IndexStoreQuery``
    static func functions(_ query: String) -> IndexStoreQuery {
        IndexStoreQuery(query: query)
            .withKinds([.instanceMethod])
            .withRoles([.definition, .canonical])
            .withAnchorStart(false)
            .withAnchorEnd(false)
            .withInlcudeSubsequences(true)
            .withIgnoringCase(false)
    }
}
