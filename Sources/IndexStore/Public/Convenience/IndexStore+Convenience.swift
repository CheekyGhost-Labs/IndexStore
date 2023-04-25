//
//  File.swift
//  
//
//  Created by Michael O'Brien on 21/4/2023.
//

import Foundation
import IndexStoreDB

public extension IndexStore {

    /// Will return any source symbols for any **empty** extensions on types matching the given query.
    ///
    /// **Note: ** The provided query will have the `kinds` and `roles` modified to enable the search.
    /// - Parameter query: The query to search with.
    /// - Returns: Array of ``SourceSymbol`` instances
    func sourceSymbols(forEmptyExtensionsMatching query: IndexStoreQuery) -> [SourceSymbol] {
        let rawResults = querySymbols(query)
        var results: [SourceSymbol] = []
        let usrs = rawResults.map(\.usr)
        usrs.forEach {
            let references = workspace.occurrences(ofUSR: $0, roles: [.reference])
            references.forEach {
                guard $0.roles.contains([.reference]) && $0.relations.isEmpty else { return }
                var details = sourceSymbolFromOccurence($0)
                details.sourceKind = .`extension`
                results.append(details)
            }
        }
        return results
    }

    /// Will return source symbols  for any declarations/symbols within the store that conform to the given protocol.
    /// - Parameter protocolName: The name of the protocol to search for.
    /// - Returns: Array of ``SourceSymbol``
    public func sourceSymbols(conformingToProtocol protocolName: String) -> [SourceSymbol] {
        let query = IndexStoreQuery.protocolDeclarations(protocolName)
        let protocols = querySymbols(query)
        let conformingTypes: [SourceSymbol] = protocols.flatMap {
            let conforming = workspace.occurrences(ofUSR: $0.usr, roles: [.reference, .baseOf])
            let validUsrs: [String] = conforming.flatMap {
                guard $0.roles == [.reference, .baseOf] else {
                    return [String]()
                }
                return $0.relations.map(\.symbol.usr)
            }
            let occurances = validUsrs.flatMap {
                return workspace.occurrences(ofUSR: $0, roles: [.definition])
            }
            return occurances.compactMap(sourceSymbolFromOccurence)
        }
        return conformingTypes
    }

    func invocationsOfFunctionSymbol(_ occurence: SourceSymbol) -> [SourceSymbol] {
        var results: [SourceSymbol] = []
        let conforming = workspace.occurrences(ofUSR: occurence.usr, roles: [.call])
//        let validUsrs: [String] = conforming.flatMap {
//            guard $0.roles == [.reference, .baseOf] else {
//                return [String]()
//            }
//            return $0.relations.map(\.symbol.usr)
//        }
//        let occurances = validUsrs.flatMap {
//            return workspace.occurrences(ofUSR: $0, roles: [.definition])
//        }
//        return occurances.compactMap(sourceSymbolFromOccurence)
        return []
    }
}
