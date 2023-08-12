//
//  IndexStore.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Foundation
import IndexStoreDB
import Logging
import TSCBasic

/// Class abstracting `IndexStoreDB` functionality that serves ``SourceSymbol`` results.
public final class IndexStore {
    // MARK: - Properties

    /// The active ``Configuration`` instance any index store derives paths from.
    public let configuration: Configuration

    /// ``Workspace`` instance to facilitate symbol lookups.
    public let workspace: Workspace

    /// Logger instance for any debug or console output.
    public let logger: Logger

    // MARK: - Lifecycle

    /// Will create a new instance and attempt to load an index store using the given values.
    /// - Parameters:
    ///   - libIndexStorePath: The path to the libIndexStore dylib.
    ///   - projectDirectory: The root project directory.
    ///   - indexStorePath: The path to the raw index store data.
    ///   - indexDatabasePath: The path to put the index database.
    ///   - logger: `Logger` instance for any debug or console output. Leave `nil` for default.
    public init(configuration: Configuration, logger: Logger? = nil) {
        let storeLogger = logger ?? .default
        self.configuration = configuration
        workspace = Workspace(configuration: configuration, logger: storeLogger)
        self.logger = storeLogger
    }

    // MARK: - Public: Convenience

    /// Will poll the underlying index store for any changes and wait for them to be processed.
    /// - Parameter isInitialScan: Bool whether this is the initial scan for changes in the index stores lifecycle.
    public func pollForChangesAndWait() {
        workspace.pollForChangesAndWait(isInitialScan: false)
    }

