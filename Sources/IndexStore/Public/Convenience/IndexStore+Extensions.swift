//
//  File.swift
//  
//
//  Created by Michael O'Brien on 21/4/2023.
//

import Foundation
import IndexStoreDB

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
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        caseInsensitive: Bool = false
    ) -> [SourceDetails] {
        sourceDetails(
            matchingType: type,
            kinds: [.extension],
            roles: [.definition],
            anchorStart: anchorStart,
            anchorEnd: anchorEnd,
            includeSubsequence: includeSubsequence,
            caseInsensitive: caseInsensitive
        )
    }

    func sourceDetailsForExtensions() -> [SourceDetails] {
        let sourceFiles = swiftSourceFiles()
        let rawResults = workspace.symbolsInSourceFiles(at: sourceFiles, roles: [.definition])
        let usrs = rawResults.map(\.symbol.usr)
        var results: [SourceDetails] = []
        usrs.forEach {
            let references = workspace.occurrences(ofUSR: $0, roles: [.reference])
            let relations: [SymbolRelation] = references.flatMap(\.relations)
            // For each valid relation usr - resolve the symbol and transform into SourceDetail
            relations.forEach { relation in
                /*
                 Empty extensions will not resolve (which is ideal as it has no extended behavior), if it has declarations it will
                 have the `.extendedBy`. Including `.definition` for safety.
                 */
                let symbols = workspace.occurrences(ofUSR: relation.symbol.usr, roles: [.definition, .reference, .extendedBy])
                let transformed = symbols.compactMap(sourceDetailsFromOccurence)
                // Append valid symbols to the result set
                results.append(contentsOf: transformed)
            }
        }
        return results
    }

    func sourceDetails(
        forEmptyExtensionsOfType type: String,
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
        var results: [SourceDetails] = []
        let usrs = rawResults.map(\.symbol.usr)
        usrs.forEach {
            let references = workspace.occurrences(ofUSR: $0, roles: [.reference])
            references.forEach {
                guard $0.roles.contains([.reference]) && $0.relations.isEmpty else { return }
                var details = sourceDetailsFromOccurence($0)
                details.sourceKind = .`extension`
                results.append(details)
            }
        }
        return results
    }

    func sourceDetailsForEmptyExtensions() -> [SourceDetails] {
        let sourceFiles = swiftSourceFiles()
        let rawResults = workspace.symbolsInSourceFiles(at: sourceFiles, roles: [.definition])
        var results: [SourceDetails] = []
        let usrs = rawResults.map(\.symbol.usr)
        usrs.forEach {
            let references = workspace.occurrences(ofUSR: $0, roles: [.reference])
            references.forEach {
                guard $0.roles.contains([.reference]) && $0.relations.isEmpty else { return }
                var details = sourceDetailsFromOccurence($0)
                details.sourceKind = .`extension`
                results.append(details)
            }
        }
        return results
    }
}
