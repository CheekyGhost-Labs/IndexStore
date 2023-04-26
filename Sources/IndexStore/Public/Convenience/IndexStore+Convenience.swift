//
//  File.swift
//  
//
//  Created by Michael O'Brien on 21/4/2023.
//

import Foundation
import IndexStoreDB

public extension IndexStore {

    // MARK: - Convenience: Extensions

    /// Will return any source symbols for any **empty** extensions on types matching the given query.
    ///
    /// **Note: ** The provided query will have the `kinds` and `roles` modified to enable the search.
    /// - Parameter query: The query to search with.
    /// - Returns: Array of ``SourceSymbol`` instances
    func sourceSymbols(forEmptyExtensionsMatching query: IndexStoreQuery) -> [SourceSymbol] {
        let symbols = querySymbols(query)
        var results: [SourceSymbol] = []
        symbols.forEach {
            let references = workspace.occurrences(ofUSR: $0.usr, roles: [.reference])
            references.forEach { reference in
                guard reference.roles.contains([.reference]) && reference.relations.isEmpty else { return }
                var details = sourceSymbolFromOccurence(reference)
                details.sourceKind = .`extension`
                results.append(details)
            }
        }
        return results
    }

    // MARK: - Convenience: Invocations

    /// Will return source symbols that invoke the given symbol function.
    ///
    /// **Note: ** Valid symbols are the following ``SourceKind`` cases:
    /// - ``SourceKind/instanceMethod``
    /// - ``SourceKind/variable``
    /// - ``SourceKind/staticMethod``
    /// - ``SourceKind/staticProperty``
    /// - ``SourceKind/classMethod``
    /// - ``SourceKind/classProperty``
    /// - Parameter symbol: The symbol occurrence to assess
    /// - Returns: Array of `SourceSymbol` instances
    func invocationsOfSymbol(_ symbol: SourceSymbol) -> [SourceSymbol] {
        let validSourceKinds: [SourceKind] = SourceKind.allFunctions + SourceKind.properties
        guard validSourceKinds.contains(symbol.sourceKind) else {
            logger.warning("symbol with kind `\(symbol.sourceKind) is not valid for this method. Returning empty results.")
            return []
        }
        var results: [SourceSymbol] = []
        let conforming = workspace.occurrences(ofUSR: symbol.usr, roles: [.receivedBy, .calledBy])
        for symbol in conforming {
            let sourceSymbol = sourceSymbolFromOccurence(symbol)
            results.append(sourceSymbol)
        }
        return results
    }

    /// Will assess the symbol's parent and inheritence heirachy and return true when it is being invoked within a test case within an `XCTestCase` class (or subclass).
    ///
    /// **Note: ** Valid symbols are the following ``SourceKind`` cases:
    /// - ``SourceKind/instanceMethod``
    /// - ``SourceKind/function``
    /// - ``SourceKind/variable``
    /// - ``SourceKind/staticMethod``
    /// - ``SourceKind/staticProperty``
    /// - ``SourceKind/classMethod``
    /// - ``SourceKind/classProperty``
    /// - Parameter symbol: The symbol occurrence to assess
    /// - Returns: `Bool`
    func isSymbolInvokedByTestCase(_ symbol: SourceSymbol) -> Bool {
        let validSourceKinds: [SourceKind] = SourceKind.allFunctions + SourceKind.properties
        guard validSourceKinds.contains(symbol.sourceKind) else {
            logger.warning("symbol with kind `\(symbol.sourceKind) is not valid for this method. Returning empty results.")
            return false
        }
        let conforming = workspace.occurrences(ofUSR: symbol.usr, roles: [.calledBy])
        let haystack = conforming.map(sourceSymbolFromOccurence)
        var testFunctionFound: Bool = false
        for result in haystack {
            var parent: SourceSymbol? = result.parent
            while parent != nil {
                // Check if the parent is a function that starts with `test` (unit testing convention)
                if let parent, parent.name.starts(with: "test") {
                    testFunctionFound = true
                } else if testFunctionFound, let parent, parent.inheritance.contains(where: { $0.name == "XCTestCase" }) {
                    return true
                }
                parent = parent?.parent
            }
        }
        return false
    }

    // MARK: - Convenience: Protocols

    /// Will search for protocols that match the given protocol name, then resolve any source symbols  for declarations that conform to the given protocol.
    /// - Parameter protocolName: The name of the protocol to search for.
    /// - Returns: Array of ``SourceSymbol``
    func sourceSymbols(conformingToProtocol protocolName: String) -> [SourceSymbol] {
        let query = IndexStoreQuery.protocolDeclarations(matching: protocolName).withIgnoringCase(true)
        let symbols = querySymbols(query)
        return resolveSymbolsConformingToProtocolSymbols(symbols)
    }

    /// Will search for protocols that match the given protocol name, then resolve any source symbols  for declarations that conform to the given protocol.
    /// - Parameters:
    ///   - protocolName: The name of the protocol to search for.
    ///   - sourceFiles: The source files to search in.
    /// - Returns: Array of ``SourceSymbol``
    func sourceSymbols(conformingToProtocol protocolName: String, in sourceFiles: [String]) -> [SourceSymbol] {
        let query = IndexStoreQuery.protocolDeclarations(matching: protocolName).withSourceFiles(sourceFiles).withIgnoringCase(true)
        let symbols = querySymbols(query)
        return resolveSymbolsConformingToProtocolSymbols(symbols)
    }

    /// Performs the symbol lookups to find symbols conforming to protocols in the given array.
    /// - Parameter symbols: The symbols to search for.
    /// - Returns: Array of ``SourceSymbol`` instances
    internal func resolveSymbolsConformingToProtocolSymbols(_ symbols: [SourceSymbol]) -> [SourceSymbol] {
        let conformingTypes: [SourceSymbol] = symbols.flatMap {
            let conforming = workspace.occurrences(ofUSR: $0.usr, roles: [.reference, .baseOf])
            let validUsrs: [String] = conforming.flatMap {
                guard $0.roles == [.reference, .baseOf] else {
                    return [String]()
                }
                return $0.relations.map(\.symbol.usr)
            }
            let occurances = validUsrs.flatMap {
                return workspace.occurrences(ofUSR: $0, roles: [.definition])
            }
            return occurances.compactMap(sourceSymbolFromOccurence)
        }
        return conformingTypes
    }
}
