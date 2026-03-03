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
    var state: StatusState = .init(pendingUnitCount: 0, lastPendingChangeTimestamp: nil, lastOutOfDateTimestamp: nil, lastOutOfDateUnit: nil)

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
        countQueue.sync {
            state.lastOutOfDateUnit = info
            state.lastOutOfDateTimestamp = Date()
        }
        notifyOutOfDate(info)
    }

    // MARK: - Notifications (internal)

    func notifyPendingCountChanged() {
        guard let store else { return }
        delegate?.indexStore(store, didUpdatePendingUnitCount: pendingUnitCount)
    }

    func notifyOutOfDate(_ unit: UnitInfo) {
        guard let store else { return }
        delegate?.indexStore(store, didDetectOutOfDateUnit: unit)
    }
}
