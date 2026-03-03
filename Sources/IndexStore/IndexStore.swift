//
//  IndexStore.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Foundation
import IndexStoreDB
import OSLog
import TSCBasic

/// Class abstracting `IndexStoreDB` functionality that serves ``SourceSymbol`` results.
public final class IndexStore {

    // MARK: - Supplementary

    /// Enumeration of supported limit strategies to use when resolving inherited symbols.
    public enum RecursiveSearchStrategy: Hashable, Sendable {
        /// All symbols will be recursively resolved
        case all
        /// Only symbols immediately referenced to matching results will be resolved
        case immediate
        /// Symbols will be recursively resolved up until the given recursive limit.
        /// - For example, sending `1` would be the same as `.immediate`, sending `2` would be `immediate + 1` and so on.
        /// - Note: Sending
        case level(Int)
        /// Will not attempt to search for any related symbols (parents, inheritance etc)
        case noSearching
    }
    
    /// Struct holding the recursive strategies to use when resolving parent and inheritance symbols.
    public struct RecursiveSearchConfiguration: Hashable, Sendable {
        
        /// The strategy to use when resolving parent symbols.
        public let parent: RecursiveSearchStrategy

        /// The strategy to use when resolving inheritance symbols.
        public let inheritance: RecursiveSearchStrategy

        // MARK: - Lifecycle

        public init(parent: RecursiveSearchStrategy, inheritance: RecursiveSearchStrategy) {
            self.parent = parent
            self.inheritance = inheritance
        }

        
        /// Convenience property that returns an instance with the given strategy assigned to the `parent` property and the `inheritance`
        /// using the ``IndexStore/RecursiveSearchStrategy/all`` strategy.
        /// - Parameter strategy: The strategy to assign.
        /// - Returns: ``IndexStore/RecursiveSearchStrategy``
        public static func parent(_ strategy: RecursiveSearchStrategy) -> Self {
            .init(parent: strategy, inheritance: .all)
        }

        /// Convenience property that returns an instance with the given strategy assigned to the `inheritance` property and the `parent`
        /// using the ``IndexStore/RecursiveSearchStrategy/all`` strategy.
        /// - Parameter strategy: The strategy to assign.
        /// - Returns: ``IndexStore/RecursiveSearchStrategy``
        public static func inheritance(_ strategy: RecursiveSearchStrategy) -> Self {
            .init(parent: .all, inheritance: strategy)
        }

        /// Convenience property that returns an instance with both parent and inheritance
        /// using the ``IndexStore/RecursiveSearchStrategy/all`` strategy.
        public static var all: Self {
            .init(parent: .all, inheritance: .all)
        }

        /// Convenience property that returns an instance with both parent and inheritance
        /// using the ``IndexStore/RecursiveSearchStrategy/immediate`` strategy.
        public static var immediate: Self {
            .init(parent: .immediate, inheritance: .immediate)
        }

        /// Convenience property that returns an instance with both parent and inheritance
        /// using the ``IndexStore/RecursiveSearchStrategy/level(_:)`` strategy.
        public static func level(_ value: Int) -> Self {
            let cleanValue = max(0, value)
            return .init(parent: .level(cleanValue), inheritance: .level(cleanValue))
        }

        /// Convenience property that returns an instance with both parent and inheritance
        /// using the ``IndexStore/RecursiveSearchStrategy/noSearching`` strategy.
        public static var noSearching: Self {
            .init(parent: .noSearching, inheritance: .noSearching)
        }
        
        /// Will return a new instance using the current ``inheritance`` strategy and assigning the given value to the ``parent`` strategy.
        /// - Parameter strategy: The strategy to assign.
        /// - Returns: `RecursiveSearchConfiguration`
        public func withParentStrategy(_ strategy: RecursiveSearchStrategy) -> Self {
            .init(parent: strategy, inheritance: inheritance)
        }

        /// Will return a new instance using the current ``parent`` strategy and assigning the given value to the ``inheritance`` strategy.
        /// - Parameter strategy: The strategy to assign.
        /// - Returns: `RecursiveSearchConfiguration`
        public func withInheritanceStrategy(_ strategy: RecursiveSearchStrategy) -> Self {
            .init(parent: parent, inheritance: strategy)
        }

        // MARK: - Helpers: Internal

        /// Returns a configuration that should be used for the *next* recursive call when resolving a parent.
        func nextForParentRecursion() -> Self {
            switch parent {
            case .all:
                return self
            case .immediate:
                return .init(parent: .noSearching, inheritance: inheritance)
            case .level(let level):
                let next = level - 1
                return .init(parent: next <= 0 ? .noSearching : .level(next), inheritance: inheritance)
            case .noSearching:
                return self // should never be used, but keep it stable
            }
        }

