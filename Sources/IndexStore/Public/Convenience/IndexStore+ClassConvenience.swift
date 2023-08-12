//
//  IndexStore+ClassConvenience.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Foundation
import TSCBasic

extension IndexStore {
    // MARK: - Convenience: Classes

    /// Will search for classes that match the given class name, then resolve any source symbols for declarations that subclass the given class.
    /// - Parameter className: The name of the class to search for.
    /// - Returns: Array of ``SourceSymbol``
    public func sourceSymbols(subclassing className: String) -> [SourceSymbol] {
        // Find classes or declarations (objc class interface) matching the type.
        let query = IndexStoreQuery.classDeclarations(matching: className)
            .withIgnoringCase(true)
            .withRoles([.definition, .declaration])
            .withRestrictingToProjectDirectory(false)
        let symbols = querySymbols(query)
        // Resolve symbols conforming to the matches
        return resolveSymbolsSubclassingClassSymbols(symbols)
    }

    /// Will search for classes that match the given class name, then resolve any source symbols for declarations that subclass the given class.
    /// - Parameters:
    ///   - className: The name of the class to search for.
    ///   - sourceFiles: The source files to search in.
    /// - Returns: Array of ``SourceSymbol``
    public func sourceSymbols(subclassing className: String, in sourceFiles: [String]) -> [SourceSymbol] {
        // Resolve symbols for the given class name within the given source files
        let query = IndexStoreQuery.classDeclarations(matching: className)
            .withIgnoringCase(true)
            .withRoles([.definition, .declaration])
            .withRestrictingToProjectDirectory(false)
        let symbols = querySymbols(query)
        // Resolve symbols conforming to the matches within the source files
        return resolveSymbolsSubclassingClassSymbols(symbols, in: sourceFiles)
    }

    /// Performs the symbol lookups to find symbols subclassing the given class symbols.
    /// - Parameter symbols: The symbols to search for.
    /// - Returns: Array of ``SourceSymbol`` instances
    internal func resolveSymbolsSubclassingClassSymbols(_ symbols: [SourceSymbol]) -> [SourceSymbol] {
        var results: OrderedSet<SourceSymbol> = []
        symbols.forEach {
            let subclasses = workspace.occurrences(ofUSR: $0.usr, roles: [.baseOf])
            var validUSRs: [String] = []
            subclasses.forEach {
                guard
                    // Restrict to symbols in project directory
                    $0.location.path.contains(configuration.projectDirectory),
                    $0.roles == [.reference, .baseOf]
                else {
                    return
                }
                let usrs = $0.relations.map(\.symbol.usr)
                validUSRs.append(contentsOf: usrs)
            }
            let occurrences = validUSRs.flatMap {
                workspace.occurrences(ofUSR: $0, roles: [.definition, .declaration])
            }
            occurrences.forEach { occurrence in
                // Limiting to usr rather than equatable/hashable within set some classes have objc declarations
                guard !results.contains(where: { $0.usr == occurrence.symbol.usr }) else {
                    return
                }
                let symbol = sourceSymbolFromOccurrence(occurrence)
                results.append(symbol)
            }
        }
        return results.contents
    }

    /// Performs the symbol lookups to find symbols subclassing the given class symbols.
    /// - Parameters:
    ///   - symbols: The symbols to search for.
    ///   - sourceFiles: The source files to search in.
    /// - Returns: Array of ``SourceSymbol``
    internal func resolveSymbolsSubclassingClassSymbols(_ symbols: [SourceSymbol], in sourceFiles: [String]) -> [SourceSymbol] {
        var results: OrderedSet<SourceSymbol> = []
        symbols.forEach { symbol in
            let baseOfRelations = workspace.occurrences(ofUSR: symbol.usr, roles: [.baseOf]).flatMap(\.relations)
            let declarationSymbols = workspace.symbolsInSourceFiles(at: sourceFiles, roles: [.definition, .declaration])
            declarationSymbols.forEach { declaration in
                guard baseOfRelations.contains(where: { $0.symbol.usr == declaration.symbol.usr }) else { return }
                let sourceSymbol = sourceSymbolFromOccurrence(declaration)
                results.append(sourceSymbol)
            }
        }
        return results.contents
    }
}
