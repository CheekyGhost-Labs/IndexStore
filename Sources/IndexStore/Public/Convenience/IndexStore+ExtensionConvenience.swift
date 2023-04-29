//
//  IndexStore+Convenience.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Foundation
import IndexStoreDB
import TSCBasic

extension IndexStore {

    // MARK: - Convenience: Extensions

    /// Will return any source symbols for any **empty** extensions on types matching the given query.
    ///
    /// **Note: ** The provided query will have the `kinds` and `roles` modified to enable the search.
    /// - Parameter query: The query to search with.
    /// - Returns: Array of ``SourceSymbol`` instances
    public func sourceSymbols(forEmptyExtensionsMatching query: IndexStoreQuery) -> [SourceSymbol] {
        let symbols = querySymbols(query)
        var results: [SourceSymbol] = []
        symbols.forEach {
            let references = workspace.occurrences(ofUSR: $0.usr, roles: [.reference])
            references.forEach { reference in
                guard reference.roles.contains([.reference]) && reference.relations.isEmpty else { return }
                var details = sourceSymbolFromOccurence(reference)
                details.sourceKind = .`extension`
                results.append(details)
            }
        }
        return results
    }
}
