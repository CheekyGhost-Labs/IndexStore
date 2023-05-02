//
//  IndexStore+ProtocolConvenience.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Foundation
import TSCBasic

extension IndexStore {
    // MARK: - Convenience: Protocols

    /// Will search for protocols that match the given protocol name, then resolve any source symbols for declarations that conform to the given protocol.
    /// - Parameter protocolName: The name of the protocol to search for.
    /// - Returns: Array of ``SourceSymbol``
    public func sourceSymbols(conformingToProtocol protocolName: String) -> [SourceSymbol] {
        // Find any matching protocol symbols
        let query = IndexStoreQuery.protocolDeclarations(matching: protocolName)
            .withIgnoringCase(true)
            .withRestrictingToProjectDirectory(false)
        let symbols = querySymbols(query)
        // Resolve conforming instances
        return resolveSymbolsConformingToProtocolSymbols(symbols)
    }

    /// Will search for protocols that match the given protocol name, then resolve any source symbols for declarations that conform to the given protocol within the given source files.
    /// - Parameters:
    ///   - protocolName: The name of the protocol to search for.
    ///   - sourceFiles: The source files to search in.
    /// - Returns: Array of ``SourceSymbol``
    public func sourceSymbols(conformingToProtocol protocolName: String, in sourceFiles: [String]) -> [SourceSymbol] {
        // Find any matching protocol symbols
        let query = IndexStoreQuery.protocolDeclarations(matching: protocolName)
            .withIgnoringCase(true)
            .withRestrictingToProjectDirectory(false)
        let symbols = querySymbols(query)
        // Find any matching protocol symbols within the given source files
        return resolveSymbolsConformingToProtocolSymbols(symbols, in: sourceFiles)
    }

    /// Performs the symbol lookups to find symbols conforming to protocols in the given array.
    /// - Parameter symbols: The symbols to search for.
    /// - Returns: Array of ``SourceSymbol`` instances
    internal func resolveSymbolsConformingToProtocolSymbols(_ symbols: [SourceSymbol]) -> [SourceSymbol] {
        var results: OrderedSet<SourceSymbol> = []
        symbols.forEach {
            let subclasses = workspace.occurrences(ofUSR: $0.usr, roles: [.baseOf])
            let validUsrs: [String] = subclasses.flatMap {
                guard
                    // Restrict to symbols in project directory
                    $0.location.path.contains(configuration.projectDirectory),
                    $0.roles == [.reference, .baseOf]
                else {
                    return [String]()
                }
                return $0.relations.map(\.symbol.usr)
            }
            let occurances = validUsrs.flatMap {
                workspace.occurrences(ofUSR: $0, roles: [.definition, .declaration])
            }
            occurances.forEach { occurence in
                // Limiting to usr rather than equatable/hashable within set some classes have objc declarations
                guard !results.contains(where: { $0.usr == occurence.symbol.usr }) else {
                    return
                }
                let symbol = sourceSymbolFromOccurence(occurence)
                results.append(symbol)
            }
        }
        return results.contents
    }

    /// Performs the symbol lookups to find symbols within the given source files that contain a `.baseOf` relationship to the usr in the given symbols array.
    /// - Parameters:
    ///   - symbols: The symbols to for.
    ///   - sourceFiles: The source files to search in.
    /// - Returns: Array of ``SourceSymbole`` instances
    internal func resolveSymbolsConformingToProtocolSymbols(_ symbols: [SourceSymbol], in sourceFiles: [String]) -> [SourceSymbol] {
        var results: OrderedSet<SourceSymbol> = []
        symbols.forEach { symbol in
            let baseOfRelations = workspace.occurrences(ofUSR: symbol.usr, roles: [.baseOf]).flatMap(\.relations)
            let declarationSymbols = workspace.symbolsInSourceFiles(at: sourceFiles, roles: [.definition, .declaration])
            declarationSymbols.forEach { declaration in
                guard baseOfRelations.contains(where: { $0.symbol.usr == declaration.symbol.usr }) else { return }
                let sourceSymbol = sourceSymbolFromOccurence(declaration)
                results.append(sourceSymbol)
            }
        }
        return results.contents
    }
}
