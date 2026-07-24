//
//  WorkspaceTests.swift
//  IndexStore
//
//  Created by Michael O'Brien on 24/7/2026.
//

import XCTest

@testable import IndexStore

final class WorkspaceTests: XCTestCase {

    // MARK: - Tests: ListenToUnitTests

    func test_init_configuration_listenToUnitEventsTrue_isRunningInTestsTrue_willAssignFalse() throws {
        let configuration = try IndexStore.Configuration(projectDirectory: "test-dir", listenToUnitEvents: true, isRunningUnitTests: true)
        let storeInstance = IndexStore(configuration: configuration)
        let instanceUnderTest = Workspace(configuration: configuration, delegate: nil, logger: storeInstance.logger)
        XCTAssertFalse(instanceUnderTest.listenToUnitEvents)
    }

    func test_init_configuration_listenToUnitEventsFalse_isRunningInTestsFalse_willAssignFalse() throws {
        let configuration = try IndexStore.Configuration(projectDirectory: "test-dir", listenToUnitEvents: false, isRunningUnitTests: false)
        let storeInstance = IndexStore(configuration: configuration)
        let instanceUnderTest = Workspace(configuration: configuration, delegate: nil, logger: storeInstance.logger)
        XCTAssertFalse(instanceUnderTest.listenToUnitEvents)
    }

    func test_init_configuration_listenToUnitEventsTrue_isRunningInTestsFalse_willAssignTrue() throws {
        let configuration = try IndexStore.Configuration(projectDirectory: "test-dir", listenToUnitEvents: true, isRunningUnitTests: false)
        let storeInstance = IndexStore(configuration: configuration)
        let instanceUnderTest = Workspace(configuration: configuration, delegate: nil, logger: storeInstance.logger)
        XCTAssertTrue(instanceUnderTest.listenToUnitEvents)
    }

    func test_init_manual_listenToUnitEventsTrue_isRunningInTestsTrue_willAssignProvidedFalse() throws {
        let configuration = try IndexStore.Configuration(projectDirectory: "test-dir", listenToUnitEvents: true, isRunningUnitTests: false)
        let storeInstance = IndexStore(configuration: configuration)
        let instanceUnderTest = Workspace(
            libIndexStorePath: "",
            projectDirectory: "",
            indexStorePath: "",
            indexDatabasePath: "",
            listenToUnitEvents: true,
            delegate: nil,
            logger: storeInstance.logger
        )
        XCTAssertFalse(instanceUnderTest.listenToUnitEvents)
    }

    func test_init_manual_listenToUnitEventsTrue_isRunningInTestsFalse_willAssignProvided() throws {
        // Remove XCTestConfigurationFilePath so resolveIsRunningTests() returns false
        let envKey = "XCTestConfigurationFilePath"
        let originalValue = ProcessInfo.processInfo.environment[envKey]
        unsetenv(envKey)
        defer {
            if let originalValue {
                setenv(envKey, originalValue, 1)
            }
        }
        let configuration = try IndexStore.Configuration(projectDirectory: "test-dir", listenToUnitEvents: true, isRunningUnitTests: false)
        let storeInstance = IndexStore(configuration: configuration)
        let instanceUnderTest = Workspace(
            libIndexStorePath: "",
            projectDirectory: "",
            indexStorePath: "",
            indexDatabasePath: "",
            listenToUnitEvents: true,
            delegate: nil,
            logger: storeInstance.logger
        )
        XCTAssertTrue(instanceUnderTest.listenToUnitEvents)
    }

    func test_init_manual_listenToUnitEventsFalse_isRunningInTestsFalse_willAssignProvided() throws {
        // Remove XCTestConfigurationFilePath so resolveIsRunningTests() returns false
        let envKey = "XCTestConfigurationFilePath"
        let originalValue = ProcessInfo.processInfo.environment[envKey]
        unsetenv(envKey)
        defer {
            if let originalValue {
                setenv(envKey, originalValue, 1)
            }
        }
        let configuration = try IndexStore.Configuration(projectDirectory: "test-dir", listenToUnitEvents: true, isRunningUnitTests: false)
        let storeInstance = IndexStore(configuration: configuration)
        let instanceUnderTest = Workspace(
            libIndexStorePath: "",
            projectDirectory: "",
            indexStorePath: "",
            indexDatabasePath: "",
            listenToUnitEvents: false,
            delegate: nil,
            logger: storeInstance.logger
        )
        XCTAssertFalse(instanceUnderTest.listenToUnitEvents)
    }
}
