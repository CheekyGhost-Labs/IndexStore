//
//  IndexStatusControllerTests.swift
//  IndexStore
//
//  Created by Michael O'Brien on 3/3/2026.
//

import XCTest
@testable import IndexStoreDB
@testable import IndexStore

class IndexStoreDelegateSpy: IndexStoreDelegate {

    var indexStore_didUpdatePendingUnitCountCalled: Bool { indexStore_didUpdatePendingUnitCountCallCount > 0 }
    var indexStore_didUpdatePendingUnitCountCallCount: Int = 0
    var indexStore_didUpdatePendingUnitCountParameters: (store: IndexStore, pendingUnitCount: Int)? { indexStore_didUpdatePendingUnitCountParameterList.last }
    var indexStore_didUpdatePendingUnitCountParameterList: [(store: IndexStore, pendingUnitCount: Int)] = []

    func indexStore(_ store: IndexStore, didUpdatePendingUnitCount pendingUnitCount: Int) {
        indexStore_didUpdatePendingUnitCountCallCount += 1
        indexStore_didUpdatePendingUnitCountParameterList.append((store, pendingUnitCount))
    }

    var indexStore_didDetectOutOfDateUnitCalled: Bool { indexStore_didDetectOutOfDateUnitCallCount > 0 }
    var indexStore_didDetectOutOfDateUnitCallCount: Int = 0
    var indexStore_didDetectOutOfDateUnitParameters: (store: IndexStore, unit: UnitInfo)? { indexStore_didDetectOutOfDateUnitParameterList.last }
    var indexStore_didDetectOutOfDateUnitParameterList: [(store: IndexStore, unit: UnitInfo)] = []

    func indexStore(_ store: IndexStore, didDetectOutOfDateUnit unit: UnitInfo) {
        indexStore_didDetectOutOfDateUnitCallCount += 1
        indexStore_didDetectOutOfDateUnitParameterList.append((store, unit))
    }
}

final class IndexStatusControllerTests: XCTestCase {

