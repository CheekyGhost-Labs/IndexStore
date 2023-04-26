//
//  IndexStore.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation
import Files
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
    ///   - libIndexStorePath: The path to the libIndexStor dlyib.
    ///   - projectDirectory: The root project directory.
    ///   - indexStorePath: The path to the raw index store data.
    ///   - indexDatabasePath: The path to put the index database.
    ///   - logger: `Logger` instance for any debug or console output. Leave `nil` for default.
    public init(configuration: Configuration, logger: Logger? = nil) {
        let storeLogger = logger ?? .default
        self.configuration = configuration
        self.workspace = Workspace(configuration: configuration, logger: storeLogger)
        self.logger = storeLogger
    }

    // MARK: - Public: Convenience

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
        let results = rawResults.compactMap(sourceSymbolFromOccurence)
        return results
    }

    /// Will return all swift source file paths within the given project directory.
    /// - Parameter projectRoot: The project directory to resolve source files from. Default is `Configuration.projectDirectory`
    /// - Returns: Array of source file path `String` types
    public func swiftSourceFiles(inProjectDirectory projectRoot: String? = nil) -> [String] {
        let projectRoot = projectRoot ?? configuration.projectDirectory
        guard let projectFolder = try? Folder(path: projectRoot) else { return [] }
        let sourceFiles = projectFolder.files.recursive.filter { file in
            file.extension == "swift"
        }
        return sourceFiles.map(\.path)
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
    /// - Parameter details: The source declaration details to resolve for.
    /// - Returns: `String` if the source file exists and can be read.
    /// - Throws: ``SourceResolvingError``
    public func declarationSource(forDetails details: SourceSymbol) throws -> String {
        let contents = try sourceContents(forDetails: details)
        let lines = contents.components(separatedBy: .newlines)
        let normalisedLine = max(0, details.location.line - 1)
        guard normalisedLine < lines.count else {
            throw SourceResolvingError.unableToResolveSourceLine(
                name: details.name,
                path: details.location.path,
                line: details.location.line
            )
        }
        return lines[normalisedLine]
    }

    /// Will return the **full source contents** from the source file holding with the given source declaration details.
    /// - Parameter details: The source declaration details to resolve for.
    /// - Returns: `String` if the source file exists and can be read.
    /// - Throws: ``SourceResolvingError``
    public func sourceContents(forDetails details: SourceSymbol) throws -> String {
        let path = details.location.path
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

    // MARK: - Helpers: Internal

    /// Transforms the given occurance into a source symbols instance.
    ///
    /// **Note: **Will also look up any inheritence and parents. This can increase time.
    /// - Parameter occurance: The occurence to transform
    /// - Returns: ``SourceSymbol``
    func sourceSymbolFromOccurence(_ occurance: SymbolOccurrence) -> SourceSymbol {
        // Resolve source declaration kind
        let kind = SourceKind(symbolKind: occurance.symbol.kind)
        // Source location
        let location = SourceLocation(symbol: occurance)
        // Roles
        let roles = SourceRole(rawValue: occurance.roles.rawValue)
        // Optional parent
        let parent = resolveParentForOccurence(occurance)
        // Inheritence
        let inheritenceCollection = resolveInheritenceForOccurence(occurance)
        // Result
        let result = SourceSymbol(
            name: occurance.symbol.name,
            usr: occurance.symbol.usr,
            sourceKind: kind,
            roles: roles,
            location: location,
            parent: parent,
            inheritence: inheritenceCollection
        )
        return result
    }

    /// Will resolve the immediate parent for the given occurrence.
    /// - Parameter symbolOccurance: The `SymbolOccurrence` to resolve for.
    /// - Returns: ``SourceSymbol`` instance or `nil`
    func resolveParentForOccurence(_ symbolOccurance: SymbolOccurrence) -> SourceSymbol? {
        guard !symbolOccurance.location.isSystem else { return nil }
        guard
            let childOfRelation = symbolOccurance.relations.first(where: {
                $0.roles.contains(.childOf) || $0.roles.contains(.calledBy) || $0.roles.contains(.containedBy)
            })
        else {
            return nil
        }
        // Resolve Occurance Definition
        let references = workspace.occurrences(ofUSR: childOfRelation.symbol.usr, roles: [.definition])
        guard
            let parentOccurence = references.first(where: {
                !$0.roles.contains(.extendedBy) && $0.symbol.name == childOfRelation.symbol.name
            })
        else {
            return nil
        }
        return sourceSymbolFromOccurence(parentOccurence)
    }

    /// Will resolve the source symbols representing the types the given occurence conforms to or inherits from.
    /// - Parameter symbolOccurance: The `SymbolOccurrence` to resolve for.
    /// - Returns: ``SourceSymbol`` instance or `nil`
    func resolveInheritenceForOccurence(_ occurence: SymbolOccurrence) -> [SourceSymbol] {
        guard !occurence.location.isSystem else { return [] }
        let sourceKind = SourceKind(symbolKind: occurence.symbol.kind)
        let validSourceKinds: [SourceKind] = [.protocol, .struct, .enum, .class, .protocol]
        guard validSourceKinds.contains(sourceKind) else { return [] }
        logger.debug("resolving inheritence for source `\(occurence.symbol.name)`")
        let references = workspace.occurrences(relatedToUSR: occurence.symbol.usr, roles: [.baseOf])
        var results: [SourceSymbol] = []
        references.forEach { ref in
            guard
                !results.contains(where: { $0.usr == ref.symbol.usr }),
                ref.relations.contains(where: { $0.symbol.name == occurence.symbol.name })
            else {
                return
            }
            let occurences = workspace.occurrences(ofUSR: ref.symbol.usr, roles: [.definition, .baseOf, .canonical])
            let filtered = occurences.filter {
                $0.roles.contains(.definition) ||
                $0.roles.contains(.declaration) && $0.roles.contains(.canonical)
            }
            guard let target = filtered.first else { return }
            let details = sourceSymbolFromOccurence(target)
            results.append(details)
        }
        return results
    }
}
