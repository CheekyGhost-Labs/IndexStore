//
//  Workspace.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation
import IndexStoreDB
import Logging
import TSCBasic

/// Class abstracting `IndexStoreDB` functionality that serves `SymbolOccurrence` results.
///
/// Driven by an `IndexStoreDB` instance.
public final class Workspace {

    // MARK: - Properties

    /// The path to the libIndexStor dlyib.
    public let libIndexStorePath: String

    /// The root project directory.
    public let projectDirectory: String

    /// The path to the raw index store data.
    public let indexStorePath: String

    /// The path to put the index database.
    public let indexDatabasePath: String

    /// The source code index (if loaded)
    private(set) public var index: IndexStoreDB?

    /// Bool whether to exclude any system symbols from results.
    ///
    /// i.e: `Equatable` is a system symbol and would be excluded from any results.
    public let excludeSystemResults: Bool

    /// Logger instance for any debug or console output.
    public let logger: Logger

    // MARK: - Lifecycle

    /// Will create a new instance and attempt to load an index store using the given values.
    /// - Parameters:
    ///   - libIndexStorePath: The path to the libIndexStor dlyib.
    ///   - projectDirectory: The root project directory.
    ///   - indexStorePath: The path to the raw index store data.
    ///   - indexDatabasePath: The path to put the index database.
    ///   - logger: `Logger` instance for any debug or console output.
    public init(
        libIndexStorePath: String,
        projectDirectory: String,
        indexStorePath: String,
        indexDatabasePath: String,
        excludeSystemResults: Bool,
        logger: Logger
    ) {
        self.libIndexStorePath = libIndexStorePath
        self.projectDirectory = projectDirectory
        self.indexStorePath = indexStorePath
        self.indexDatabasePath = indexDatabasePath
        self.excludeSystemResults = excludeSystemResults
        self.logger = logger
        try? loadIndexStore()
    }

    /// Will create a new instance and attempt to load an index store using the values from the given configuration.
    /// - Parameters:
    ///   - configuration: The configuration instance holding any path values.
    ///   - logger: `Logger` instance for any debug or console output.
    public init(configuration: Configuration, logger: Logger) {
        // Assign overrides
        self.projectDirectory = configuration.projectDirectory
        self.indexStorePath = configuration.indexStorePath
        self.indexDatabasePath = configuration.indexDatabasePath
        self.libIndexStorePath = configuration.libIndexStorePath
        self.excludeSystemResults = configuration.excludeSystemResults
        self.logger = logger
        // Create index store instance
        try? loadIndexStore()
    }

    // MARK: - Helpers: IndexStore

