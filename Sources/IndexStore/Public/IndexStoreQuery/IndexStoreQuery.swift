//
//  IndexStoreQuery.swift
//
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import IndexStoreDB

/// Struct representing a query to give to an `IndexStore` instance to search for source symbols.
public struct IndexStoreQuery: Equatable {
    // MARK: - Properties

    /// The type or name query to search for.
    public var query: String?

    /// Optional array of source files to restrict searching to.
    public var sourceFiles: [String]?

    /// `SourceKind` set types to restrict results to. Default is `.allCasses`.
    public var kinds: [SourceKind] = SourceKind.allCases

    /// `SourceRole` set types to restrict results to. Default is `.all`.
    public var roles: SourceRole = .all

    /// Bool whether to restrict search results to symbols with a location within the project directory. Default is `true`.
    public var restrictToProjectDirectory: Bool = true

    /// Bool whether to anchor the search term to the starting bounds of a word or line Default is `true`.
    public var anchorStart: Bool = true

    /// Bool whether to anchor the search term to the ending bounds of a word or line Default is `true`.
    public var anchorEnd: Bool = true

    /// Bool whether to include symbol names that contain the term as a substring. Default is `false`.
    public var includeSubsequence: Bool = false

    /// Bool whether to perform a case insensitive search. Default is `false`.
    public var ignoreCase: Bool = false

    // MARK: - Lifecycle

    public init() {}

    public init(query: String) {
        self.query = query
    }

    public init(sourceFiles: [String]) {
        self.sourceFiles = sourceFiles
    }

    // MARK: - Builder

    public func withQuery(_ query: String?) -> IndexStoreQuery {
        var result = self
        result.query = query
        return result
    }

    public func withSourceFiles(_ files: [String]?) -> IndexStoreQuery {
        var result = self
        result.sourceFiles = files
        return result
    }

    public func withKinds(_ kinds: [SourceKind]) -> IndexStoreQuery {
        var result = self
        result.kinds = kinds
        return result
    }

    public func withRoles(_ roles: SourceRole) -> IndexStoreQuery {
        var result = self
        result.roles = roles
        return result
    }

    public func withRestrictingToProjectDirectory(_ flag: Bool) -> IndexStoreQuery {
        var result = self
        result.restrictToProjectDirectory = flag
        return result
    }

    public func withAnchorStart(_ anchorStart: Bool) -> IndexStoreQuery {
        var result = self
        result.anchorStart = anchorStart
        return result
    }

    public func withAnchorEnd(_ anchorEnd: Bool) -> IndexStoreQuery {
        var result = self
        result.anchorEnd = anchorEnd
        return result
    }

    public func withInlcudeSubsequences(_ include: Bool) -> IndexStoreQuery {
        var result = self
        result.includeSubsequence = include
        return result
    }

    public func withIgnoringCase(_ ignoreCase: Bool) -> IndexStoreQuery {
        var result = self
        result.ignoreCase = ignoreCase
        return result
    }
}
