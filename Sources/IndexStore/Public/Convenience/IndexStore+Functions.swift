//
//  IndexStore+Functions.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation

public extension IndexStore {

    /// Will return the source details for any function declarations/symbols within the store that match the given query.
    ///
    /// **Note: ** The ``SourceKind`` for a function is ``SourceKind/instanceMethod``
    /// - Parameters:
    ///   - type: The type name to search for.
    ///   - anchorStart: Bool wether to anchor the search term to the starting bounds of a word or line Default is `true`.
    ///   - anchorEnd: Bool wether to anchor the search term to the end bounds of a word or line. Default is `true`.
    ///   - includeSubsequence: Bool whether to include symbol names that contain the term as a substring. Default is `false`.
    ///   - caseInsensitive: Bool whether to perform a case insensitive search. Default is `false`.
    /// - Returns: Array of ``SourceDetails`` instances
    func sourceDetails(forFunctionsMatching query: String, caseInsensitive: Bool = false) -> [SourceDetails] {
        queryIndexStoreSymbols(
            matchingType: query,
            kinds: [.instanceMethod],
            roles: [.definition, .canonical],
            anchorStart: false,
            anchorEnd: false,
            includeSubsequence: true,
            caseInsensitive: caseInsensitive
        )
    }

    /// Will return the source details for any function declarations/symbols within the given source files.
    ///
    /// **Note: ** The source files must be in within the index or no results for that source file will be returned.
    /// - Parameter filePaths: Array of source file paths to search in.
    /// - Returns: Array of ``SourceDetails`` instances.
    func sourceDetails(forFunctionsInSourceFiles filePaths: [String]) -> [SourceDetails] {
        let sourceFiles = swiftSourceFiles()
        let rawResults = workspace.symbolsInSourceFiles(at: sourceFiles, roles: [.definition, .canonical]).filter {
            $0.symbol.kind == .instanceMethod
        }
        let results = rawResults.compactMap(sourceDetailsFromOccurence)
        return results
    }

    /// Will return the source details for any function declarations/symbols within the store.
    ///
    /// **Note: ** This method iteratest through **all** source files in the project. It can be **very time expensive** if you
    /// have a vast source file count. Filtering for source kinds is also done while iterating.
    /// - Returns: Array of ``SourceDetails`` instances
    func sourceDetailsForFunctions() -> [SourceDetails] {
        let sourceFiles = swiftSourceFiles()
        return sourceDetails(forFunctionsInSourceFiles: sourceFiles)
    }
}
