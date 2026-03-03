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

  // MARK: - Lifecycle

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
