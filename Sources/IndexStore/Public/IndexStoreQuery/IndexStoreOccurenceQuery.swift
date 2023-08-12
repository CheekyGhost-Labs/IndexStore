//
//  IndexStoreQuery.swift
//
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import IndexStoreDB

/// Struct representing a query to give to an `IndexStore` instance to search for occurrences, or related occurrences, of a source symbol USR.
public struct IndexStoreOccurenceQuery: Equatable {
    // MARK: - Properties

    /// The USR or to search for.
    public var usr: String

    /// Optional array of source files to restrict results to.
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

    public init(usr: String) {
        self.usr = usr
    }

    // MARK: - Builder

    public func withSourceFiles(_ files: [String]?) -> IndexStoreOccurenceQuery {
        var result = self
        result.sourceFiles = files
        return result
    }

    public func withKinds(_ kinds: [SourceKind]) -> IndexStoreOccurenceQuery {
        var result = self
        result.kinds = kinds
        return result
    }

    public func withRoles(_ roles: SourceRole) -> IndexStoreOccurenceQuery {
        var result = self
        result.roles = roles
        return result
    }

    public func withRestrictingToProjectDirectory(_ flag: Bool) -> IndexStoreOccurenceQuery {
        var result = self
        result.restrictToProjectDirectory = flag
        return result
    }

    public func withAnchorStart(_ anchorStart: Bool) -> IndexStoreOccurenceQuery {
        var result = self
        result.anchorStart = anchorStart
        return result
    }

    public func withAnchorEnd(_ anchorEnd: Bool) -> IndexStoreOccurenceQuery {
        var result = self
        result.anchorEnd = anchorEnd
        return result
    }

    public func withInlcudeSubsequences(_ include: Bool) -> IndexStoreOccurenceQuery {
        var result = self
        result.includeSubsequence = include
        return result
    }

    public func withIgnoringCase(_ ignoreCase: Bool) -> IndexStoreOccurenceQuery {
        var result = self
        result.ignoreCase = ignoreCase
        return result
    }
}
