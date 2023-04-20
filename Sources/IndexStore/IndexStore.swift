//
//  IndexStore.swift
//  IndexStore
//
//  Created by CheekyGhost Labs on 19/4/2023.
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation
import IndexStoreDB
import Logging

/// Class abstracting `IndexStoreDB` functionality that serves ``SourceDetails`` results.
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
    ///   - logger: `Logger` instance for any debug or console output.
    public init(configuration: Configuration, logger: Logger) {
        self.configuration = configuration
        self.workspace = Workspace(configuration: configuration, logger: logger)
        self.logger = logger
    }

    // MARK: - Helpers: Public: SourceFiles

    public func swiftSourceFiles(inProjectDirectory projectRoot: String? = nil) -> [String] {
        let fileManager = FileManager.default
        let projectRoot = projectRoot ?? configuration.projectDirectory
        guard let enumerator = fileManager.enumerator(atPath: projectRoot) else { return [] }
        var swiftSourceFiles: [String] = []
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift" {
                swiftSourceFiles.append(fileURL.path)
            }
        }
        return swiftSourceFiles
    }

    // MARK: - Helpers: Public: Indexing

    /// Will return an array of ``SourceDetails`` instances for any declarations matching the given type and whose declaration kind is contained in the given array.
    /// - Parameters:
    ///   - type: The type to search for.
    ///   - kinds: Array of ``SourceKind`` types to restrict results to.
    /// - Returns: `Array` of ``SourceDetails`` objects.
    public func sourceDetailsForType(_ type: String, kinds: [SourceKind]) -> [SourceDetails] {
        logger.debug("Searching for symbol occurances with type `\(type)`: kinds `\(kinds)`")
        let rawResults = workspace.findWorkspaceSymbols(matching: type)
        var results = rawResults.compactMap(sourceDetailsFromOccurence)
        // Extensions have to be resolved via USR name
        guard kinds.contains(.extension) else {
            logger.debug("`.extensions` kind not included - skipping extensions lookup")
            return resultsFilteredByKind(results: results, kinds: kinds)
        }
        logger.debug("`.extensions` kind included - performing USR extension lookup")
        let usrs = results.map(\.usr)
        usrs.forEach {
            /*
             Empty extensions will not resolve (which is ideal as it has no extended behavior), if it has declarations it will
             have the `.extendedBy`. Including `.definition` for safety.
             */
            let references = workspace.occurrences(ofUSR: $0, roles: [.reference])
            let relations: [SymbolRelation] = references.flatMap(\.relations)
            // For each valid relation usr - resolve the symbol and transform into SourceDetail
            relations.forEach { relation in
                let symbols = workspace.occurrences(
                    ofUSR: relation.symbol.usr, roles: [.extendedBy, .definition])
                let transformed = symbols.compactMap(sourceDetailsFromOccurence)
                // Append valid symbols to the result set
                results.append(contentsOf: transformed)
            }
        }
        return resultsFilteredByKind(results: results, kinds: kinds)
    }

    public func sourceDetailsForSourceKinds(_ kinds: [SourceKind], roles: SourceRole) -> [SourceDetails] {
        let sourceFiles = swiftSourceFiles()
        let symbolRoles = SymbolRole(rawValue: roles.rawValue)
        // Parse ensuring no duplicates exist
        var parsedSymbols: [SymbolOccurrence] = []
        var results: [SourceDetails] = []
        sourceFiles.forEach { filePath in
            let occurences = workspace.symbolsInSourceFile(at: filePath, roles: symbolRoles).filter { !parsedSymbols.contains($0) }
            parsedSymbols.append(contentsOf: occurences)
            mapOccurencesToResults(occurences, into: &results)
        }
        return results
    }

    public func sourceDetailsForExtensionOfType(_ type: String) -> [SourceDetails] {
        let rawResults = workspace.findWorkspaceSymbols(matching: type).filter {
            $0.roles.contains(.definition)
        }
        let conformingTypes: [SourceDetails] = rawResults.flatMap {
            let conforming = workspace.occurrences(
                ofUSR: $0.symbol.usr, roles: [.reference, .extendedBy])
            let validUsrs: [String] = conforming.flatMap {
                guard $0.roles == [.reference, .extendedBy] else {
                    return [String]()
                }
                return $0.relations.map(\.symbol.usr)
            }
            let occurances = validUsrs.flatMap {
                return workspace.occurrences(ofUSR: $0, roles: [.definition])
            }
            return occurances.compactMap(sourceDetailsFromOccurence)
        }
        return conformingTypes
    }

    public func sourceDetailsForTypesConformingToProtocolNamed(_ name: String) -> [SourceDetails] {
        let rawResults = workspace.findWorkspaceSymbols(matching: name).filter {
            $0.symbol.kind == .protocol && $0.roles.contains(.definition)
        }
        let conformingTypes: [SourceDetails] = rawResults.flatMap {
            let conforming = workspace.occurrences(
                ofUSR: $0.symbol.usr, roles: [.reference, .baseOf])
            let validUsrs: [String] = conforming.flatMap {
                guard $0.roles == [.reference, .baseOf] else {
                    return [String]()
                }
                return $0.relations.map(\.symbol.usr)
            }
            let occurances = validUsrs.flatMap {
                return workspace.occurrences(ofUSR: $0, roles: [.definition])
            }
            return occurances.compactMap(sourceDetailsFromOccurence)
        }
        return conformingTypes
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
    public func declarationSourceForDetails(_ details: SourceDetails) throws -> String {
        let contents = try sourceContentsForDetails(details)
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
    public func sourceContentsForDetails(_ details: SourceDetails) throws -> String {
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

    func resultsFilteredByKind(results: [SourceDetails], kinds: [SourceKind]) -> [SourceDetails] {
        results.filter { kinds.contains($0.sourceKind) }
    }

    func mapOccurencesToResults(_ occurences: [SymbolOccurrence], into results: inout [SourceDetails]) {
        occurences.forEach {
            let details = sourceDetailsFromOccurence($0)
            if !details.location.isStale, !configuration.excludeStaleResults {
                results.append(details)
            }
        }
    }

    func sourceDetailsFromOccurence(_ occurance: SymbolOccurrence) -> SourceDetails {
        // Resolve source declaration kind
        let kind = SourceKind(symbolKind: occurance.symbol.kind)
        // Source location
        let location = SourceLocation(symbol: occurance)
        // Roles
        let roles = SourceRole(rawValue: occurance.roles.rawValue)
        // Optional parent
        let parent = resolveParentForOccurance(occurance)
        // Inheritence
        let inheritenceCollection = resolveInheritenceForOccurance(occurance)
        // Result
        let result = SourceDetails(
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

    func resolveParentForOccurance(_ symbolOccurance: SymbolOccurrence) -> SourceDetails? {
        guard
            let childOfRelation = symbolOccurance.relations.first(where: {
                $0.roles.contains(.childOf)
            })
        else {
            return nil
        }
        // Resolve Occurance Definition
        let references = workspace.occurrences(
            ofUSR: childOfRelation.symbol.usr, roles: [.definition])
        guard
            let parentOccurence = references.first(where: {
                $0.symbol.name == childOfRelation.symbol.name
            })
        else {
            return nil
        }
        return sourceDetailsFromOccurence(parentOccurence)
    }

    func resolveInheritenceForOccurance(_ occurance: SymbolOccurrence) -> [SourceDetails] {
        let sourceKind = SourceKind(symbolKind: occurance.symbol.kind)
        let validSourceKinds: [SourceKind] = [.protocol, .struct, .enum, .class, .protocol]
        guard validSourceKinds.contains(sourceKind) else { return [] }
        logger.debug("resolving inheritence for source `\(occurance.symbol.name)`")
        let references = workspace.occurrences(relatedToUSR: occurance.symbol.usr, roles: [.baseOf])
        var results: [SourceDetails] = []
        references.forEach { ref in
            guard
                !results.contains(where: { $0.usr == ref.symbol.usr }),
                ref.relations.contains(where: { $0.symbol.name == occurance.symbol.name }),
                let details = sourceDetailsForType(ref.symbol.name, kinds: validSourceKinds).first
            else {
                return
            }
            results.append(details)
        }
        return results
    }
}
