//
//  File.swift
//  
//
//  Created by Michael O'Brien on 21/4/2023.
//

import Foundation

public extension IndexStore {

    /// Will return the source details for any  extension declarations/symbols within the store that extend the given source type.
    /// - Parameters:
    ///   - type: The source type being extended
    ///   - anchorStart: <#anchorStart description#>
    ///   - anchorEnd: <#anchorEnd description#>
    ///   - includeSubsequence: <#includeSubsequence description#>
    ///   - caseInsensitive: <#caseInsensitive description#>
    /// - Returns: Array of ``SourceDetails`` instances.
    func sourceDetails(
        forExtensionsOfType type: String,
        includeEmptyExtensions: Bool = false,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        caseInsensitive: Bool = false
    ) -> [SourceDetails] {
        let rawResults = workspace.findWorkspaceSymbols(
            matching: type,
            roles: [.definition],
            anchorStart: anchorStart,
            anchorEnd: anchorEnd,
            includeSubsequence: includeSubsequence,
            caseInsensitive: caseInsensitive
        )
        let conformingTypes: [SourceDetails] = rawResults.flatMap {
            /*
             Empty extensions will not resolve (which is ideal as it has no extended behavior), if it has declarations it will
             have the `.extendedBy`. Including `.reference` for safety.
             */
            let conforming = workspace.occurrences(ofUSR: $0.symbol.usr, roles: [.reference, .extendedBy])
            let validUsrs: [String] = conforming.flatMap {
                // If not valid reference role return empty results
                guard $0.roles.contains(.reference) else { return [String]() }
                let isEmptyExtension = $0.roles != [.reference, .extendedBy]
                // If not including empty extensions, and the reference is empty - return empty results
                if !includeEmptyExtensions, isEmptyExtension {
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
