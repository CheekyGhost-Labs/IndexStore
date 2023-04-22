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
    ///
    /// - Parameters:
    ///   - type: The type name to search for.
    ///   - anchorStart: Bool wether to anchor the search term to the starting bounds of a word or line Default is `true`.
    ///   - anchorEnd: Bool wether to anchor the search term to the end bounds of a word or line. Default is `true`.
    ///   - includeSubsequence: Bool whether to include symbol names that contain the term as a substring. Default is `false`.
    ///   - caseInsensitive: Bool whether to perform a case insensitive search. Default is `false`.
    /// - Returns: Array of ``SourceDetails`` instances
    func sourceDetails(
        forExtensionsOfType type: String,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        caseInsensitive: Bool = false
    ) -> [SourceDetails] {
        queryIndexStoreSymbols(
            matchingType: type,
            kinds: [.extension],
            roles: [.definition],
            anchorStart: anchorStart,
            anchorEnd: anchorEnd,
            includeSubsequence: includeSubsequence,
            caseInsensitive: caseInsensitive
        )
    }

    /// Will return the source details for any  empty extensions on  types matching  given query.
    ///
    /// **Note:** Empty extensions do not have a unique `usr`. The location and lines etc will be accurate,
    /// however, the ``SourceDetails/usr`` property will reference the parent symbol.
    /// - Parameters:
    ///   - type: The type name to search for.
    ///   - anchorStart: Bool wether to anchor the search term to the starting bounds of a word or line Default is `true`.
    ///   - anchorEnd: Bool wether to anchor the search term to the end bounds of a word or line. Default is `true`.
    ///   - includeSubsequence: Bool whether to include symbol names that contain the term as a substring. Default is `false`.
    ///   - caseInsensitive: Bool whether to perform a case insensitive search. Default is `false`.
    /// - Returns: Array of ``SourceDetails`` instances
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

    /// Will return the source details for any extensions of types.
    ///
    /// - Returns: Array of ``SourceDetails`` instances
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

    /// Will return the source details for any empty extensions of types.
    ///
    /// - Returns: Array of ``SourceDetails`` instances
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
