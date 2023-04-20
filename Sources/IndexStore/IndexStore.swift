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
import TSCBasic

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
    ///   - logger: `Logger` instance for any debug or console output. Leave `nil` for default.
    public init(configuration: Configuration, logger: Logger? = nil) {
        let storeLogger = logger ?? .default
        self.configuration = configuration
        self.workspace = Workspace(configuration: configuration, logger: storeLogger)
        self.logger = storeLogger
    }

    // MARK: - Helpers: Public: SourceFiles

    public func swiftSourceFiles(inProjectDirectory projectRoot: String? = nil) -> [String] {
        let fileManager = FileManager.default
        let projectRoot = projectRoot ?? configuration.projectDirectory
        guard let enumerator = fileManager.enumerator(atPath: projectRoot) else { return [] }
        var swiftSourceFiles: [String] = []
        for case let fileURL as URL in enumerator where fileURL.pathExtension == "swift" {
            swiftSourceFiles.append(fileURL.path)
        }
        return swiftSourceFiles
    }

    // MARK: - Helpers: Public: Indexing

    /// Will return source details  for any declarations/symbols matching the given type and whose declaration kind is contained in the given array.
    /// - Parameters:
    ///   - type: The type to search for.
    ///   - kinds: Array of ``SourceKind`` types to restrict results to.
    ///   - roles: ``SourceRole`` set types to restrict results to.
    ///   - anchorStart: Bool wether to anchor the search term to the starting bounds of a word or line Default is `true`.
    ///   - anchorEnd: Bool wether to anchor the search term to the end bounds of a word or line. Default is `true`.
    ///   - includeSubsequence: Bool whether to include symbol names that contain the term as a substring. Default is `false`.
    ///   - caseInsensitive: Bool whether to perform a case insensitive search. Default is `false`.
    /// - Returns: `Array` of ``SourceDetails`` objects.
    public func sourceDetails(
        matchingType type: String,
        kinds: [SourceKind] = SourceKind.allCases,
        roles: SourceRole = .all,
        anchorStart: Bool = true,
        anchorEnd: Bool = true,
        includeSubsequence: Bool = false,
        caseInsensitive: Bool = false
    ) -> [SourceDetails] {
        logger.debug("Searching for symbol occurances with type `\(type)`: kinds `\(kinds)`")
        let symbolRoles = SymbolRole(rawValue: roles.rawValue)
        let rawResults = workspace.findWorkspaceSymbols(
            matching: type,
            roles: symbolRoles,
            anchorStart: anchorStart,
            anchorEnd: anchorEnd,
            includeSubsequence: includeSubsequence,
            caseInsensitive: caseInsensitive
        )
        var results: [SourceDetails] = rawResults.compactMap(sourceDetailsFromOccurence)
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
                let symbols = workspace.occurrences(ofUSR: relation.symbol.usr, roles: [.extendedBy, .definition])
                let transformed = symbols.compactMap(sourceDetailsFromOccurence)
                // Append valid symbols to the result set
                results.append(contentsOf: transformed)
            }
        }
        return resultsFilteredByKind(results: results, kinds: kinds)
    }

    /// Will return source details  for any declarations/symbols within the store that match the given source kinds and roles.
    ///
    /// **Note: ** This method iteratest through **all** source files in the project. It can be expensive if you
    /// have a vast source file count. Filtering for source kinds is also done while iterating.
    /// - Parameters:
    ///   - kinds: The source kinds to search for.
    ///   - roles: The roles any symbols must match.
    /// - Returns: Array of ``SourceDetails`` instances.
    public func sourceDetailsForSourceKinds(_ kinds: [SourceKind], roles: SourceRole) -> [SourceDetails] {
        let sourceFiles = swiftSourceFiles()
        let symbolRoles = SymbolRole(rawValue: roles.rawValue)
        let symbolKinds = kinds.map(\.indexSymbolKind)
        let occurences = workspace.symbolsInSourceFiles(at: sourceFiles, kinds: symbolKinds, roles: symbolRoles)
        var results: [SourceDetails] = []
        mapOccurencesToResults(occurences, into: &results)
        return results
    }

    /// Will return the source details for any  extension declarations/symbols within the store that extend the given source type.
    /// - Parameter type: The source type being extended
    /// - Returns: Array of ``SourceDetails`` instances.
    public func sourceDetails(extendingType type: String) -> [SourceDetails] {
        let rawResults = workspace.findWorkspaceSymbols(matching: type)
        let conformingTypes: [SourceDetails] = rawResults.flatMap {
            let conforming = workspace.occurrences(ofUSR: $0.symbol.usr, roles: [.reference, .extendedBy])
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

    /// Will return source details  for any declarations/symbols within the store that conform to the given protocol.
    /// - Parameter protocolName: The protocol to search for.
    /// - Returns: Array of ``SourceDetails``
    public func sourceDetails(conformingToProtocol protocolName: String) -> [SourceDetails] {
        let rawResults = workspace.findWorkspaceSymbols(matching: protocolName).filter { $0.symbol.kind == .protocol }
        let conformingTypes: [SourceDetails] = rawResults.flatMap {
            let conforming = workspace.occurrences(ofUSR: $0.symbol.usr, roles: [.reference, .baseOf])
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

    // MARK: - Public: Convenience

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

    /// Will filter the given results by the given source kinds
    /// - Parameters:
    ///   - results: The results to filter.
    ///   - kinds: Array of `SourceKind` types to filter with.
    /// - Returns: Array of ``SourceDetails`` instances
    func resultsFilteredByKind(results: [SourceDetails], kinds: [SourceKind]) -> [SourceDetails] {
        results.filter { kinds.contains($0.sourceKind) }
    }

    /// Will transform the given set of ``SymbolOccurrence`` instances into ``SourceDetails`` instances and append them to the given array.
    /// - Parameters:
    ///   - occurences: Set of ``SymbolOccurrence`` instances to transform.
    ///   - results: ``SourceDetails`` array to append results to
    func mapOccurencesToResults(_ occurences: OrderedSet<SymbolOccurrence>, into results: inout [SourceDetails]) {
        occurences.forEach {
            let details = sourceDetailsFromOccurence($0)
            if !details.location.isStale, !configuration.excludeStaleResults {
                results.append(details)
            }
        }
    }

    /// Transforms the given occurance into a source details instance.
    ///
    /// **Note: **Will also look up any inheritence and parents. This can increase time.
    /// - Parameter occurance: The occurence to transform
    /// - Returns: ``SourceDetails``
    func sourceDetailsFromOccurence(_ occurance: SymbolOccurrence) -> SourceDetails {
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

    /// Will resolve the immediate parent for the given occurrence.
    /// - Parameter symbolOccurance: The `SymbolOccurrence` to resolve for.
    /// - Returns: ``SourceDetails`` instance or `nil`
    func resolveParentForOccurence(_ symbolOccurance: SymbolOccurrence) -> SourceDetails? {
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

    /// Will resolve the source details representing the types the given occurence conforms to or inherits from.
    /// - Parameter symbolOccurance: The `SymbolOccurrence` to resolve for.
    /// - Returns: ``SourceDetails`` instance or `nil`
    func resolveInheritenceForOccurence(_ occurance: SymbolOccurrence) -> [SourceDetails] {
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
                let details = sourceDetails(matchingType: ref.symbol.name, kinds: validSourceKinds).first
            else {
                return
            }
            results.append(details)
        }
        return results
    }
}
