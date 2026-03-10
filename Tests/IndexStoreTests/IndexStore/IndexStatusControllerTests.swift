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

    var indexStore_didUpdateTrackedUnitStatusCalled: Bool { indexStore_didUpdateTrackedUnitStatusCallCount > 0 }
    var indexStore_didUpdateTrackedUnitStatusCallCount: Int = 0
    var indexStore_didUpdateTrackedUnitStatusParameters: (store: IndexStore, trackedUnit: TrackedUnit)? { indexStore_didUpdateTrackedUnitStatusParameterList.last }
    var indexStore_didUpdateTrackedUnitStatusParameterList: [(store: IndexStore, trackedUnit: TrackedUnit)] = []

    func indexStore(_ store: IndexStore, didUpdateTrackedUnitStatus trackedUnit: TrackedUnit) {
        indexStore_didUpdateTrackedUnitStatusCallCount += 1
        indexStore_didUpdateTrackedUnitStatusParameterList.append((store, trackedUnit))
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

    // MARK: - Tests: Tracked Unit Lifecycle

    func test_hasOutOfDateUnits_returnsFalseWhenEmpty() {
        XCTAssertFalse(instanceUnderTest.hasOutOfDateUnits)
        XCTAssertFalse(indexStore.hasOutOfDateUnits)
    }

    func test_hasOutOfDateUnits_returnsTrueWhenOutOfDateUnitsExist() {
        reportOutOfDateUnit(mainFilePath: "pathA", unitName: "unitA")
        XCTAssertTrue(instanceUnderTest.hasOutOfDateUnits)
        XCTAssertTrue(indexStore.hasOutOfDateUnits)
    }

    func test_hasOutOfDateUnits_returnsFalseWhenAllProcessed() {
        reportOutOfDateUnit(mainFilePath: "pathA", unitName: "unitA")
        instanceUnderTest.markUnitsProcessing(["unitA"])
        instanceUnderTest.markUnitsProcessed(["unitA"])
        XCTAssertFalse(instanceUnderTest.hasOutOfDateUnits)
        XCTAssertFalse(indexStore.hasOutOfDateUnits)
    }

    func test_unitIsOutOfDate_tracksMultipleUnits() {
        reportOutOfDateUnit(mainFilePath: "pathA", unitName: "unitA")
        reportOutOfDateUnit(mainFilePath: "pathB", unitName: "unitB")
        reportOutOfDateUnit(mainFilePath: "pathC", unitName: "unitC")

        let tracked = instanceUnderTest.allTrackedUnits
        XCTAssertEqual(tracked.count, 3)
        let names = Set(tracked.map(\.unit.unitName))
        XCTAssertEqual(names, ["unitA", "unitB", "unitC"])
        XCTAssertTrue(tracked.allSatisfy { $0.status == .outOfDate })
    }

    func test_unitIsOutOfDate_updatesExistingUnit() {
        reportOutOfDateUnit(mainFilePath: "pathA", unitName: "unitA", outOfDateModTime: 100)
        reportOutOfDateUnit(mainFilePath: "pathA-updated", unitName: "unitA", outOfDateModTime: 200)

        let tracked = instanceUnderTest.allTrackedUnits
        XCTAssertEqual(tracked.count, 1)
        let entry = tracked.first
        XCTAssertEqual(entry?.unit.unitName, "unitA")
        XCTAssertEqual(entry?.unit.mainFilePath, "pathA-updated")
        XCTAssertEqual(entry?.unit.outOfDateModTime, 200)
        XCTAssertEqual(entry?.status, .outOfDate)
    }

    func test_markUnitsProcessing_transitionsCorrectUnits() {
        reportOutOfDateUnit(mainFilePath: "pathA", unitName: "unitA")
        reportOutOfDateUnit(mainFilePath: "pathB", unitName: "unitB")
        reportOutOfDateUnit(mainFilePath: "pathC", unitName: "unitC")

        let result = instanceUnderTest.markUnitsProcessing(["unitA", "unitC"])
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.status == .processing })

        let all = instanceUnderTest.allTrackedUnits
        let processingNames = Set(all.filter { $0.status == .processing }.map(\.unit.unitName))
        let outOfDateNames = Set(all.filter { $0.status == .outOfDate }.map(\.unit.unitName))
        XCTAssertEqual(processingNames, ["unitA", "unitC"])
        XCTAssertEqual(outOfDateNames, ["unitB"])
    }

    func test_markUnitsProcessing_ignoresNonOutOfDateUnits() {
        reportOutOfDateUnit(mainFilePath: "pathA", unitName: "unitA")
        instanceUnderTest.markUnitsProcessing(["unitA"])
        // unitA is now .processing — calling again should not re-transition
        let result = instanceUnderTest.markUnitsProcessing(["unitA"])
        XCTAssertTrue(result.isEmpty)
    }

    func test_markUnitsProcessed_transitionsCorrectUnits() {
        reportOutOfDateUnit(mainFilePath: "pathA", unitName: "unitA")
        reportOutOfDateUnit(mainFilePath: "pathB", unitName: "unitB")
        instanceUnderTest.markUnitsProcessing(["unitA", "unitB"])

        let result = instanceUnderTest.markUnitsProcessed(["unitA"])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.unit.unitName, "unitA")
        XCTAssertEqual(result.first?.status, .processed)

        let all = instanceUnderTest.allTrackedUnits
        let processed = all.first { $0.unit.unitName == "unitA" }
        let stillProcessing = all.first { $0.unit.unitName == "unitB" }
        XCTAssertEqual(processed?.status, .processed)
        XCTAssertEqual(stillProcessing?.status, .processing)
    }

    func test_markUnitsProcessed_ignoresNonProcessingUnits() {
        reportOutOfDateUnit(mainFilePath: "pathA", unitName: "unitA")
        // unitA is .outOfDate — cannot skip to .processed
        let result = instanceUnderTest.markUnitsProcessed(["unitA"])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(instanceUnderTest.allTrackedUnits.first?.status, .outOfDate)
    }

    func test_outOfDateUnits_filtersCorrectly() {
        reportOutOfDateUnit(mainFilePath: "pathA", unitName: "unitA")
        reportOutOfDateUnit(mainFilePath: "pathB", unitName: "unitB")
        reportOutOfDateUnit(mainFilePath: "pathC", unitName: "unitC")
        instanceUnderTest.markUnitsProcessing(["unitB"])
        instanceUnderTest.markUnitsProcessed(["unitB"])

        let outOfDate = instanceUnderTest.outOfDateUnits
        let names = Set(outOfDate.map(\.unit.unitName))
        XCTAssertEqual(names, ["unitA", "unitC"])
    }

    func test_clearProcessedUnits_removesOnlyProcessed() {
        reportOutOfDateUnit(mainFilePath: "pathA", unitName: "unitA")
        reportOutOfDateUnit(mainFilePath: "pathB", unitName: "unitB")
        reportOutOfDateUnit(mainFilePath: "pathC", unitName: "unitC")
        instanceUnderTest.markUnitsProcessing(["unitA"])
        instanceUnderTest.markUnitsProcessed(["unitA"])

        instanceUnderTest.clearProcessedUnits()

        let all = instanceUnderTest.allTrackedUnits
        XCTAssertEqual(all.count, 2)
        let names = Set(all.map(\.unit.unitName))
        XCTAssertEqual(names, ["unitB", "unitC"])
    }

    func test_clearAllTrackedUnits_removesEverything() {
        reportOutOfDateUnit(mainFilePath: "pathA", unitName: "unitA")
        reportOutOfDateUnit(mainFilePath: "pathB", unitName: "unitB")
        instanceUnderTest.markUnitsProcessing(["unitA"])

        instanceUnderTest.clearAllTrackedUnits()

        XCTAssertTrue(instanceUnderTest.allTrackedUnits.isEmpty)
    }

    func test_statusTransitions_notifyDelegate() {
        // Reset the spy count (unitIsOutOfDate also fires a notification)
        delegateSpy.indexStore_didUpdateTrackedUnitStatusCallCount = 0
        delegateSpy.indexStore_didUpdateTrackedUnitStatusParameterList.removeAll()

        reportOutOfDateUnit(mainFilePath: "pathA", unitName: "unitA")
        // 1 notification: outOfDate
        XCTAssertEqual(delegateSpy.indexStore_didUpdateTrackedUnitStatusCallCount, 1)
        XCTAssertEqual(delegateSpy.indexStore_didUpdateTrackedUnitStatusParameterList.last?.trackedUnit.status, .outOfDate)

        instanceUnderTest.markUnitsProcessing(["unitA"])
        // 2 notifications total: outOfDate + processing
        XCTAssertEqual(delegateSpy.indexStore_didUpdateTrackedUnitStatusCallCount, 2)
        XCTAssertEqual(delegateSpy.indexStore_didUpdateTrackedUnitStatusParameterList.last?.trackedUnit.status, .processing)

        instanceUnderTest.markUnitsProcessed(["unitA"])
        // 3 notifications total: outOfDate + processing + processed
        XCTAssertEqual(delegateSpy.indexStore_didUpdateTrackedUnitStatusCallCount, 3)
        XCTAssertEqual(delegateSpy.indexStore_didUpdateTrackedUnitStatusParameterList.last?.trackedUnit.status, .processed)

        // All delegate calls should reference the correct store
        XCTAssertTrue(delegateSpy.indexStore_didUpdateTrackedUnitStatusParameterList.allSatisfy { $0.store === indexStore })
    }

    func test_indexStore_outOfDateUnits_proxiesToController() {
        reportOutOfDateUnit(mainFilePath: "pathA", unitName: "unitA")
        XCTAssertEqual(indexStore.outOfDateUnits.count, instanceUnderTest.outOfDateUnits.count)
        XCTAssertEqual(indexStore.outOfDateUnits.first?.unit.unitName, "unitA")
    }

    func test_indexStore_trackedUnits_proxiesToController() {
        reportOutOfDateUnit(mainFilePath: "pathA", unitName: "unitA")
        instanceUnderTest.markUnitsProcessing(["unitA"])
        XCTAssertEqual(indexStore.trackedUnits.count, 1)
        XCTAssertEqual(indexStore.trackedUnits.first?.status, .processing)
    }

    func test_indexStore_clearProcessedUnits_proxiesToController() {
        reportOutOfDateUnit(mainFilePath: "pathA", unitName: "unitA")
        instanceUnderTest.markUnitsProcessing(["unitA"])
        instanceUnderTest.markUnitsProcessed(["unitA"])
        XCTAssertEqual(instanceUnderTest.allTrackedUnits.count, 1)

        indexStore.clearProcessedUnits()
        XCTAssertTrue(instanceUnderTest.allTrackedUnits.isEmpty)
    }

    func test_indexStore_clearAllTrackedUnits_proxiesToController() {
        reportOutOfDateUnit(mainFilePath: "pathA", unitName: "unitA")
        reportOutOfDateUnit(mainFilePath: "pathB", unitName: "unitB")
        XCTAssertEqual(instanceUnderTest.allTrackedUnits.count, 2)

        indexStore.clearAllTrackedUnits()
        XCTAssertTrue(instanceUnderTest.allTrackedUnits.isEmpty)
    }

    // MARK: - Helpers

    private func reportOutOfDateUnit(
        mainFilePath: String = "main-path",
        unitName: String = "unit-name",
        outOfDateModTime: UInt64 = 1234,
        triggerHintFile: String = "hint",
        triggerHintDescription: String = "hint-desc",
        synchronous: Bool = false
    ) {
        instanceUnderTest.unitIsOutOfDate(
            StoreUnitInfo(mainFilePath: mainFilePath, unitName: unitName),
            outOfDateModTime: outOfDateModTime,
            triggerHintFile: triggerHintFile,
            triggerHintDescription: triggerHintDescription,
            synchronous: synchronous
        )
    }
}
