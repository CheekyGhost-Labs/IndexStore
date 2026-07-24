//
//  UnitInfo.swift
//  IndexStore
//
//  Created by Michael O'Brien on 3/3/2026.
//

import Foundation

/// Describes an IndexStore unit that was detected as out of date.
///
/// `UnitInfo` is emitted via ``IndexStoreDelegate/indexStore(_:didDetectOutOfDateUnit:)`` when
/// out-of-date detection is enabled for the underlying IndexStoreDB instance.
///
/// This is a lightweight, public-facing abstraction over the information supplied by
/// `IndexStoreDB.IndexDelegate.unitIsOutOfDate(...)`, without explicitly exposing IndexStoreDB types.
///
/// - Note: Out-of-date detection events are independent from “pending unit processing” events.
///         A unit may be reported as out of date before, during, or after IndexStoreDB processes
///         unit updates.
public struct UnitInfo: Sendable, Hashable {

  /// The path to the main source file associated with the out-of-date unit.
  ///
  /// This is typically the primary file that produced the unit when the compiler emitted
  /// indexing data.
  public let mainFilePath: String

  /// The name/identifier of the out-of-date unit.
  ///
  /// This value is provided by IndexStoreDB and can be used for diagnostics or logging.
  public let unitName: String

  /// The modification timestamp (as reported by IndexStoreDB) used to determine the unit is out of date.
  ///
  /// This value comes from IndexStoreDB’s out-of-date detection mechanism and should be treated as an
  /// opaque “comparison timestamp” rather than a user-facing date.
  public let outOfDateModTime: UInt64

  /// A path hint describing which file change likely triggered the out-of-date detection.
  ///
  /// This is often a file that was modified, moved, or otherwise changed such that dependent units
  /// are now considered stale.
  public let triggerHintFile: String

  /// A human-readable description explaining why the unit was considered out of date.
  ///
  /// Useful for diagnostics output and user-facing messaging in a companion app.
  public let triggerHintDescription: String

  /// Indicates whether the underlying out-of-date event should be handled synchronously.
  ///
  /// When `true`, IndexStoreDB is requesting minimal, fast handling of the event.
  /// Consumers should avoid heavy work directly in this callback path and instead
  /// schedule any expensive follow-up asynchronously.
  public let synchronous: Bool

  // MARK: - Supplementary

  /// Describes the processing status of a tracked unit within the index store.
  public enum Status: Sendable, Hashable {
    /// The unit has been detected as out of date but has not yet been submitted for processing.
    case outOfDate
    /// The unit has been submitted for re-processing and is currently being imported.
    case processing
    /// The unit has been successfully re-processed.
    case processed
  }

  // MARK: - Lifecycle

  /// Creates a new ``UnitInfo`` instance describing an out-of-date unit.
  /// - Parameters:
  ///   - mainFilePath: The path to the main source file associated with the unit.
  ///   - unitName: The name/identifier of the unit as reported by IndexStoreDB.
  ///   - outOfDateModTime: The modification timestamp used to determine the unit is out of date.
  ///   - triggerHintFile: A path hint describing which file change triggered the detection.
  ///   - triggerHintDescription: A human-readable description of why the unit is out of date.
  ///   - synchronous: Whether the underlying event should be handled synchronously.
  public init(
    mainFilePath: String,
    unitName: String,
    outOfDateModTime: UInt64,
    triggerHintFile: String,
    triggerHintDescription: String,
    synchronous: Bool
  ) {
    self.mainFilePath = mainFilePath
    self.unitName = unitName
    self.outOfDateModTime = outOfDateModTime
    self.triggerHintFile = triggerHintFile
    self.triggerHintDescription = triggerHintDescription
    self.synchronous = synchronous
  }
}

// MARK: - TrackedUnit

/// Pairs a ``UnitInfo`` with its current processing ``UnitInfo/Status`` and the timestamp
/// of the most recent status change.
///
/// Consumers can retrieve tracked units from ``IndexStore/outOfDateUnits`` or
/// ``IndexStore/trackedUnits`` and pass them to ``IndexStore/processOutOfDateUnits(_:)``
/// to trigger re-processing.
///
/// Identity (``Equatable`` / ``Hashable``) is based on `unit.unitName`.
public struct TrackedUnit: Sendable {

  /// The underlying unit information.
  public let unit: UnitInfo

  /// The current processing status of the unit.
  public private(set) var status: UnitInfo.Status

  /// The date/time when ``status`` was last updated.
  public private(set) var lastStatusChange: Date

  // MARK: - Lifecycle

  /// Creates a new ``TrackedUnit`` instance.
  /// - Parameters:
  ///   - unit: The ``UnitInfo`` describing the underlying unit.
  ///   - status: The initial processing status. Defaults to ``UnitInfo/Status/outOfDate``.
  ///   - lastStatusChange: The timestamp of the initial status. Defaults to the current date.
  public init(unit: UnitInfo, status: UnitInfo.Status = .outOfDate, lastStatusChange: Date = Date()) {
    self.unit = unit
    self.status = status
    self.lastStatusChange = lastStatusChange
  }

  // MARK: - Helpers: Internal

  /// Returns a copy with the given status and an updated timestamp.
  ///
  /// - Parameters:
  ///   - newStatus: The ``UnitInfo/Status`` to assign.
  ///   - date: The timestamp to record for the status change. Defaults to the current date.
  /// - Returns: A new ``TrackedUnit`` with the updated status and timestamp.
  func withStatus(_ newStatus: UnitInfo.Status, at date: Date = Date()) -> TrackedUnit {
    TrackedUnit(unit: unit, status: newStatus, lastStatusChange: date)
  }
}

// MARK: - TrackedUnit + Equatable

extension TrackedUnit: Equatable {
  public static func == (lhs: TrackedUnit, rhs: TrackedUnit) -> Bool {
    lhs.unit.unitName == rhs.unit.unitName
  }
}

// MARK: - TrackedUnit + Hashable

extension TrackedUnit: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(unit.unitName)
  }
}
