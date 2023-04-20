//
//  SourceKindTests.swift
//  IndexStoreTests
//
//  Created by CheekyGhost Labs on 19/4/2023.
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import IndexStoreDB
import XCTest
@testable import IndexStore

final class SourceKindTests: XCTestCase {

    // MARK: - Tests

//    func test_convenienceGetters_willReturnExpectedValues() {
//        XCTAssertEqual(
//            SourceKind.excludingExtensions,
//            [.class, .struct, .enum, .protocol, .typealias, .unsupported])
//        XCTAssertEqual(
//            SourceKind.excludingUnsupported,
//            [.class, .struct, .enum, .protocol, .typealias, .extension])
//    }

    func test_indexSymbolKind_willReturnExpectedValue() {
        let kinds = SourceKind.allCases
        // Ordered in SourceKind declaration order
        let symbols: [IndexSymbolKind] = [
            .class, .struct, .enum, .protocol, .typealias, .extension, .unknown,
        ]
        for (index, kind) in kinds.enumerated() {
            XCTAssertEqual(kind.indexSymbolKind, symbols[index])
        }
    }

    func test_init_indexSymbolKind_willReturnExpectedValue() {
        // Ordered in SourceKind declaration order
        let symbols: [IndexSymbolKind] = [
            .class, .struct, .enum, .protocol, .typealias, .extension, .function,
        ]
        var kinds: [SourceKind?] = SourceKind.allCases
        kinds.append(nil)
        for (index, symbol) in symbols.enumerated() {
            XCTAssertEqual(SourceKind(symbolKind: symbol), kinds[index])
        }
    }
}
