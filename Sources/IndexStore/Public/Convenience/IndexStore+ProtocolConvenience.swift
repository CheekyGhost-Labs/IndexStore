//
//  IndexStore+ProtocolConvenience.swift
//  
//
//  Created by Michael O'Brien on 29/4/2023.
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
                return workspace.occurrences(ofUSR: $0, roles: [.definition, .declaration])
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
        let conformingTypes: [SourceSymbol] = symbols.flatMap { symbol in
            let declarationSymbols = workspace.symbolsInSourceFiles(at: sourceFiles, roles: [.definition, .declaration])
            let validSymbols = declarationSymbols.filter { declaration in
                declaration.relations.contains(where: {
                    $0.symbol.usr == symbol.usr && $0.roles.contains(.baseOf)
                })
            }
            return validSymbols.compactMap(sourceSymbolFromOccurence)
        }
        return conformingTypes
    }
}
