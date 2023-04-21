//
//  IndexStore+Symbols.swift
//  
//
//  Created by Michael O'Brien on 21/4/2023.
//

import Foundation
import IndexStoreDB

extension IndexStore {

    /// Will return source details for any declarations/symbols matching the given type and whose declaration kind is contained in the given array.
    /// - Parameters:
    ///   - type: The type to search for.
    ///   - kinds: Array of ``SourceKind`` types to restrict results to.
    ///   - anchorStart: Bool wether to anchor the search term to the starting bounds of a word or line Default is `true`.
    ///   - anchorEnd: Bool wether to anchor the search term to the end bounds of a word or line. Default is `true`.
    ///   - includeSubsequence: Bool whether to include symbol names that contain the term as a substring. Default is `false`.
    ///   - caseInsensitive: Bool whether to perform a case insensitive search. Default is `false`.
    /// - Returns: `Array` of ``SourceDetails`` objects.
    public func sourceDetails(
        forSourceMatchingType type: String,
        kinds: [SourceKind] = SourceKind.allCases,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        caseInsensitive: Bool = false
    ) -> [SourceDetails] {
        sourceDetails(
            matchingType: type,
            kinds: kinds,
            roles: [.definition],
            anchorStart: anchorStart,
            anchorEnd: anchorEnd,
            includeSubsequence: includeSubsequence,
            caseInsensitive: caseInsensitive
        )
    }

    /// Will return source details  for any declarations/symbols within the store that match the given source kinds and roles.
    ///
    /// **Note: ** This method iteratest through **all** source files in the project. It can be expensive if you
    /// have a vast source file count. Filtering for source kinds is also done while iterating.
    /// - Parameters:
    ///   - kinds: The source kinds to search for.
    ///   - roles: The roles any symbols must match.
    /// - Returns: Array of ``SourceDetails`` instances.
    public func sourceDetails(forSourceKinds kinds: [SourceKind], roles: SourceRole) -> [SourceDetails] {
        let sourceFiles = swiftSourceFiles()
        let symbolRoles = SymbolRole(rawValue: roles.rawValue)
        let occurences = workspace.symbolsInSourceFiles(at: sourceFiles, roles: [.definition])
        var results: [SourceDetails] = []
        mapOccurencesToResults(occurences, into: &results)
        return resultsFilteredByKind(results: results, kinds: kinds)
    }
}
