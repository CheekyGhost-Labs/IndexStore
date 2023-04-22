//
//  IndexStoreTestCase.swift
//  IndexStoreTests
//
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import XCTest
import IndexStore

class IndexStoreTestCase: XCTestCase {

    // MARK: - Properties

    var instanceUnderTest: IndexStore!

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        try super.setUpWithError()
        let configuration = try loadDefaultConfiguration()
        instanceUnderTest = IndexStore(configuration: configuration, logger: .test)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        instanceUnderTest = nil
    }

    // MARK: - Helpers

    func loadDefaultConfiguration() throws -> Configuration {
        let configPath = "\(Bundle.module.resourcePath ?? "")/Configurations/test_configuration.json"
        let configUrl = URL(fileURLWithPath: configPath)
        let data = try Data(contentsOf: configUrl)
        let decoded = try JSONDecoder().decode(Configuration.self, from: data)
        return decoded
    }

    func pathSuffix(_ sourceName: String) -> String {
        "IndexStore/Tests/IndexStoreTests/Samples/\(sourceName)"
    }
}