    /// Will attempt to load the index store based on the current path settings.
    ///
    /// **Note: ** If an `index` instance is assigned it will be replaced.
    public func loadIndexStore() throws {
        index = nil
        let lib = try IndexStoreLibrary(dylibPath: libIndexStorePath)
        let storePath = URL(fileURLWithPath: indexStorePath).path
        let databasePath = URL(fileURLWithPath: indexDatabasePath).path
        do {
            index = try IndexStoreDB(storePath: storePath, databasePath: databasePath, library: lib, listenToUnitEvents: true)
            index?.pollForUnitChangesAndWait(isInitialScan: true)
            logger.info("Opened IndexStoreDB at \(indexDatabasePath) with store path \(indexStorePath)")
        } catch {
            logger.error("Failed to open IndexStoreDB: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Helpers: Public

    /// Will search for any symbols matching the given search text.
    /// - Parameters:
    ///   - matching: The search term. An empty string will return no results.
    ///   - roles: `SymbolRole` set types to restrict results to.
    ///   - anchorStart: Bool wether to anchor the search term to the starting bounds of a word or line Default is `true`.
    ///   - anchorEnd: Bool wether to anchor the search term to the end bounds of a word or line. Default is `true`.
    ///   - includeSubsequence: Bool whether to include symbol names that contain the term as a substring. Default is `false`.
    ///   - caseInsensitive: Bool whether to perform a case insensitive search. Default is `false`.
    /// - Returns: Set of `SymbolOccurrence` instances.
    public func findWorkspaceSymbols(
        matching: String,
        roles: SymbolRole = .all,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        caseInsensitive: Bool = false
    ) -> OrderedSet<SymbolOccurrence> {
        guard let index = index else { return [] }
        // let projectDirectory = workspace.projectDirectory - can restrict if need be
        let excludeSystem = excludeSystemResults
        var symbolOccurrenceResults: OrderedSet<SymbolOccurrence> = []
        index.forEachCanonicalSymbolOccurrence(
            containing: matching,
            anchorStart: true,
            anchorEnd: true,
            subsequence: false,
            ignoreCase: caseInsensitive
        ) {
            // Forced role check for declaration symbols that are not accessor relations
            let isValidRole = !$0.roles.contains(.accessorOf) && $0.roles.contains(.definition)
            if !$0.location.isSystem || !excludeSystem, isValidRole, roles.contains($0.roles) {
                symbolOccurrenceResults.append($0)
            }
            return true
        }
        return symbolOccurrenceResults
    }

    /// Will return all symbols from within the source files at the given paths.
    ///
    /// **Note:** You can restrict results to a `SymbolRole` type. Default is `.declaration`.
    /// - Parameters:
    ///   - path: Array of absolute paths to the soure files to search in.
    ///   - kinds: Array of `IndexSymbolKind` cases to restrict results to.
    ///   - roles: The roles to restrict symbol results to. Default is `.declaration`.
    /// - Returns: Array of `SymbolOccurrence` instances.
    public func symbolsInSourceFiles(
        at paths: [String],
        kinds: [IndexSymbolKind],
        roles: SymbolRole = .declaration
    ) -> OrderedSet<SymbolOccurrence> {
        guard index != nil else { return [] }
        var results: OrderedSet<SymbolOccurrence> = []
        paths.forEach {
            let occurences = symbolsInSourceFile(at: $0, kinds: kinds, roles: roles)
            occurences.forEach { results.append($0) }
        }
        return results
    }

    /// Will return all symbols from within the source at the given path.
    ///
    /// **Note:** You can restrict results to a `SymbolRole` type. Default is `.declaration`.
    /// - Parameters:
    ///   - path: The absolute path to the soure file to search in.
    ///   - kinds: Array of `IndexSymbolKind` cases to restrict results to.
    ///   - roles: The roles to restrict symbol results to. Default is `.declaration`.
    /// - Returns: Array of `SymbolOccurrence` instances.
    public func symbolsInSourceFile(
        at path: String,
        kinds: [IndexSymbolKind],
        roles: SymbolRole = .declaration
    ) -> OrderedSet<SymbolOccurrence> {
        guard let index = index else { return [] }
        let excludeSystem = excludeSystemResults
        let symbols = index.symbols(inFilePath: path)
        var results: OrderedSet<SymbolOccurrence> = []
        symbols.forEach {
            index.forEachSymbolOccurrence(byUSR: $0.usr, roles: roles) { occurence in
                if !occurence.location.isSystem || !excludeSystem, occurence.roles.contains(.definition) {
                    if kinds.contains(occurence.symbol.kind) {
                        results.append(occurence)
                    }
                }
                return true
            }
        }
        return results
    }

    /// Will return any symbol occurences of the given USR identifier.
    ///
    /// - Parameters:
    ///   - usr: The usr of the source symbol to search for.
    ///   - roles: The roles to restrict symbol results to.
    /// - Returns: Array of `SymbolOccurrence` instances.
    public func occurrences(ofUSR usr: String, roles: SymbolRole) -> OrderedSet<SymbolOccurrence> {
        guard let index = index else { return [] }
        let results = index.occurrences(ofUSR: usr, roles: roles)
        return OrderedSet<SymbolOccurrence>(results)
    }

    /// Will return any symbol occurences that are related to the given USR identifier.
    ///
    /// - Parameters:
    ///   - usr: The usr of the source symbol to search for relations to.
    ///   - roles: The roles to restrict symbol results to.
    /// - Returns: Array of `SymbolOccurrence` instances.
    public func occurrences(relatedToUSR usr: String, roles: SymbolRole) -> OrderedSet<SymbolOccurrence> {
        guard let index = index else { return [] }
        let results = index.occurrences(relatedToUSR: usr, roles: roles)
        return OrderedSet<SymbolOccurrence>(results)
    }
}
