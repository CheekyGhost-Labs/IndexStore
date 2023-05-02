//
//  IndexStore+InvocationConvenience.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Foundation
import IndexStoreDB
import TSCBasic

public extension IndexStore {
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
        let conforming = workspace.occurrences(ofUSR: symbol.usr, roles: [.calledBy, .write, .read])
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
        let haystack = invocationsOfSymbol(symbol)
        var testFunctionFound = false
        for result in haystack {
            var parent: SourceSymbol? = result.parent
            while parent != nil {
                // Check if the parent is a function that starts with `test` (unit testing convention)
                if let parent = parent, parent.name.starts(with: "test") {
                    testFunctionFound = true
                } else if testFunctionFound, let parent = parent, recursiveInheritenceCheck(symbol: parent, name: "XCTestCase") {
                    return true
                }
                parent = parent?.parent
            }
        }
        return false
    }

    /// Will recursively assess the inheritence stack of the given symbol and return `true` when the `name` property of an inherited symbol matches the given term.
    /// - Parameters:
    ///   - symbol: The symbol to assess.
    ///   - name: The name to match with.
    /// - Returns: `Bool`
    func recursiveInheritenceCheck(symbol: SourceSymbol, name: String) -> Bool {
        if symbol.inheritance.contains(where: { $0.name == name }) {
            return true
        }
        for inherited in symbol.inheritance where recursiveInheritenceCheck(symbol: inherited, name: name) {
            return true
        }
        return false
    }
}
