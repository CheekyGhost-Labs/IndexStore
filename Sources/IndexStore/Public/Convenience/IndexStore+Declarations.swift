//
//  IndexStore+Declarations.swift
//  
//
//  Created by Michael O'Brien on 21/4/2023.
//

import Foundation

public extension IndexStore {

    // MARK: - All Declarations

    /// Will return any declaration symbols matching the given type query that match the `.protocol`, `.class`, `.enum`, `.struct`, or `.typealias` source kinds.
    ///
    /// - Parameters:
    ///   - query: The type name to search for.
    ///   - anchorStart: Bool wether to anchor the search term to the starting bounds of a word or line Default is `true`.
    ///   - anchorEnd: Bool wether to anchor the search term to the end bounds of a word or line. Default is `true`.
    ///   - includeSubsequence: Bool whether to include symbol names that contain the term as a substring. Default is `false`.
    ///   - caseInsensitive: Bool whether to perform a case insensitive search. Default is `false`.
    /// - Returns: Array of ``SourceDetails`` instances
    func sourceDetails(
        forDeclarationsMatching query: String,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        caseInsensitive: Bool = false
    ) -> [SourceDetails] {
        queryIndexStoreSymbols(
            matchingType: query,
            kinds: [.protocol, .class, .enum, .struct, .typealias],
            roles: [.definition],
            anchorStart: anchorStart,
            anchorEnd: anchorEnd,
            includeSubsequence: includeSubsequence,
            caseInsensitive: caseInsensitive
        )
    }

    // MARK: - Declaration Specifics

    /// Will return any `class` declaration symbols matching the given type query.
    ///
    /// - Parameters:
    ///   - query: The type name to search for.
    ///   - anchorStart: Bool wether to anchor the search term to the starting bounds of a word or line Default is `true`.
    ///   - anchorEnd: Bool wether to anchor the search term to the end bounds of a word or line. Default is `true`.
    ///   - includeSubsequence: Bool whether to include symbol names that contain the term as a substring. Default is `false`.
    ///   - caseInsensitive: Bool whether to perform a case insensitive search. Default is `false`.
    /// - Returns: Array of ``SourceDetails`` instances
    func sourceDetails(
        forClassesMatching query: String,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        caseInsensitive: Bool = false
    ) -> [SourceDetails] {
        queryIndexStoreSymbols(
            matchingType: query,
            kinds: [.class],
            roles: [.definition],
            anchorStart: anchorStart,
            anchorEnd: anchorEnd,
            includeSubsequence: includeSubsequence,
            caseInsensitive: caseInsensitive
        )
    }

    /// Will return any `protocol` declaration symbols matching the given type query.
    ///
    /// - Parameters:
    ///   - query: The type name to search for.
    ///   - anchorStart: Bool wether to anchor the search term to the starting bounds of a word or line Default is `true`.
    ///   - anchorEnd: Bool wether to anchor the search term to the end bounds of a word or line. Default is `true`.
    ///   - includeSubsequence: Bool whether to include symbol names that contain the term as a substring. Default is `false`.
    ///   - caseInsensitive: Bool whether to perform a case insensitive search. Default is `false`.
    /// - Returns: Array of ``SourceDetails`` instances
    func sourceDetails(
        forProtocolsMatching query: String,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        caseInsensitive: Bool = false
    ) -> [SourceDetails] {
        queryIndexStoreSymbols(
            matchingType: query,
            kinds: [.protocol],
            roles: [.definition],
            anchorStart: anchorStart,
            anchorEnd: anchorEnd,
            includeSubsequence: includeSubsequence,
            caseInsensitive: caseInsensitive
        )
    }

    /// Will return any `struct` declaration symbols matching the given type query.
    ///
    /// - Parameters:
    ///   - query: The type name to search for.
    ///   - anchorStart: Bool wether to anchor the search term to the starting bounds of a word or line Default is `true`.
    ///   - anchorEnd: Bool wether to anchor the search term to the end bounds of a word or line. Default is `true`.
    ///   - includeSubsequence: Bool whether to include symbol names that contain the term as a substring. Default is `false`.
    ///   - caseInsensitive: Bool whether to perform a case insensitive search. Default is `false`.
    /// - Returns: Array of ``SourceDetails`` instances
    func sourceDetails(
        forStructsMatching query: String,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        caseInsensitive: Bool = false
    ) -> [SourceDetails] {
        queryIndexStoreSymbols(
            matchingType: query,
            kinds: [.struct],
            roles: [.definition],
            anchorStart: anchorStart,
            anchorEnd: anchorEnd,
            includeSubsequence: includeSubsequence,
            caseInsensitive: caseInsensitive
        )
    }

    /// Will return any `enum` declaration symbols matching the given type query.
    ///
    /// - Parameters:
    ///   - query: The type name to search for.
    ///   - anchorStart: Bool wether to anchor the search term to the starting bounds of a word or line Default is `true`.
    ///   - anchorEnd: Bool wether to anchor the search term to the end bounds of a word or line. Default is `true`.
    ///   - includeSubsequence: Bool whether to include symbol names that contain the term as a substring. Default is `false`.
    ///   - caseInsensitive: Bool whether to perform a case insensitive search. Default is `false`.
    /// - Returns: Array of ``SourceDetails`` instances
    func sourceDetails(
        forEnumerationsMatching query: String,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        caseInsensitive: Bool = false
    ) -> [SourceDetails] {
        queryIndexStoreSymbols(
            matchingType: query,
            kinds: [.enum],
            roles: [.definition],
            anchorStart: anchorStart,
            anchorEnd: anchorEnd,
            includeSubsequence: includeSubsequence,
            caseInsensitive: caseInsensitive
        )
    }

    /// Will return any `typealias` declaration symbols matching the given type query.
    ///
    /// - Parameters:
    ///   - query: The type name to search for.
    ///   - anchorStart: Bool wether to anchor the search term to the starting bounds of a word or line Default is `true`.
    ///   - anchorEnd: Bool wether to anchor the search term to the end bounds of a word or line. Default is `true`.
    ///   - includeSubsequence: Bool whether to include symbol names that contain the term as a substring. Default is `false`.
    ///   - caseInsensitive: Bool whether to perform a case insensitive search. Default is `false`.
    /// - Returns: Array of ``SourceDetails`` instances
    func sourceDetails(
        forTypealiasesMatching query: String,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        caseInsensitive: Bool = false
    ) -> [SourceDetails] {
        queryIndexStoreSymbols(
            matchingType: query,
            kinds: [.typealias],
            roles: [.definition],
            anchorStart: anchorStart,
            anchorEnd: anchorEnd,
            includeSubsequence: includeSubsequence,
            caseInsensitive: caseInsensitive
        )
    }
}
