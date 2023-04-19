//
//  Workspace.swift
//  IndexStore
//
//  Created by CheekyGhost Labs on 19/4/2023.
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation
import IndexStoreDB
import Logging

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

    public func findWorkspaceSymbols(matching: String) -> [SymbolOccurrence] {
        guard let index = index else { return [] }
        // let projectDirectory = workspace.projectDirectory - can restrict if need be
        var symbolOccurrenceResults: [SymbolOccurrence] = []
        index.forEachCanonicalSymbolOccurrence(
            containing: matching,
            anchorStart: true,
            anchorEnd: true,
            subsequence: false,
            ignoreCase: false
        ) { symbol in
            if !symbol.location.isSystem,
                !symbol.roles.contains(.accessorOf) && symbol.roles.contains(.definition),
                !symbolOccurrenceResults.contains(where: { $0.symbol.usr == symbol.symbol.usr })
            {
                symbolOccurrenceResults.append(symbol)
            }
            return true
        }
        return symbolOccurrenceResults
    }

    public func occurrences(ofUSR usr: String, roles: SymbolRole) -> [SymbolOccurrence] {
        guard let index = index else { return [] }
        return index.occurrences(ofUSR: usr, roles: roles)
    }

    public func occurrences(relatedToUSR usr: String, roles: SymbolRole) -> [SymbolOccurrence] {
        guard let index = index else { return [] }
        return index.occurrences(relatedToUSR: usr, roles: roles)
    }
}