    /// Will return source symbols  for any declarations/symbols matching the given query.
    /// - Parameter query: The ``IndexStoreQuery`` to search with.
    /// - Returns: `Array` of ``SourceSymbol`` objects.
    public func querySymbols(_ query: IndexStoreQuery) -> [SourceSymbol] {
        // Map to workspace expectations
        let symbolKinds = query.kinds.map(\.indexSymbolKind)
        let symbolRoles = SymbolRole(rawValue: query.roles.rawValue)

        // Resolve raw results
        var rawResults: OrderedSet<SymbolOccurrence> = []

        // Direct index lookup
        if query.sourceFiles == nil {
            // Perform standard
            guard let queryTerm = query.query, !queryTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                logger.warning("Query term is `nil` or empty. Returning empty results as no source files provided.")
                return []
            }
            logger.debug("Searching for symbols matching `\(queryTerm)`: kinds `\(query.kinds)`")
            let targetDirectory = query.restrictToProjectDirectory ? configuration.projectDirectory : nil
            rawResults = workspace.querySymbols(
                matching: queryTerm,
                kinds: symbolKinds,
                roles: symbolRoles,
                anchorStart: query.anchorStart,
                anchorEnd: query.anchorEnd,
                includeSubsequence: query.includeSubsequence,
                ignoreCase: query.ignoreCase,
                restrictToLocation: targetDirectory
            )
        }
        if let sourceFiles = query.sourceFiles {
            if sourceFiles.isEmpty {
                logger.warning("Source files is `nil` or empty. Returning empty results.")
                return []
            }
            let queryLogMessage = (query.query != nil) ? "symbols matching \(query.query ?? "")" : "all symbols"
            logger.debug("Searching in `\(sourceFiles.count)` files for \(queryLogMessage): kinds `\(query.kinds)`")
            let targetDirectory = query.restrictToProjectDirectory ? configuration.projectDirectory : nil
            rawResults = workspace.querySymbols(
                inSourceFiles: sourceFiles,
                matching: query.query,
                kinds: symbolKinds,
                roles: symbolRoles,
                anchorStart: query.anchorStart,
                anchorEnd: query.anchorEnd,
                includeSubsequence: query.includeSubsequence,
                ignoreCase: query.ignoreCase,
                restrictToLocation: targetDirectory
            )
        }
        let results = rawResults.compactMap(sourceSymbolFromOccurrence)
        return results
    }

    /// Will return all swift source file paths within the given project directory.
    /// - Parameter projectRoot: The project directory to resolve source files from. Default is `Configuration.projectDirectory`
    /// - Returns: Array of source file path `String` types
    public func swiftSourceFiles(inProjectDirectory projectRoot: String? = nil) -> [String] {
        let projectRoot = projectRoot ?? configuration.projectDirectory
        let url = URL(fileURLWithPath: projectRoot)

        // Create enumerator
        let keys: [URLResourceKey] = [.isRegularFileKey]
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: keys, options: options) else {
            return []
        }
        // Enumerate and append valid source files
        var results: [URL] = []
        for case let fileURL as URL in enumerator {
            guard let attributes = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]) else {
                logger.debug("Unable to resolve attributes for file. Skipping.")
                continue
            }
            let isFile = attributes.isRegularFile ?? false
            guard isFile, fileURL.pathExtension == "swift" else {
                logger.debug("Skipping non-swift file.")
                continue
            }
            results.append(fileURL)
        }
        return results.map(\.path).sorted()
    }

    /// Will return the declaration source **line** from the source contents associated with the given details.
    ///
    /// **Note:** This will return the entire line including any whitespace. i.e if the declaration is on one line:
    /// ```
    ///     enum Foo { typealias Bar = String }
    /// ```
    /// the result will be `"    enum Foo { typealias Bar = String }"`
    /// ```
    ///     enum Foo {
    ///         typealias Bar = String
    ///     }
    /// ```
    /// the result will be `"    enum Foo {"`
    /// - Parameter symbol: The source symbol details to resolve for.
    /// - Returns: `String` if the source file exists and can be read.
    /// - Throws: ``SourceResolvingError``
    public func declarationSource(forSymbol symbol: SourceSymbol) throws -> String {
        let contents = try sourceContents(forSymbol: symbol)
        let lines = contents.components(separatedBy: .newlines)
        let normalizedLine = max(0, symbol.location.line - 1)
        guard normalizedLine < lines.count else {
            throw SourceResolvingError.unableToResolveSourceLine(
                name: symbol.name,
                path: symbol.location.path,
                line: symbol.location.line
            )
        }
        return lines[normalizedLine]
    }

    /// Will return the **full source contents** from the source file holding with the given source declaration details.
    /// - Parameter symbol: The source symbol details to resolve for.
    /// - Returns: `String` if the source file exists and can be read.
    /// - Throws: ``SourceResolvingError``
    public func sourceContents(forSymbol symbol: SourceSymbol) throws -> String {
        let path = symbol.location.path
        guard FileManager.default.fileExists(atPath: path) else {
            throw SourceResolvingError.sourcePathDoesNotExist(path: path)
        }
        do {
            let contents = try String(contentsOfFile: path)
            guard !contents.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw SourceResolvingError.sourceContentsIsEmpty(path: path)
            }
            return contents
        } catch let error as SourceResolvingError {
            throw error
        } catch {
            throw SourceResolvingError.unableToReadContents(path: path, cause: error.localizedDescription)
        }
    }

    // MARK: - Helpers: Transforming and Resolving

    /// Transforms the given occurrence into a source symbols instance.
    ///
    /// **Note: **Will also look up any inheritance and parents. This can increase time.
    /// - Parameter occurrence: The occurrence to transform
    /// - Returns: ``SourceSymbol``
    public func sourceSymbolFromOccurrence(_ occurrence: SymbolOccurrence) -> SourceSymbol {
        // Resolve source declaration kind
        let kind = SourceKind(symbolKind: occurrence.symbol.kind)
        // Source location
        let location = SourceLocation(symbol: occurrence)
        // Roles
        let roles = SourceRole(rawValue: occurrence.roles.rawValue)
        // Optional parent
        let parent = resolveParentForOccurrence(occurrence)
        // Inheritance
        let inheritanceCollection = resolveInheritanceForOccurrence(occurrence)
        // Result
        let result = SourceSymbol(
            name: occurrence.symbol.name,
            usr: occurrence.symbol.usr,
            sourceKind: kind,
            roles: roles,
            location: location,
            parent: parent,
            inheritance: inheritanceCollection
        )
        return result
    }

    /// Will resolve the immediate parent for the given occurrence.
    /// - Parameter symbolOccurrence: The `SymbolOccurrence` to resolve for.
    /// - Returns: ``SourceSymbol`` instance or `nil`
    public func resolveParentForOccurrence(_ symbolOccurrence: SymbolOccurrence) -> SourceSymbol? {
        guard !symbolOccurrence.location.isSystem else { return nil }
        guard
            let childOfRelation = symbolOccurrence.relations.first(where: {
                $0.roles.contains(.childOf) || $0.roles.contains(.calledBy) || $0.roles.contains(.containedBy)
            })
        else {
            return nil
        }
        // Resolve Occurrence Definition
        let references = workspace.occurrences(ofUSR: childOfRelation.symbol.usr, roles: [.definition])
        guard
            let parentOccurrence = references.first(where: {
                !$0.roles.contains(.extendedBy) && $0.symbol.name == childOfRelation.symbol.name
            })
        else {
            return nil
        }
        return sourceSymbolFromOccurrence(parentOccurrence)
    }

    /// Will resolve the source symbols representing the types the given occurrence conforms to or inherits from.
    /// - Parameter symbolOccurrence: The `SymbolOccurrence` to resolve for.
    /// - Returns: ``SourceSymbol`` instance or `nil`
    public func resolveInheritanceForOccurrence(_ occurrence: SymbolOccurrence) -> [SourceSymbol] {
        guard !occurrence.location.isSystem else { return [] }
        let sourceKind = SourceKind(symbolKind: occurrence.symbol.kind)
        let validSourceKinds: [SourceKind] = [.protocol, .struct, .enum, .class, .protocol]
        guard validSourceKinds.contains(sourceKind) else { return [] }
        logger.debug("resolving inheritance for source `\(occurrence.symbol.name)`")
        let references = workspace.occurrences(relatedToUSR: occurrence.symbol.usr, roles: [.baseOf])
        var results: [SourceSymbol] = []
        references.forEach { ref in
            guard
                !results.contains(where: { $0.usr == ref.symbol.usr }),
                ref.relations.contains(where: { $0.symbol.name == occurrence.symbol.name })
            else {
                return
            }
            var targetOccurrence: SymbolOccurrence?
            var occurrences = workspace.occurrences(ofUSR: ref.symbol.usr, roles: [.definition, .declaration, .canonical])
            if occurrences.isEmpty {
                occurrences = workspace.occurrences(ofUSR: ref.symbol.usr, roles: [.definition, .declaration, .canonical, .baseOf])
                targetOccurrence = occurrences.first(where: { element in
                    element.relations.contains(where: { $0.symbol.name == occurrence.symbol.name })
                })
            } else {
                targetOccurrence = occurrences.first
            }
            guard let result = targetOccurrence else { return }
            let details = sourceSymbolFromOccurrence(result)
            results.append(details)
        }
        return results
    }
}