    var delegateSpy: IndexStoreDelegateSpy!
    var indexStore: IndexStore!
    var instanceUnderTest: IndexStatusController!

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        try super.setUpWithError()
        let configPath = "\(Bundle.module.resourcePath ?? "")/Configurations/test_configuration.json"
        let configuration = try IndexStore.Configuration.fromJson(at: configPath)
        delegateSpy = .init()
        indexStore = IndexStore(configuration: configuration, autoLoadStore: false, logger: .test)
        instanceUnderTest = IndexStatusController(store: indexStore, delegate: delegateSpy)
        indexStore.statusController = instanceUnderTest
    }

    override func tearDownWithError() throws {
        delegateSpy = nil
        indexStore = nil
        instanceUnderTest = nil
    }

    // MARK: - Tests

    func test_isIndexing_willReturnExpectedFlag() {
        instanceUnderTest.state.pendingUnitCount = 0
        XCTAssertFalse(instanceUnderTest.isIndexing)
        XCTAssertEqual(indexStore.isIndexing, instanceUnderTest.isIndexing)
        instanceUnderTest.state.pendingUnitCount = 10
        XCTAssertTrue(instanceUnderTest.isIndexing)
        XCTAssertEqual(indexStore.isIndexing, instanceUnderTest.isIndexing)
    }

    func test_processingAddedPending_willIncreaseCount() {
        instanceUnderTest.state.pendingUnitCount = 1
        instanceUnderTest.processingAddedPending(123)
        XCTAssertEqual(instanceUnderTest.pendingUnitCount, 124)
        XCTAssertEqual(indexStore.pendingUnitCount, instanceUnderTest.pendingUnitCount)
    }

    func test_processingAddedPending_willUpdateLastPendingChange() {
        instanceUnderTest.state.lastPendingChangeTimestamp = nil
        instanceUnderTest.processingAddedPending(123)
        XCTAssertNotNil(instanceUnderTest.lastPendingChangeTimestamp)
        XCTAssertEqual(indexStore.lastPendingChangeTimestamp, instanceUnderTest.lastPendingChangeTimestamp)
    }

    func test_processingAddedPending_willNotifyDelegateOfCountChange() {
        instanceUnderTest.state.pendingUnitCount = 10
        instanceUnderTest.processingAddedPending(10)
        XCTAssertIdentical(delegateSpy.indexStore_didUpdatePendingUnitCountParameters?.store, indexStore)
        XCTAssertEqual(delegateSpy.indexStore_didUpdatePendingUnitCountParameters?.pendingUnitCount, 20)
    }

    func test_processingCompleted_willDecreaseCount() {
        instanceUnderTest.state.pendingUnitCount = 20
        instanceUnderTest.processingCompleted(10)
        XCTAssertEqual(instanceUnderTest.pendingUnitCount, 10)
        XCTAssertEqual(indexStore.pendingUnitCount, instanceUnderTest.pendingUnitCount)
    }

    func test_processingCompleted_willUpdateLastPendingChange() {
        instanceUnderTest.state.lastPendingChangeTimestamp = nil
        instanceUnderTest.processingAddedPending(123)
        XCTAssertNotNil(instanceUnderTest.lastPendingChangeTimestamp)
        XCTAssertEqual(indexStore.lastPendingChangeTimestamp, instanceUnderTest.lastPendingChangeTimestamp)
    }

    func test_processingCompleted_willNotifyDelegateOfCountChange() {
        instanceUnderTest.state.pendingUnitCount = 20
        instanceUnderTest.processingCompleted(10)
        XCTAssertEqual(delegateSpy.indexStore_didUpdatePendingUnitCountCallCount, 1)
        XCTAssertIdentical(delegateSpy.indexStore_didUpdatePendingUnitCountParameters?.store, indexStore)
        XCTAssertEqual(delegateSpy.indexStore_didUpdatePendingUnitCountParameters?.pendingUnitCount, 10)
    }

    func test_unitIsOutOfDate_willAssignExpectedInfo() {
        instanceUnderTest.state.lastOutOfDateTimestamp = nil
        instanceUnderTest.state.lastOutOfDateUnit = nil
        instanceUnderTest.unitIsOutOfDate(
            StoreUnitInfo.init(mainFilePath: "main-path", unitName: "unit-name"),
            outOfDateModTime: 1234,
            triggerHintFile: "hint",
            triggerHintDescription: "hint-desc",
            synchronous: true
        )
        let expected = UnitInfo(
            mainFilePath: "main-path",
            unitName: "unit-name",
            outOfDateModTime: 1234,
            triggerHintFile: "hint",
            triggerHintDescription: "hint-desc",
            synchronous: true
        )
        XCTAssertEqual(instanceUnderTest.lastOutOfDateUnit, expected)
        XCTAssertNotNil(instanceUnderTest.lastOutOfDateTimestamp)
    }

    func test_unitIsOutOfDate_willNotifyDelegateInfo() {
        instanceUnderTest.state.lastOutOfDateTimestamp = nil
        instanceUnderTest.state.lastOutOfDateUnit = nil
        instanceUnderTest.unitIsOutOfDate(
            StoreUnitInfo.init(mainFilePath: "main-path", unitName: "unit-name"),
            outOfDateModTime: 1234,
            triggerHintFile: "hint",
            triggerHintDescription: "hint-desc",
            synchronous: false
        )
        let expected = UnitInfo(
            mainFilePath: "main-path",
            unitName: "unit-name",
            outOfDateModTime: 1234,
            triggerHintFile: "hint",
            triggerHintDescription: "hint-desc",
            synchronous: false
        )
        XCTAssertEqual(delegateSpy.indexStore_didDetectOutOfDateUnitCallCount, 1)
        XCTAssertIdentical(delegateSpy.indexStore_didDetectOutOfDateUnitParameters?.store, indexStore)
        XCTAssertEqual(delegateSpy.indexStore_didDetectOutOfDateUnitParameters?.unit, expected)
    }
}
