//
//  IndexStore+Symbols.swift
//  
//
//  Created by Michael O'Brien on 21/4/2023.
//

import Foundation
import IndexStoreDB

extension IndexStore {

    /// Will return source symbols for any declarations/symbols matching the given type and whose declaration kind is contained in the given array.
    /// - Parameters:
    ///   - type: The type to search for.
    ///   - kinds: Array of ``SourceKind`` types to restrict results to.
    ///   - anchorStart: Bool wether to anchor the search term to the starting bounds of a word or line Default is `true`.
    ///   - anchorEnd: Bool wether to anchor the search term to the end bounds of a word or line. Default is `true`.
    ///   - includeSubsequence: Bool whether to include symbol names that contain the term as a substring. Default is `false`.
    ///   - caseInsensitive: Bool whether to perform a case insensitive search. Default is `false`.
    /// - Returns: `Array` of ``SourceSymbol`` objects.
    public func sourceSymbols(
        forSourceMatchingType type: String,
        kinds: [SourceKind] = SourceKind.allCases,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        caseInsensitive: Bool = false
    ) -> [SourceSymbol] {
        queryIndexStoreSymbols(
            matchingType: type,
            kinds: kinds,
            roles: [.definition],
            anchorStart: anchorStart,
            anchorEnd: anchorEnd,
            includeSubsequence: includeSubsequence,
            caseInsensitive: caseInsensitive
        )
    }

    /// Will return source symbols for any declarations/symbols within the store that match the given source kinds and roles.
    ///
    /// **Note: ** This method iteratest through **all** source files in the project. It can be **very time expensive** if you
    /// have a vast source file count. Filtering for source kinds is also done while iterating.
    /// - Parameters:
    ///   - kinds: The source kinds to search for.
    ///   - roles: The roles any symbols must match.
    /// - Returns: Array of ``SourceSymbol`` instances.
    public func sourceSymbols(forSourceKinds kinds: [SourceKind]) -> [SourceSymbol] {
        let sourceFiles = swiftSourceFiles()
        return sourceDetails(inSourceFiles: sourceFiles, kinds: kinds)
    }

    /// Will return source symbols for any declarations/symbols within the contents of the source at the given file paths.
    /// - Parameters:
    ///   - filePaths: Array of source file paths to search in.
    ///   - kinds: The source kinds to filter results with.
    /// - Returns: Array of ``SourceSymbol``
    public func sourceSymbols(inSourceFiles filePaths: [String], kinds: [SourceKind]) -> [SourceSymbol] {
        let rawResults = workspace.symbolsInSourceFiles(at: filePaths, roles: [.definition])
        var results: [SourceSymbol] = rawResults.compactMap(sourceDetailsFromOccurence)
        // Extensions have to be resolved via USR name
        guard kinds.contains(.extension) else {
            logger.debug("`.extensions` kind not included - skipping extensions lookup")
            return resultsFilteredByKind(results: results, kinds: kinds)
        }
        logger.debug("`.extensions` kind included - performing USR extension lookup")
        let usrs = results.map(\.usr)
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
        return resultsFilteredByKind(results: results, kinds: kinds)
    }
}
