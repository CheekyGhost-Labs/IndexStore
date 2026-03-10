//
//  IndexStoreStatusController.swift
//  IndexStore
//
//  Created by Michael O'Brien on 3/3/2026.
//

import Foundation
import IndexStoreDB

/// Internal bridge between IndexStoreDB.IndexDelegate and your public IndexStoreDelegate.
///
/// Notes:
/// - This class intentionally contains minimal policy: it computes pending count and forwards events.
/// - Thread safety is intentionally left as a TODO, per your request. You can later wrap mutations
///   in a serial queue or lock without changing the surface area.
class IndexStatusController: IndexDelegate {

    // MARK: - Types

    struct StatusState: Sendable {
        var pendingUnitCount: Int
        var lastPendingChangeTimestamp: Date?
        var lastOutOfDateTimestamp: Date?
        var lastOutOfDateUnit: UnitInfo?
        /// All tracked units keyed by `unitName`.
        var trackedUnits: [String: TrackedUnit] = [:]
    }

    // MARK: - References

    /// Weak reference to the owning IndexStore wrapper, used in forwarded delegate callbacks.
    weak var store: IndexStore?

    /// Public delegate exposed by IndexStore (proxy target).
    weak var delegate: IndexStoreDelegate?

    // MARK: - Properties: Internal

    /// The current number of units that IndexStoreDB has reported as pending processing.
    ///
    /// This value is incremented via `processingAddedPending(_:)` and decremented via
    /// `processingCompleted(_:)`. It represents IndexStoreDB's internal processing queue,
    /// and can be used as a lightweight signal for “indexing activity”.
    ///
    /// - Important: This is not a guarantee that Xcode is indexing; it indicates that
    ///   IndexStoreDB is actively processing detected unit changes for the configured store.
    var pendingUnitCount: Int {
        countQueue.sync {
            state.pendingUnitCount
        }
    }

    /// The last time `pendingUnitCount` changed.
    ///
    /// Updated whenever IndexStoreDB reports pending units added or completed.
    /// Useful for diagnosing “stalled” scenarios (e.g. pending > 0 with no changes for
    /// a period of time).
    var lastPendingChangeTimestamp: Date? {
        countQueue.sync {
            state.lastPendingChangeTimestamp
        }
    }

    /// The last time an out-of-date unit was reported.
    ///
    /// Updated whenever `unitIsOutOfDate(...)` is received.
    /// This does not imply that IndexStoreDB has begun or completed processing for that unit.
    var lastOutOfDateTimestamp: Date? {
        countQueue.sync {
            state.lastOutOfDateTimestamp
        }
    }

    /// The most recent out-of-date unit details reported by IndexStoreDB.
    ///
    /// This value is updated whenever `unitIsOutOfDate(...)` is received.
    /// Consumers may use it for diagnostics, logging, or user-facing messaging.
    var lastOutOfDateUnit: UnitInfo? {
        countQueue.sync {
            state.lastOutOfDateUnit
        }
    }

    /// A snapshot of the current status state.
    ///
    /// This provides a single read point for multiple fields that collectively describe
    /// the store status (pending processing and out-of-date detection). As the implementation
    /// evolves (e.g. adding thread-safety or additional signals), `snapshot` helps keep
    /// state reads consistent and easy to extend.
    var state: StatusState = .init(pendingUnitCount: 0, lastPendingChangeTimestamp: nil, lastOutOfDateTimestamp: nil, lastOutOfDateUnit: nil, trackedUnits: [:])

    /// Indicates whether IndexStoreDB is currently processing at least one pending unit.
    ///
    /// Returns `true` when `pendingUnitCount > 0`.
    ///
    /// - Note: This reflects IndexStoreDB processing activity, not necessarily that Xcode
    ///         is currently performing indexing work.
    var isIndexing: Bool {
        countQueue.sync {
            state.pendingUnitCount > 0
        }
    }
    
    /// Dispatch queue used to drive some thread safety until library is migrated to structured concurrency.
    var countQueue: DispatchQueue = .init(label: "com.CheekyGhost.IndexStore.status")

    // MARK: - Init

    internal init(store: IndexStore? = nil, delegate: IndexStoreDelegate? = nil) {
        self.store = store
        self.delegate = delegate
    }

    // MARK: - Conformance: IndexDelegate

    /// IndexStoreDB indicates that `count` units have been added to its internal processing queue.
    func processingAddedPending(_ count: Int) {
        var didChange = false
        countQueue.sync {
            let oldCount = state.pendingUnitCount
            state.pendingUnitCount = max(0, oldCount + count)
            state.lastPendingChangeTimestamp = Date()
            didChange = (state.pendingUnitCount != oldCount)
        }
        if didChange {
            notifyPendingCountChanged()
        }
    }

    /// IndexStoreDB indicates that `count` units have completed processing.
    func processingCompleted(_ count: Int) {
        var didChange = false
        countQueue.sync {
            let oldCount = state.pendingUnitCount
            state.pendingUnitCount = max(0, oldCount - count)
            state.lastPendingChangeTimestamp = Date()
            didChange = (state.pendingUnitCount != oldCount)
        }
        if didChange {
            notifyPendingCountChanged()
        }
    }