        /// Returns a configuration that should be used for the *next* recursive call when resolving inheritance.
        func nextForInheritanceRecursion() -> Self {
            switch inheritance {
            case .all:
                return self
            case .immediate:
                return .init(parent: parent, inheritance: .noSearching)
            case .level(let level):
                let next = level - 1
                return .init(parent: parent, inheritance: next <= 0 ? .noSearching : .level(next))
            case .noSearching:
                return self
            }
        }
    }

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

    /// Will return source symbols for any declarations/symbols matching the given query.
    ///
    /// When you query for a symbol, you're asking the database for information about that entity's definition and primary properties.  Think of a symbol as an abstract representation of a code entity.
    /// For instance, if you have a class named `MyClass` defined in your codebase, querying for this symbol would give you information about `MyClass` itself, such as its location, documentation,
    /// accessibility level, etc
    ///
    /// - Parameters:
    ///   - query: The ``IndexStoreQuery`` to search with.
    ///   - recursiveSearchConfig: Configuration holding the recursive search strategies to use when searching for parents and inheritance.
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
                restrictToLocation: targetDirectory,
                module: query.module
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
                restrictToLocation: targetDirectory,
                module: query.module
            )
        }
        let results = rawResults.compactMap {
            sourceSymbolFromOccurrence($0, recursiveSearchConfig: query.recursiveSearchConfig)
        }
        return results
    }

    /// Will return source symbols for any occurrences matching the given ``SourceSymbol`` and  query parameters.
    ///
    /// Querying for an occurrence of a symbol will ask for all places where that symbol is used or referenced.
    ///
    /// For example, if you have declared a class named `MyClass`, the occurrences of this symbol would be everywhere in the code where `MyClass` is mentioned, like in object instantiations,
    /// type annotations, or subclassing etc.
    ///
    /// - Parameters:
    ///   - symbol: The ``SourceSymbol`` instance to search for.
    ///   - query: The ``IndexStoreQuery`` to search with.
    ///   - recursiveSearchConfig: Configuration holding the recursive search strategies to use when searching for parents and inheritance.
    /// - Returns: `Array` of ``SourceSymbol`` objects.
    public func queryOccurrences(
        ofSymbol symbol: SourceSymbol,
        query: IndexStoreQuery
    ) -> [SourceSymbol] {
        queryOccurrences(ofUsr: symbol.usr, query: query)
    }

    /// Will return source symbols for any occurrences matching the given ``SourceSymbol/usr`` and  query parameters.
    ///
    /// Querying for an occurrence of a symbol will ask for all places where that symbol is used or referenced.
    ///
    /// For example, if you have declared a class named `MyClass`, the occurrences of this symbol would be everywhere in the code where `MyClass` is mentioned, like in object instantiations,
    /// type annotations, or subclassing etc.
    ///
    /// - Parameters:
    ///   - usr: The ``SourceSymbol/usr`` to search with.
    ///   - query: The ``IndexStoreQuery`` to search with.
    ///   - recursiveSearchConfig: Configuration holding the recursive search strategies to use when searching for parents and inheritance.
    /// - Returns: `Array` of ``SourceSymbol`` objects.
    public func queryOccurrences(
        ofUsr usr: String,
        query: IndexStoreQuery
    ) -> [SourceSymbol] {
        let symbolKinds = query.kinds.map(\.indexSymbolKind)
        let symbolRoles = SymbolRole(rawValue: query.roles.rawValue)
        let targetDirectory = query.restrictToProjectDirectory ? configuration.projectDirectory : nil
        let occurrences = workspace.occurrences(
            ofUSR: usr,
            matching: query.query,
            kinds: symbolKinds,
            roles: symbolRoles,
            anchorStart: query.anchorStart,
            anchorEnd: query.anchorEnd,
            includeSubsequence: query.includeSubsequence,
            ignoreCase: query.ignoreCase,
            restrictToLocation: targetDirectory,
            module: query.module
        )
        let results = occurrences.compactMap {
            sourceSymbolFromOccurrence($0, recursiveSearchConfig:  query.recursiveSearchConfig)
        }
        return results
    }

    /// Will return source symbols that have a defined semantic or structural relation to the given symbol.
    /// For example:
    /// - **Overrides:** If you're looking at a method in a base class, the related symbols could be methods in derived classes that override it.
    /// - **Implementations:** In the context of protocols or interfaces, related symbols might be the concrete implementations of those abstract methods or properties in conforming types.
    /// - **References:** This could be broader than direct usage, encompassing any symbol that has a semantic connection to the original one. For instance, a function that is passed as a 
    /// callback or a delegate might be considered related.
    /// - **Associations:** Symbols that are part of the same module, class, or other structural code entity might be grouped together. For instance, members of a struct or class would be related
    /// to the class or struct symbol.
    /// - **Dependencies:** Symbols that rely on another symbol directly or indirectly. For example, functions that call another specific function.
    ///
    /// The query requires the ``IndexStore/SourceSymbol/usr`` value retreived from the provided symbol.
    /// ```
    /// class MyClass {}
    /// class Sample {
    ///
    ///     var myInstance: MyClass
    ///
    ///     init() {
    ///         myInstance = MyClass()
    ///     }
    /// }
    /// ```
    /// you can query as
    /// ```
    /// let classSymbol = indexStore.querySymbols(.classDeclarations(matching: "CustomClass"))[0]
    /// indexStore.queryRelatedOccurrences(ofSymbol: classSymbol, query: .withRoles([.definition, .childOf])) // var myInstance: MyClass
    /// indexStore.queryRelatedOccurrences(ofSymbol: classSymbol, query: .withRoles([.reference, .calledBy, .containedBy])) // myInstance = MyClass()
    /// indexStore.queryRelatedOccurrences(ofSymbol: classSymbol, query: .withRoles(.all)) // [var myInstance: MyClass, myInstance = MyClass()]
    /// ```
    /// - Parameters:
    ///   - symbol: The ``SourceSymbol`` to search with.
    ///   - query: The ``IndexStoreQuery`` to search with.
    ///   - recursiveSearchConfig: Configuration holding the recursive search strategies to use when searching for parents and inheritance.
    /// - Returns: `Array` of ``SourceSymbol`` objects.
    public func queryRelatedOccurrences(
        ofSymbol symbol: SourceSymbol,
        query: IndexStoreQuery
    ) -> [SourceSymbol] {
        queryRelatedOccurrences(ofUsr: symbol.usr, query: query)
    }

    @available(
      *,
      deprecated,
      renamed: "queryRelatedOccurrences(ofSymbol:query:)",
      message: "Use queryRelatedOccurrences(ofSymbol:query:) to fix the spelling of Occurrences"
    )
    public func queryRelatedOccurences(ofSymbol symbol: SourceSymbol, query: IndexStoreQuery) -> [SourceSymbol] {
        queryRelatedOccurrences(ofUsr: symbol.usr, query: query)
    }

    /// Will return source symbols that have a defined semantic or structural relation to the given symbol usr value.
    /// For example:
    /// - **Overrides:** If you're looking at a method in a base class, the related symbols could be methods in derived classes that override it.
    /// - **Implementations:** In the context of protocols or interfaces, related symbols might be the concrete implementations of those abstract methods or properties in conforming types.
    /// - **References:** This could be broader than direct usage, encompassing any symbol that has a semantic connection to the original one. For instance, a function that is passed as a
    /// callback or a delegate might be considered related.
    /// - **Associations:** Symbols that are part of the same module, class, or other structural code entity might be grouped together. For instance, members of a struct or class would be related
    /// to the class or struct symbol.
    /// - **Dependencies:** Symbols that rely on another symbol directly or indirectly. For example, functions that call another specific function.
    ///
    /// ```
    /// class MyClass {}
    /// class Sample {
    ///
    ///     var myInstance: MyClass
    ///
    ///     init() {
    ///         myInstance = MyClass()
    ///     }
    /// }
    /// ```
    /// you can query as
    /// ```
    /// let classSymbol = indexStore.querySymbols(.classDeclarations(matching: "CustomClass"))[0]
    /// indexStore.queryRelatedOccurrences(ofSymbol: classSymbol, query: .withRoles([.definition, .childOf])) // var myInstance: MyClass
    /// indexStore.queryRelatedOccurrences(ofSymbol: classSymbol, query: .withRoles([.reference, .calledBy, .containedBy])) // myInstance = MyClass()
    /// indexStore.queryRelatedOccurrences(ofSymbol: classSymbol, query: .withRoles(.all)) // [var myInstance: MyClass, myInstance = MyClass()]
    /// ```
    /// - Parameters:
    ///   - usr: The ``SourceSymbol/usr`` to search with.
    ///   - query: The ``IndexStoreQuery`` to search with.
    ///   - recursiveSearchConfig: Configuration holding the recursive search strategies to use when searching for parents and inheritance.
    /// - Returns: `Array` of ``SourceSymbol`` objects.
    public func queryRelatedOccurrences(
        ofUsr usr: String,
        query: IndexStoreQuery
    ) -> [SourceSymbol] {
        let symbolKinds = query.kinds.map(\.indexSymbolKind)
        let symbolRoles = SymbolRole(rawValue: query.roles.rawValue)
        let targetDirectory = query.restrictToProjectDirectory ? configuration.projectDirectory : nil
        let occurrences = workspace.occurrences(
            relatedToUSR: usr,
            matching: query.query,
            kinds: symbolKinds,
            roles: symbolRoles,
            anchorStart: query.anchorStart,
            anchorEnd: query.anchorEnd,
            includeSubsequence: query.includeSubsequence,
            ignoreCase: query.ignoreCase,
            restrictToLocation: targetDirectory,
            restrictedToSourceFiles: query.sourceFiles ?? [],
            module: query.module
        )
        let results = occurrences.compactMap {
            sourceSymbolFromOccurrence($0, recursiveSearchConfig: query.recursiveSearchConfig)
        }
        return results
    }

    @available(
      *,
      deprecated,
      renamed: "queryRelatedOccurrences(ofUsr:query:)",
      message: "Use queryRelatedOccurrences(ofUsr:query:) to fix the spelling of Occurrences"
    )
    public func queryRelatedOccurences(ofUsr usr: String, query: IndexStoreQuery) -> [SourceSymbol] {
        queryRelatedOccurrences(ofUsr: usr, query: query)
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
    /// - Parameters:
    ///   - occurrence: The occurrence to transform
    ///   - recursiveSearchConfig: Configuration holding the recursive search strategies to use when searching for parents and inheritance.
    /// - Returns: ``SourceSymbol``
    public func sourceSymbolFromOccurrence(_ occurrence: SymbolOccurrence, recursiveSearchConfig: RecursiveSearchConfiguration = .all) -> SourceSymbol {
        // Resolve source declaration kind
        let kind = SourceKind(symbolKind: occurrence.symbol.kind)
        // Source location
        let location = SourceLocation(symbol: occurrence)
        // Roles
        let roles = SourceRole(rawValue: occurrence.roles.rawValue)
        // Optional parent
        let nextParentConfig = recursiveSearchConfig.nextForParentRecursion()
        let parent: SourceSymbol? = {
            switch recursiveSearchConfig.parent {
            case .noSearching: nil
            default: resolveParentForOccurrence(occurrence, recursiveSearchConfig: nextParentConfig)
            }
        }()
        // Inheritance
        let nextInheritanceConfig = recursiveSearchConfig.nextForInheritanceRecursion()
        let inheritanceCollection: [SourceSymbol] = {
            switch recursiveSearchConfig.inheritance {
            case .noSearching: []
            default: resolveInheritanceForOccurrence(occurrence, recursiveSearchConfig: nextInheritanceConfig)
            }
        }()
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
    /// - Parameters:
    ///   - symbolOccurrence: The `SymbolOccurrence` to resolve for.
    ///   - recursiveSearchConfig: Configuration holding the recursive search strategies to use when searching for parents and inheritance.
    /// - Returns: ``SourceSymbol`` instance or `nil`
    public func resolveParentForOccurrence(
        _ symbolOccurrence: SymbolOccurrence,
        recursiveSearchConfig: RecursiveSearchConfiguration = .all
    ) -> SourceSymbol? {
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
        return sourceSymbolFromOccurrence(parentOccurrence, recursiveSearchConfig: recursiveSearchConfig)
    }

    /// Will resolve the source symbols representing the types the given occurrence conforms to or inherits from.
    /// - Parameters:
    ///   - symbolOccurrence: The `SymbolOccurrence` to resolve for.
    ///   - recursiveSearchConfig: Configuration holding the recursive search strategies to use when searching for parents and inheritance.
    /// - Returns: ``SourceSymbol`` instance or `nil`
    public func resolveInheritanceForOccurrence(
        _ occurrence: SymbolOccurrence,
        recursiveSearchConfig: RecursiveSearchConfiguration = .all
    ) -> [SourceSymbol] {
        guard !occurrence.location.isSystem else { return [] }
        let sourceKind = SourceKind(symbolKind: occurrence.symbol.kind)
        let validSourceKinds: [SourceKind] = [.protocol, .struct, .enum, .class]
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
            let details = sourceSymbolFromOccurrence(result, recursiveSearchConfig: recursiveSearchConfig)
            results.append(details)
        }
        return results
    }
}
