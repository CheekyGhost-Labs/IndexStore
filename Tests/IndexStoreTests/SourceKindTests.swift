//
//  SourceKindTests.swift
//  IndexStoreTests
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import IndexStoreDB
import XCTest

@testable import IndexStore

final class SourceKindTests: XCTestCase {

    // MARK: - Tests

    func test_convenienceGetters_willReturnExpectedValues() {
        XCTAssertEqual(
            SourceKind.excluding([.struct, .class, .enum]),
            [
                .unsupported,
                .module,
                .namespace,
                .namespaceAlias,
                .macro,
                .protocol,
                .extension,
                .union,
                .typealias,
                .function,
                .variable,
                .field,
                .enumConstant,
                .instanceMethod,
                .classMethod,
                .staticMethod,
                .instanceProperty,
                .classProperty,
                .staticProperty,
                .constructor,
                .destructor,
                .conversionFunction,
                .parameter,
                .using,
                .concept,
                .commentTag,
            ]
        )
    }

    func test_indexSymbolKind_willReturnExpectedValue() {
        let kinds = SourceKind.allCases
        // Ordered in SourceKind declaration order
        let symbols: [IndexSymbolKind] = [
            .unknown,
            .module,
            .namespace,
            .namespaceAlias,
            .macro,
            .enum,
            .struct,
            .class,
            .protocol,
            .extension,
            .union,
            .typealias,
            .function,
            .variable,
            .field,
            .enumConstant,
            .instanceMethod,
            .classMethod,
            .staticMethod,
            .instanceProperty,
            .classProperty,
            .staticProperty,
            .constructor,
            .destructor,
            .conversionFunction,
            .parameter,
            .using,
            .concept,
            .commentTag,
        ]
        for (index, kind) in kinds.enumerated() {
            XCTAssertEqual(kind.indexSymbolKind, symbols[index])
        }
    }

    func test_init_indexSymbolKind_willReturnExpectedValue() {
        // Ordered in SourceKind declaration order
        let symbols: [IndexSymbolKind] = [
            .unknown,
            .module,
            .namespace,
            .namespaceAlias,
            .macro,
            .enum,
            .struct,
            .class,
            .protocol,
            .extension,
            .union,
            .typealias,
            .function,
            .variable,
            .field,
            .enumConstant,
            .instanceMethod,
            .classMethod,
            .staticMethod,
            .instanceProperty,
            .classProperty,
            .staticProperty,
            .constructor,
            .destructor,
            .conversionFunction,
            .parameter,
            .using,
            .concept,
            .commentTag,
        ]
        let kinds: [SourceKind] = SourceKind.allCases
        for (index, symbol) in symbols.enumerated() {
            XCTAssertEqual(SourceKind(symbolKind: symbol), kinds[index])
        }
    }

    func test_unsupportedConvenienceGetter_willReturnExpectedValues() {
        let expected = SourceKind.allCases.filter { $0 != .unsupported }
        XCTAssertEqual(SourceKind.supported, expected)
    }
}