    /// IndexStoreDB indicates a unit is out of date.
    /// Only called if IndexStoreDB was initialized with out-of-date detection enabled.
    func unitIsOutOfDate(
        _ unitInfo: StoreUnitInfo,
        outOfDateModTime: UInt64,
        triggerHintFile: String,
        triggerHintDescription: String,
        synchronous: Bool
    ) {
        let info = UnitInfo(
            mainFilePath: unitInfo.mainFilePath,
            unitName: unitInfo.unitName,
            outOfDateModTime: outOfDateModTime,
            triggerHintFile: triggerHintFile,
            triggerHintDescription: triggerHintDescription,
            synchronous: synchronous
        )
        var tracked: TrackedUnit!
        countQueue.sync {
            state.lastOutOfDateUnit = info
            state.lastOutOfDateTimestamp = Date()
            let entry = TrackedUnit(unit: info, status: .outOfDate)
            state.trackedUnits[info.unitName] = entry
            tracked = entry
        }
        notifyOutOfDate(info)
        notifyTrackedUnitStatusChanged(tracked)
    }

    // MARK: - Properties: Tracked Units

    /// Returns `true` when there is at least one tracked unit with ``UnitInfo/Status/outOfDate`` status.
    var hasOutOfDateUnits: Bool {
        !outOfDateUnits.isEmpty
    }

    /// All tracked units that are currently in the `.outOfDate` status.
    var outOfDateUnits: [TrackedUnit] {
        countQueue.sync {
            state.trackedUnits.values.filter { $0.status == .outOfDate }
        }
    }

    /// A snapshot of all tracked units regardless of status.
    var allTrackedUnits: [TrackedUnit] {
        countQueue.sync {
            Array(state.trackedUnits.values)
        }
    }

    // MARK: - Helpers: Tracked Unit Lifecycle

    /// Transitions the given unit names from ``UnitInfo/Status/outOfDate`` to ``UnitInfo/Status/processing``.
    ///
    /// Only units whose current status is `.outOfDate` will be transitioned. Units in any other
    /// status are silently ignored.
    ///
    /// - Parameter unitNames: The set of `unitName` identifiers to transition.
    /// - Returns: The ``TrackedUnit`` values that were actually transitioned. Empty if none matched.
    @discardableResult
    func markUnitsProcessing(_ unitNames: Set<String>) -> [TrackedUnit] {
        var transitioned: [TrackedUnit] = []
        countQueue.sync {
            for name in unitNames {
                guard let existing = state.trackedUnits[name], existing.status == .outOfDate else { continue }
                let updated = existing.withStatus(.processing)
                state.trackedUnits[name] = updated
                transitioned.append(updated)
            }
        }
        for unit in transitioned {
            notifyTrackedUnitStatusChanged(unit)
        }
        return transitioned
    }

    /// Transitions the given unit names from ``UnitInfo/Status/processing`` to ``UnitInfo/Status/processed``.
    ///
    /// Only units whose current status is `.processing` will be transitioned. Units in any other
    /// status are silently ignored.
    ///
    /// - Parameter unitNames: The set of `unitName` identifiers to transition.
    /// - Returns: The ``TrackedUnit`` values that were actually transitioned. Empty if none matched.
    @discardableResult
    func markUnitsProcessed(_ unitNames: Set<String>) -> [TrackedUnit] {
        var transitioned: [TrackedUnit] = []
        countQueue.sync {
            for name in unitNames {
                guard let existing = state.trackedUnits[name], existing.status == .processing else { continue }
                let updated = existing.withStatus(.processed)
                state.trackedUnits[name] = updated
                transitioned.append(updated)
            }
        }
        for unit in transitioned {
            notifyTrackedUnitStatusChanged(unit)
        }
        return transitioned
    }

    /// Removes all tracked units with ``UnitInfo/Status/processed`` status.
    ///
    /// Units that are still `.outOfDate` or `.processing` are retained.
    func clearProcessedUnits() {
        countQueue.sync {
            state.trackedUnits = state.trackedUnits.filter { $0.value.status != .processed }
        }
    }

    /// Removes all tracked units regardless of their current status.
    func clearAllTrackedUnits() {
        countQueue.sync {
            state.trackedUnits.removeAll()
        }
    }

    // MARK: - Notifications (internal)

    /// Clears the ``lastOutOfDateUnit`` and ``lastOutOfDateTimestamp`` values.
    ///
    /// This does **not** affect the ``trackedUnits`` collection.
    func clearLastOutOfDateUnitStatus() {
        countQueue.sync {
            state.lastOutOfDateUnit = nil
            state.lastOutOfDateTimestamp = nil
        }
    }

    /// Forwards the current pending unit count to the public ``IndexStoreDelegate``.
    func notifyPendingCountChanged() {
        guard let store else { return }
        delegate?.indexStore(store, didUpdatePendingUnitCount: pendingUnitCount)
    }

    /// Forwards an out-of-date unit event to the public ``IndexStoreDelegate``.
    ///
    /// - Parameter unit: The ``UnitInfo`` describing the out-of-date unit.
    func notifyOutOfDate(_ unit: UnitInfo) {
        guard let store else { return }
        delegate?.indexStore(store, didDetectOutOfDateUnit: unit)
    }

    /// Forwards a tracked unit status change to the public ``IndexStoreDelegate``.
    ///
    /// - Parameter trackedUnit: The ``TrackedUnit`` whose status was updated.
    func notifyTrackedUnitStatusChanged(_ trackedUnit: TrackedUnit) {
        guard let store else { return }
        delegate?.indexStore(store, didUpdateTrackedUnitStatus: trackedUnit)
    }
}
