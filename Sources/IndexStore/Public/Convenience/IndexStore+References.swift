//
//  IndexStore+References.swift
//
//
//  Created by Michael O'Brien on 6/6/2023.
//

import Foundation
import IndexStoreDB
import TSCBasic

public extension IndexStore {
    /// Will return propery declaration symbol occurrences of the resolved type of the given symbol.
    ///
    /// for example, in the following source
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
    /// indexStore.sourceSymbols(forPropertiesWithTypeOf: classSymbol) // [var myInstance: MyClass]
    /// ```
    /// - Parameter symbol: The symbol to search with.
    /// - Returns: `Array` of ``SourceSymbol`` objects.
    func sourceSymbols(forPropertiesWithTypeOf symbol: SourceSymbol) -> [SourceSymbol] {
        let symbolKinds = SourceKind.properties.map(\.indexSymbolKind)
        // Resolve valid occurrences based on roles
        let rawResults = workspace.occurrences(ofUSR: symbol.usr, roles: [.reference, .containedBy])
        let baseOccurences = rawResults.map(sourceSymbolFromOccurrence)
        // Grab the property parents of valid occurrences
        let validOccurences: [SourceSymbol] = baseOccurences.compactMap {
            guard
                let parent = $0.parent,
                workspace.validateKind(parent.sourceKind.indexSymbolKind, kinds: symbolKinds, canIgnore: false)
            else {
                return nil
            }
            return parent
        }
        return validOccurences
    }

    /// Will return propery declaration symbol occurrences of the resolved type of the given symbol within the given source files.
    ///
    /// for example, in the following source
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
    /// indexStore.sourceSymbols(forPropertiesWithTypeOf: classSymbol) // [var myInstance: MyClass]
    /// ```
    /// - Parameters:
    ///   - symbol: The symbol to search with.
    ///   - sourceFiles: Array of source files to search in.
    /// - Returns: `Array` of ``SourceSymbol`` objects.
    func sourceSymbols(forPropertiesWithTypeOf symbol: SourceSymbol, in sourceFiles: [String]) -> [SourceSymbol] {
        let results = sourceSymbols(forPropertiesWithTypeOf: symbol)
        return results.filter { sourceFiles.contains($0.location.path) }
    }
}
