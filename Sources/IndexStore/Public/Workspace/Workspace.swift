//
//  Workspace.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
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

    /// The path to the libIndexStore dylib.
    public let libIndexStorePath: String

    /// The root project directory.
    public let projectDirectory: String

    /// The path to the raw index store data.
    public let indexStorePath: String

    /// The path to put the index database.
    public let indexDatabasePath: String

    /// The source code index (if loaded)
    public private(set) var index: IndexStoreDB?

    /// Bool whether any index store changes should be listened for.
    /// Defaults to `true`. When initialized with a ``Configuration`` will be set to `false` when the ``Configuration/isRunningUnitTests`` is `true`.
    public let listenToUnitEvents: Bool

    /// Logger instance for any debug or console output.
    public let logger: Logger

    // MARK: - Lifecycle

    /// Will create a new instance and attempt to load an index store using the given values.
    /// - Parameters:
    ///   - libIndexStorePath: The path to the libIndexStore dylib.
    ///   - projectDirectory: The root project directory.
    ///   - indexStorePath: The path to the raw index store data.
    ///   - indexDatabasePath: The path to put the index database.
    ///   - listenToUnitEvents: Bool whether the index store should listen to unit changes. This is assigned to `false` when
    ///   - logger: `Logger` instance for any debug or console output.
    public init(
        libIndexStorePath: String,
        projectDirectory: String,
        indexStorePath: String,
        indexDatabasePath: String,
        listenToUnitEvents: Bool,
        logger: Logger
    ) {
        self.libIndexStorePath = libIndexStorePath
        self.projectDirectory = projectDirectory
        self.indexStorePath = indexStorePath
        self.indexDatabasePath = indexDatabasePath
        self.logger = logger
        self.listenToUnitEvents = listenToUnitEvents
        try? loadIndexStore()
    }

    /// Will create a new instance and attempt to load an index store using the values from the given configuration.
    /// - Parameters:
    ///   - configuration: The configuration instance holding any path values.
    ///   - logger: `Logger` instance for any debug or console output.
    public init(configuration: IndexStore.Configuration, logger: Logger) {
        // Assign overrides
        projectDirectory = configuration.projectDirectory
        indexStorePath = configuration.indexStorePath
        indexDatabasePath = configuration.indexDatabasePath
        libIndexStorePath = configuration.libIndexStorePath
        listenToUnitEvents = !configuration.isRunningUnitTests
        self.logger = logger
        // Create index store instance
        try? loadIndexStore()
    }

    // MARK: - Helpers: IndexStore

    /// Will poll the underlying index store for any changes and wait for them to be processed.
    /// - Parameter isInitialScan: Bool whether this is the initial scan for changes in the index stores lifecycle.
    public func pollForChangesAndWait(isInitialScan: Bool) {
        index?.pollForUnitChangesAndWait(isInitialScan: isInitialScan)
    }

    /// Will attempt to load the index store based on the current path settings.
    ///
    /// **Note: ** If an `index` instance is assigned it will be replaced.
    public func loadIndexStore() throws {
        index = nil
        let lib = try IndexStoreLibrary(dylibPath: libIndexStorePath)
        let storePath = URL(fileURLWithPath: indexStorePath).path
        let databasePath = URL(fileURLWithPath: indexDatabasePath).path
        do {
            index = try IndexStoreDB(
                storePath: storePath,
                databasePath: databasePath,
                library: lib,
                listenToUnitEvents: listenToUnitEvents
            )
            index?.pollForUnitChangesAndWait(isInitialScan: true)
            logger.info("Opened IndexStoreDB at \(indexDatabasePath) with store path \(indexStorePath)")
        } catch {
            logger.error("Failed to open IndexStoreDB: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Helpers: Internal

    /// Will query the index for any symbols that match the given query parameters.
    ///
    /// **Note: ** This is a direct index search.
    /// - Parameters:
    ///   - matching: Type or name query to filter results by.
    ///   - kinds: Array of kinds to restrict results to.
    ///   - roles: Set of roles to restrict roles to.
    ///   - anchorStart: Bool whether to anchor the search term to the starting bounds of a word or line Default is `true`.
    ///   - anchorEnd: Bool whether to anchor the search term to the ending bounds of a word or line Default is `true`.
    ///   - includeSubsequence: Bool whether to include symbol names that contain the term as a substring. Default is `false`.
    ///   - ignoreCase: Bool whether to perform a case insensitive search. Default is `false`.
    ///   - directory: Optional directory to restrict results to (based on `location.path`)
    /// - Returns: `OrderedSet` of `SymbolOccurrence` instances.
    func querySymbols(
        matching: String,
        kinds: [IndexSymbolKind],
        roles: SymbolRole = .all,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        ignoreCase: Bool = false,
        restrictToLocation directory: String?,
        module: String?
    ) -> OrderedSet<SymbolOccurrence> {
        guard let index = index else { return [] }
        let targetDirectory = directory ?? ""
        logger.debug("-- Searching for symbol occurrences with type `\(matching)`: roles `\(roles)`")
        var symbolOccurrenceResults: OrderedSet<SymbolOccurrence> = []
        index.forEachCanonicalSymbolOccurrence(
            containing: matching,
            anchorStart: anchorStart,
            anchorEnd: anchorEnd,
            subsequence: includeSubsequence,
            ignoreCase: ignoreCase
        ) { [self] symbol in
            // Validate symbol location (if required)
            guard validateProjectDirectory(symbol, projectDirectory: targetDirectory, canIgnore: directory == nil) else { return true }
            // Validate module name (if required)
            guard validateModule(symbol, module: module) else { return true }
            // Validate symbol roles
            guard validateRoles(symbol, roles: roles, canIgnore: false) else { return true }
            symbolOccurrenceResults.append(symbol)
            return true
        }
        return processQueryResults(symbolOccurrenceResults, kinds: kinds, roles: roles, restrictToLocation: directory)
    }

    /// Will search for symbols within the given array of source files, then filter based on the given parameters.
    /// - Parameters:
    ///   - sourceFiles: Optional array of source files to restrict searching to.
    ///   - matching: Optional type or name query to filter results by.
    ///   - kinds: Array of kinds to restrict results to.
    ///   - roles: Set of roles to restrict roles to.
    ///   - anchorStart: Bool whether to anchor the search term to the starting bounds of a word or line Default is `true`.
    ///   - anchorEnd: Bool whether to anchor the search term to the ending bounds of a word or line Default is `true`.
    ///   - includeSubsequence: Bool whether to include symbol names that contain the term as a substring. Default is `false`.
    ///   - ignoreCase: Bool whether to perform a case insensitive search. Default is `false`.
    ///   - directory: Optional directory to restrict results to (based on `location.path`)
    /// - Returns: `OrderedSet` of `SymbolOccurrence` instances.
    func querySymbols(
        inSourceFiles sourceFiles: [String],
        matching: String?,
        kinds: [IndexSymbolKind],
        roles: SymbolRole = .all,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        ignoreCase: Bool = false,
        restrictToLocation directory: String?,
        module: String?
    ) -> OrderedSet<SymbolOccurrence> {
        // Source file lookups only let you search for symbols and roles. When searching for extensions, the project directory may not
        // match a referenced symbol. The approach here is to search for symbols, then filter by project, kinds, and name, then grab any
        // extensions (if searching for extensions). Extension lookups are also filtered by kinds and project
        guard !sourceFiles.isEmpty else {
            logger.warning("sourceFiles is empty. Returning empty results")
            return []
        }
        let targetDirectory = directory ?? ""
        let rawResults = symbolsInSourceFiles(at: sourceFiles, roles: roles)
        var symbolOccurrenceResults: OrderedSet<SymbolOccurrence> = []
        // Filter Results
        rawResults.forEach {
            // Validate symbol location (if required)
            guard validateProjectDirectory($0, projectDirectory: targetDirectory, canIgnore: directory == nil) else { return }
            // Validate module name (if required)
            guard validateModule($0, module: module) else { return }
            // Validate symbol roles
            guard validateRoles($0, roles: roles, canIgnore: false) else { return }
            // Name match (if present)
            let nameMatch = validateName(
                $0.symbol.name,
                term: matching,
                anchorStart: anchorStart,
                anchorEnd: anchorEnd,
                includeSubsequence: includeSubsequence,
                ignoreCase: ignoreCase
            )
            if nameMatch { symbolOccurrenceResults.append($0) }
        }
        return processQueryResults(symbolOccurrenceResults, kinds: kinds, roles: roles, restrictToLocation: directory)
    }

    // MARK: - Helpers: Querying

    /// Will return any symbol occurrences of the given USR identifier.
    ///
    /// - Parameters:
    ///   - usr: The usr of the source symbol to search for.
    ///   - roles: The roles to restrict symbol results to.
    /// - Returns: Array of `SymbolOccurrence` instances.
    func occurrences(ofUSR usr: String, roles: SymbolRole) -> OrderedSet<SymbolOccurrence> {
        guard let index = index else { return [] }
        let results = index.occurrences(ofUSR: usr, roles: roles)
        return OrderedSet<SymbolOccurrence>(results)
    }

    func occurrences(
        ofUSR usr: String,
        matching: String?,
        kinds: [IndexSymbolKind],
        roles: SymbolRole = .all,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        ignoreCase: Bool = false,
        restrictToLocation directory: String?,
        module: String?
    ) -> OrderedSet<SymbolOccurrence> {
        guard let index = index else { return [] }
        let targetDirectory = directory ?? ""
        let rawResults = index.occurrences(ofUSR: usr, roles: roles)
        var symbolOccurrenceResults: OrderedSet<SymbolOccurrence> = []
        rawResults.forEach {
            // Location check on occurrence (if required)
            guard validateProjectDirectory($0, projectDirectory: targetDirectory, canIgnore: directory == nil) else { return }
            // Validate module name (if required)
            guard validateModule($0, module: module) else { return }
            // Name match (if present)
            let nameMatch = validateName(
                $0.symbol.name,
                term: matching,
                anchorStart: anchorStart,
                anchorEnd: anchorEnd,
                includeSubsequence: includeSubsequence,
                ignoreCase: ignoreCase
            )
            if nameMatch { symbolOccurrenceResults.append($0) }
        }
        return symbolOccurrenceResults
    }

    /// Will return any symbol occurrences that are related to the given USR identifier.
    ///
    /// - Parameters:
    ///   - usr: The usr of the source symbol to search for relations to.
    ///   - roles: The roles to restrict symbol results to.
    /// - Returns: Array of `SymbolOccurrence` instances.
    func occurrences(relatedToUSR usr: String, roles: SymbolRole) -> OrderedSet<SymbolOccurrence> {
        guard let index = index else { return [] }
        let results = index.occurrences(relatedToUSR: usr, roles: roles)
        return OrderedSet<SymbolOccurrence>(results)
    }

    func occurrences(
        relatedToUSR usr: String,
        matching: String?,
        kinds: [IndexSymbolKind],
        roles: SymbolRole = .all,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        ignoreCase: Bool = false,
        restrictToLocation directory: String?,
        restrictedToSourceFiles sourceFiles: [String] = [],
        module: String?
    ) -> OrderedSet<SymbolOccurrence> {
        guard let index = index else { return [] }
        let targetDirectory = directory ?? ""
        let rawResults = index.occurrences(relatedToUSR: usr, roles: .all)
        var symbolOccurrenceResults: OrderedSet<SymbolOccurrence> = []
        rawResults.forEach {
            // Validate a relation matches the usr of the symbol
            guard $0.relations.contains(where: { $0.symbol.usr == usr }) else { return }
            symbolOccurrenceResults.append($0)
        }
        // Map relations
        var resultSet: OrderedSet<SymbolOccurrence> = []
        let relationUsrs = rawResults.map(\.symbol.usr)
        relationUsrs.forEach {
            // Send roles from parameters here and let index store db handle filtering
            let occurrences = occurrences(ofUSR: $0, roles: roles)
            occurrences.forEach {
                // Location check on occurrence (if required)
                guard validateProjectDirectory($0, projectDirectory: targetDirectory, canIgnore: directory == nil) else { return }
                // Validate module name (if required)
                guard validateModule($0, module: module) else { return }
                // Name match for occurrence (if required)
                let nameMatch = validateName(
                    $0.symbol.name,
                    term: matching,
                    anchorStart: anchorStart,
                    anchorEnd: anchorEnd,
                    includeSubsequence: includeSubsequence,
                    ignoreCase: ignoreCase
                )
                guard nameMatch else { return }
                guard !sourceFiles.isEmpty else {
                    resultSet.append($0)
                    return
                }
                if sourceFiles.contains($0.location.path) {
                    resultSet.append($0)
                }
            }
        }
        return resultSet
    }

    // MARK: - Helpers: Result processing

    /// Will take the given raw set of symbols and filter based on the given parameters. Will also perform any extension lookups if required.
    /// - Parameters:
    ///   - occurrences: Set of `SymbolOccurrence` instances to process.
    ///   - kinds: Array of kinds to restrict results to.
    ///   - roles: Set of roles to restrict roles to.
    ///   - directory: Optional directory to restrict results to (based on `location.path`)
    /// - Returns: `OrderedSet` of `SymbolOccurrence` instances
    func processQueryResults(
        _ occurrences: OrderedSet<SymbolOccurrence>,
        kinds: [IndexSymbolKind],
        roles: SymbolRole = .all,
        restrictToLocation directory: String?
    ) -> OrderedSet<SymbolOccurrence> {
        let notExtensionKinds = kinds.filter { $0 != .extension }
        var results: OrderedSet<SymbolOccurrence> = []
        // Extensions have to be resolved via USR name
        guard kinds.contains(.extension) else {
            occurrences.forEach {
                // Kind match
                var kindsMatch = !notExtensionKinds.isEmpty && notExtensionKinds.contains($0.symbol.kind)
                if kinds.contains(.extension), $0.symbol.kind == .extension {
                    kindsMatch = true
                }
                if kindsMatch {
                    results.append($0)
                }
            }
            logger.debug("`.extensions` kind not included - skipping extensions lookup")
            return results
        }
        // If just looking for extensions can keep an empty result set to only populate extensions, otherwise include filtered results.
        if kinds != [.extension] {
            occurrences.forEach {
                if kinds.contains($0.symbol.kind) {
                    results.append($0)
                }
            }
        }
        logger.debug("`.extensions` kind included - performing USR extension lookup")
        let extensions = resolveExtensionsOnOccurrences(occurrences, kinds: kinds, roles: roles, restrictToLocation: directory)
        extensions.forEach { results.append($0) }
        logger.debug("-- `\(results.count)` results")
        return results
    }

    // MARK: - Helpers: Source file resolving

    /// Will return all symbols from within the source files at the given paths.
    ///
    /// **Note:** You can restrict results to a `SymbolRole` type. Default is `.declaration`.
    /// - Parameters:
    ///   - path: Array of absolute paths to the source files to search in.
    ///   - kinds: Array of `IndexSymbolKind` cases to restrict results to.
    ///   - roles: The roles to restrict symbol results to. Default is `.declaration`.
    /// - Returns: Array of `SymbolOccurrence` instances.
    func symbolsInSourceFiles(at paths: [String], roles: SymbolRole = .declaration) -> OrderedSet<SymbolOccurrence> {
        guard index != nil else { return [] }
        var results: OrderedSet<SymbolOccurrence> = []
        paths.forEach {
            let occurrences = symbolsInSourceFile(at: $0, roles: roles)
            occurrences.forEach { results.append($0) }
        }
        return results
    }

    /// Will return all symbols from within the source at the given path.
    ///
    /// **Note:** You can restrict results to a `SymbolRole` type. Default is `.declaration`.
    /// - Parameters:
    ///   - path: The absolute path to the source file to search in.
    ///   - roles: The roles to restrict symbol results to. Default is `.declaration`.
    /// - Returns: Array of `SymbolOccurrence` instances.
    func symbolsInSourceFile(at path: String, roles: SymbolRole = .declaration) -> OrderedSet<SymbolOccurrence> {
        guard let index = index else { return [] }
        let symbols = index.symbols(inFilePath: path)
        var results: OrderedSet<SymbolOccurrence> = []
        symbols.forEach { symbol in
            index.forEachSymbolOccurrence(byUSR: symbol.usr, roles: roles) { occurrence in
                results.append(occurrence)
                return true
            }
        }
        return results
    }

    // MARK: - Helpers: Extensions

    /// Will resolve any extension symbols for the given array of occurrences.
    /// - Parameters:
    ///   - symbolOccurrences: Set of `SymbolOccurrence` instances to search with.
    ///   - kinds: Array of `IndexSymbolKind` cases to restrict results to.
    ///   - roles: The roles to restrict symbol results to. Default is `.declaration`.
    ///   - directory: Optional directory to restrict results to (based on `location.path`)
    /// - Returns: `OrderedSet` of `SymbolOccurrence` instances.
    func resolveExtensionsOnOccurrences(
        _ symbolOccurrences: OrderedSet<SymbolOccurrence>,
        kinds: [IndexSymbolKind],
        roles _: SymbolRole,
        restrictToLocation directory: String?
    ) -> OrderedSet<SymbolOccurrence> {
        var results: OrderedSet<SymbolOccurrence> = []
        let targetDirectory = directory ?? ""
        symbolOccurrences.forEach {
            if $0.symbol.kind == .extension {
                results.append($0)
                return
            }
            let references = occurrences(ofUSR: $0.symbol.usr, roles: [.reference, .extendedBy])
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
                    if validateKind($0.symbol.kind, kinds: kinds, canIgnore: false),
                       validateProjectDirectory($0, projectDirectory: targetDirectory, canIgnore: directory == nil)
                    {
                        results.append($0)
                    }
                }
            }
        }
        return results
    }

    // MARK: - Helpers: Validation

    func validateRoles(_ targetRoles: SymbolRole, roles: SymbolRole, canIgnore: Bool) -> Bool {
        let intersection = targetRoles.intersection(roles)
        return !intersection.isEmpty
    }

    func validateRoles(_ occurrence: SymbolOccurrence, roles: SymbolRole, canIgnore: Bool) -> Bool {
        let intersection = occurrence.roles.intersection(roles)
        return !intersection.isEmpty
    }

    func validateProjectDirectory(_ occurrence: SymbolOccurrence, projectDirectory: String, canIgnore: Bool) -> Bool {
        let isProjectDirectory = occurrence.location.path.contains(projectDirectory)
        return isProjectDirectory || canIgnore
    }

    func validateKind(_ kind: IndexSymbolKind, kinds: [IndexSymbolKind], canIgnore: Bool) -> Bool {
        kinds.contains(kind) || canIgnore
    }

    func validateModule(_ occurrence: SymbolOccurrence, module: String?) -> Bool {
        guard let module = module else { return true }
        return occurrence.location.moduleName == module
    }

    func validateName(
        _ name: String,
        term: String?,
        anchorStart: Bool,
        anchorEnd: Bool,
        includeSubsequence: Bool,
        ignoreCase: Bool
    ) -> Bool {
        guard let term = term, !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return true }
        let needle = ignoreCase ? term.lowercased() : term
        let haystack = ignoreCase ? name.lowercased() : name
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
