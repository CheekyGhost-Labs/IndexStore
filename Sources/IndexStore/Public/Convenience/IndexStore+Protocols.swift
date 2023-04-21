//
//  IndexStore+Protocols.swift
//  
//
//  Created by Michael O'Brien on 21/4/2023.
//

import Foundation

extension IndexStore {

    /// Will return source details  for any declarations/symbols within the store that conform to the given protocol.
    /// - Parameter protocolName: The protocol to search for.
    /// - Returns: Array of ``SourceDetails``
    public func sourceDetails(conformingToProtocol protocolName: String) -> [SourceDetails] {
        let rawResults = workspace.findWorkspaceSymbols(matching: protocolName).filter { $0.symbol.kind == .protocol }
        let conformingTypes: [SourceDetails] = rawResults.flatMap {
            let conforming = workspace.occurrences(ofUSR: $0.symbol.usr, roles: [.reference, .baseOf])
            let validUsrs: [String] = conforming.flatMap {
                guard $0.roles == [.reference, .baseOf] else {
                    return [String]()
                }
                return $0.relations.map(\.symbol.usr)
            }
            let occurances = validUsrs.flatMap {
                return workspace.occurrences(ofUSR: $0, roles: [.definition])
            }
            return occurances.compactMap(sourceDetailsFromOccurence)
        }
        return conformingTypes
    }
}
