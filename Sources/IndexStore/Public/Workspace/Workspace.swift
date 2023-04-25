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
        logger: Logger
    ) {
        self.libIndexStorePath = libIndexStorePath
        self.projectDirectory = projectDirectory
        self.indexStorePath = indexStorePath
        self.indexDatabasePath = indexDatabasePath
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

    public func querySymbols(
        matching: String,
        kinds: [IndexSymbolKind],
        roles: SymbolRole = .all,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        ignoreCase: Bool = false,
        restrictToLocation directory: String?
    ) -> OrderedSet<SymbolOccurrence> {
        guard let index = index else { return [] }
        let targetDirectory = directory ?? ""
        logger.debug("-- Searching for symbol occurances with type `\(matching)`: roles `\(roles)`")
        var symbolOccurrenceResults: OrderedSet<SymbolOccurrence> = []
        index.forEachCanonicalSymbolOccurrence(
            containing: matching,
            anchorStart: anchorStart,
            anchorEnd: anchorEnd,
            subsequence: includeSubsequence,
            ignoreCase: ignoreCase
        ) { [self] in
            if validateRoles($0, roles: roles, canIgnore: false),
                validateProjectDirectory($0, projectDirectory: targetDirectory, canIgnore: directory == nil) {
                symbolOccurrenceResults.append($0)
            }
            return true
        }
        let filtered = symbolOccurrenceResults.filter {
            kinds == [.extension] || kinds.contains($0.symbol.kind)
        }
        // Extensions have to be resolved via USR name
        guard kinds.contains(.extension) else {
            logger.debug("`.extensions` kind not included - skipping extensions lookup")
            return OrderedSet<SymbolOccurrence>(filtered)
        }
        // If just looking for extensions can keep an empty result set to only populate extensions, otherwise include filtered results.
        var results: OrderedSet<SymbolOccurrence> = []
        if kinds != [.extension] {
            results = OrderedSet<SymbolOccurrence>(filtered)
        }
        logger.debug("`.extensions` kind included - performing USR extension lookup")
        let extensions = resolveExtensionsOnOccurrences(symbolOccurrenceResults, kinds: kinds, roles: roles, restrictToLocation: directory)
        extensions.forEach { results.append($0) }
        logger.debug("-- `\(results.count)` results")
        return results
    }

    public func querySymbols(
        inSourceFiles sourceFiles: [String],
        matching: String?,
        kinds: [IndexSymbolKind],
        roles: SymbolRole = .all,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        ignoreCase: Bool = false,
        restrictToLocation directory: String?
    ) -> OrderedSet<SymbolOccurrence> {
        guard !sourceFiles.isEmpty else {
            logger.warning("sourceFiles is empty. Returning empty results")
            return []
        }
        let targetDirectory = directory ?? ""
        let rawResults = symbolsInSourceFiles(at: sourceFiles, roles: roles)
        var filtered: [SymbolOccurrence] = []
        // Filter Results
        rawResults.forEach {
            guard
                validateRoles($0, roles: roles, canIgnore: false),
                validateProjectDirectory($0, projectDirectory: targetDirectory, canIgnore: directory == nil)
            else {
                return
            }
            // Kind match
            guard kinds == [.extension] || kinds.contains($0.symbol.kind) else { return }
            // Name match (if present)
            var shouldInclude: Bool = true
            if let matching, !matching.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                shouldInclude = validateName(
                    $0,
                    term: matching,
                    anchorStart: anchorStart,
                    anchorEnd: anchorEnd,
                    includeSubsequence: includeSubsequence,
                    ignoreCase: ignoreCase
                )
            }
            if shouldInclude { filtered.append($0) }
        }
        // Extensions have to be resolved via USR name
        guard kinds.contains(.extension) else {
            logger.debug("`.extensions` kind not included - skipping extensions lookup")
            return OrderedSet<SymbolOccurrence>(filtered)
        }
        // If just looking for extensions can keep an empty result set to only populate extensions, otherwise include filtered results.
        var results: OrderedSet<SymbolOccurrence> = []
        if kinds != [.extension] {
            results = OrderedSet<SymbolOccurrence>(filtered)
        }
        logger.debug("`.extensions` kind included - performing USR extension lookup")
        let extensions = resolveExtensionsOnOccurrences(rawResults, kinds: kinds, roles: roles, restrictToLocation: directory)
        extensions.forEach { results.append($0) }
        logger.debug("-- `\(results.count)` results")
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

    // MARK: - Helpers: Source file resolving

    /// Will return all symbols from within the source files at the given paths.
    ///
    /// **Note:** You can restrict results to a `SymbolRole` type. Default is `.declaration`.
    /// - Parameters:
    ///   - path: Array of absolute paths to the soure files to search in.
    ///   - kinds: Array of `IndexSymbolKind` cases to restrict results to.
    ///   - roles: The roles to restrict symbol results to. Default is `.declaration`.
    /// - Returns: Array of `SymbolOccurrence` instances.
    func symbolsInSourceFiles(at paths: [String], roles: SymbolRole = .declaration) -> OrderedSet<SymbolOccurrence> {
        guard index != nil else { return [] }
        var results: OrderedSet<SymbolOccurrence> = []
        paths.forEach {
            let occurences = symbolsInSourceFile(at: $0, roles: roles)
            occurences.forEach { results.append($0) }
        }
        return results
    }

    /// Will return all symbols from within the source at the given path.
    ///
    /// **Note:** You can restrict results to a `SymbolRole` type. Default is `.declaration`.
    /// - Parameters:
    ///   - path: The absolute path to the soure file to search in.
    ///   - roles: The roles to restrict symbol results to. Default is `.declaration`.
    /// - Returns: Array of `SymbolOccurrence` instances.
    func symbolsInSourceFile(at path: String, roles: SymbolRole = .declaration) -> OrderedSet<SymbolOccurrence> {
        guard let index = index else { return [] }
        let symbols = index.symbols(inFilePath: path)
        var results: OrderedSet<SymbolOccurrence> = []
        symbols.forEach {
            index.forEachSymbolOccurrence(byUSR: $0.usr, roles: roles) { occurence in
                if roles.contains(occurence.roles) || occurence.roles.contains(roles) {
                    results.append(occurence)
                }
                return true
            }
        }
        return results
    }

    // MARK: - Helpers: Extensions

    func resolveExtensionsOnOccurrences(
        _ symbolOccurrences: OrderedSet<SymbolOccurrence>,
        kinds: [IndexSymbolKind],
        roles: SymbolRole,
        restrictToLocation directory: String?
    ) -> OrderedSet<SymbolOccurrence> {
        var results: OrderedSet<SymbolOccurrence> = []
        let targetDirectory = directory ?? ""
        let usrs = symbolOccurrences.map { $0.symbol.usr }
        usrs.forEach {
            let references = occurrences(ofUSR: $0, roles: [.reference])
            let relations: [SymbolRelation] = references.flatMap(\.relations)
            // For each valid relation usr - resolve the symbol and transform into SourceDetail
            relations.forEach { relation in
                /*
                 Empty extensions will not resolve (which is ideal as it has no extended behavior), if it has declarations it will
                 have the `.extendedBy`. Including `.definition` for safety.
                 */
                let symbols = occurrences(ofUSR: relation.symbol.usr, roles: [.definition, .reference, .extendedBy])
                // Append valid symbols to the result set
                symbols.forEach {
                    if validateRoles($0, roles: roles, canIgnore: true),
                        validateKinds($0, kinds: kinds, canIgnore: false),
                        validateProjectDirectory($0, projectDirectory: targetDirectory, canIgnore: directory == nil) {
                        results.append($0)
                    }
                }
            }
        }
        return results
    }

    // MARK: - Helpers: Validation

    func validateRoles(_ occurance: SymbolOccurrence, roles: SymbolRole, canIgnore: Bool) -> Bool {
        let roleMatch = roles.contains(occurance.roles) || occurance.roles.contains(roles)
        return roleMatch || canIgnore
    }

    func validateKinds(_ occurance: SymbolOccurrence, kinds: [IndexSymbolKind], canIgnore: Bool) -> Bool {
        kinds.contains(occurance.symbol.kind) || canIgnore
    }

    func validateProjectDirectory(_ occurance: SymbolOccurrence, projectDirectory: String, canIgnore: Bool) -> Bool {
        let isProjectDirectory = occurance.location.path.contains(projectDirectory)
        return isProjectDirectory || !canIgnore
    }

    func validateName(
        _ occurance: SymbolOccurrence,
        term: String,
        anchorStart: Bool,
        anchorEnd: Bool,
        includeSubsequence: Bool,
        ignoreCase: Bool
    ) -> Bool {
        let needle = ignoreCase ? term.lowercased() : term
        let haystack = ignoreCase ? occurance.symbol.name.lowercased() : occurance.symbol.name
        if anchorStart {
            return haystack.starts(with: needle)
        }
        if anchorEnd {
            return haystack.starts(with: needle)
        }
        if includeSubsequence {
            return haystack.contains(needle)
        }
        return haystack == needle
    }
}
