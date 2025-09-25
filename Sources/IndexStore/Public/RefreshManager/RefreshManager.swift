//
//  RefreshManager.swift
//  IndexStore
//
//  Created by Michael O'Brien on 25/9/2025.
//

import Foundation
import IndexStoreDB

public extension RefreshConfiguration {

    /// Pre-configured settings for Xcode extensions
    static var xcodeExtension: RefreshConfiguration {
        .init(
            maxAge: 60, // 1 minute - shorter for extensions
            minimumRefreshInterval: 5
        )
    }

    /// Pre-configured settings for Xcode extensions
    static var conservative: RefreshConfiguration {
        .init(
            maxAge: 600, // 10 minutes
            minimumRefreshInterval: 30
        )
    }
}

/// Configuration for refresh behavior
public struct RefreshConfiguration {

    /// Maximum age before forcing a refresh (in seconds)
    public let maxAge: TimeInterval

    /// Minimum interval between refreshes to avoid excessive polling
    public let minimumRefreshInterval: TimeInterval

    public init(
        maxAge: TimeInterval = 300, // 5 minutes
        minimumRefreshInterval: TimeInterval = 10 // 10 seconds
    ) {
        self.maxAge = maxAge
        self.minimumRefreshInterval = minimumRefreshInterval
    }

}

/// Tracks refresh state and provides intelligent refresh decisions
public class IndexStoreRefreshManager {

    // MARK: - Properties: Public

    public var indexStorePath: String {
        indexStoreConfiguration.indexStorePath
    }

    public var databasePath: String {
        indexStoreConfiguration.indexDatabasePath
    }

    // MARK: - Properties: Public

    public let configuration: RefreshConfiguration

    public let indexStoreConfiguration: IndexStore.Configuration

    // MARK: - Properties: Internal

    let userDefaults: UserDefaults

    let lastRefreshKey: String = "IndexStore.refreshManager.lastRefresh"

    let lastIndexStoreModificationKey: String = "IndexStore.refreshManager.lastModified"

    let refreshCountKey: String = "IndexStore.refreshManager.refreshCount"

    init(
        configuration: RefreshConfiguration,
        indexStoreConfiguration: IndexStore.Configuration,
        userDefaults: UserDefaults = .standard
    ) {
        self.configuration = configuration
        self.indexStoreConfiguration = indexStoreConfiguration
        self.userDefaults = userDefaults
    }

    /// Information about the current index state
    public struct IndexState {

        // MARK: - Supplementary

        public enum StaleStatus: Equatable {
            case notStale
            case neverRefreshed
            case exceedsMaxAge(TimeInterval)
            case indexStoreNewer
            case databaseMissing
            case forceRefresh
            case minimumIntervalNotMet

            var isStale: Bool {
                self != .notStale
            }
        }

        // MARK: - Propertues

        public let lastRefresh: Date?
        public let indexStoreLastModified: Date?
        public let databaseLastModified: Date?
        public let secondsSinceLastRefresh: TimeInterval
        public let staleStatus: StaleStatus

        public var isStale: Bool { staleStatus.isStale }

        public init(
            lastRefresh: Date?,
            indexStoreLastModified: Date?,
            databaseLastModified: Date?,
            secondsSinceLastRefresh: TimeInterval,
            staleStatus: StaleStatus
        ) {
            self.lastRefresh = lastRefresh
            self.indexStoreLastModified = indexStoreLastModified
            self.databaseLastModified = databaseLastModified
            self.secondsSinceLastRefresh = secondsSinceLastRefresh
            self.staleStatus = staleStatus
        }

        static func empty() -> Self {
            .init(
                lastRefresh: nil,
                indexStoreLastModified: nil,
                databaseLastModified: nil,
                secondsSinceLastRefresh: 0,
                staleStatus: .neverRefreshed
            )
        }
    }

    /// Check if the index needs refreshing without performing the refresh
    func getCurrentIndexState() -> IndexState {
        let lastRefresh = getLastRefreshDate()
        let indexStoreModTime = getIndexStoreLastModification()
        let databaseModTime = getDatabaseLastModification()

        let now = Date()
        let secondsSinceRefresh = lastRefresh?.timeIntervalSince(now) ?? TimeInterval.greatestFiniteMagnitude

        // Check various staleness conditions
        var status: IndexState.StaleStatus = .notStale

        if lastRefresh == nil {
            status = .neverRefreshed
        } else if abs(secondsSinceRefresh) > configuration.maxAge {
            status = .exceedsMaxAge(abs(secondsSinceRefresh))
        } else if let indexMod = indexStoreModTime, let lastRef = lastRefresh, indexMod > lastRef {
            status = .indexStoreNewer
        } else if databaseModTime == nil {
            status = .databaseMissing
        } else if lastRefresh != nil {
            let timeSinceLastRefresh = abs(lastRefresh!.timeIntervalSinceNow)
            if timeSinceLastRefresh < configuration.minimumRefreshInterval {
                status = .minimumIntervalNotMet
            }
        }

        return IndexState(
            lastRefresh: lastRefresh,
            indexStoreLastModified: indexStoreModTime,
            databaseLastModified: databaseModTime,
            secondsSinceLastRefresh: abs(secondsSinceRefresh),
            staleStatus: status
        )
    }

    /// Determine if a refresh should be performed
    func shouldRefresh(force: Bool = false) -> Bool {
        guard !force else { return true }
        let state = getCurrentIndexState()
        return state.isStale
    }

    /// Record that a refresh was performed
    func recordRefresh() {
        let now = Date()
        userDefaults.set(now.timeIntervalSince1970, forKey: lastRefreshKey)

        // Update the stored index store modification time
        if let indexStoreModTime = getIndexStoreLastModification() {
            userDefaults.set(indexStoreModTime.timeIntervalSince1970, forKey: lastIndexStoreModificationKey)
        }

        // Increment refresh count for diagnostics
        let currentCount = userDefaults.integer(forKey: refreshCountKey)
        userDefaults.set(currentCount + 1, forKey: refreshCountKey)
    }

    /// Get diagnostic information
    func getDiagnostics() -> [String: Any] {
        let state = getCurrentIndexState()
        let refreshCount = userDefaults.integer(forKey: refreshCountKey)

        return [
            "lastRefresh": state.lastRefresh?.description ?? "Never",
            "secondsSinceLastRefresh": state.secondsSinceLastRefresh,
            "isStale": state.isStale,
            "reason": String(describing: state.staleStatus),
            "indexStoreLastModified": state.indexStoreLastModified?.description ?? "Unknown",
            "databaseLastModified": state.databaseLastModified?.description ?? "Unknown",
            "totalRefreshCount": refreshCount,
            "configuration": [
                "maxAge": configuration.maxAge,
                "minimumRefreshInterval": configuration.minimumRefreshInterval
            ]
        ]
    }

    // MARK: - Methods

    func getLastRefreshDate() -> Date? {
        let timestamp = userDefaults.double(forKey: lastRefreshKey)
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }

    func getIndexStoreLastModification() -> Date? {
        let url = URL(fileURLWithPath: indexStorePath)

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else {
            return nil
        }

        var latestModification = Date.distantPast

        while let fileURL = enumerator.nextObject() as? URL {
            do {
                let attributes = try fileURL.resourceValues(forKeys: [.contentModificationDateKey])
                if let modDate = attributes.contentModificationDate {
                    latestModification = max(latestModification, modDate)
                }
            } catch {
                continue
            }
        }

        return latestModification > Date.distantPast ? latestModification : nil
    }

    func getDatabaseLastModification() -> Date? {
        let url = URL(fileURLWithPath: databasePath)

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.modificationDate] as? Date
        } catch {
            return nil
        }
    }
}

/// Result of a refresh operation
public struct RefreshResult: CustomStringConvertible {
    public let success: Bool
    public let duration: TimeInterval
    public let reason: Reason
    public let indexState: IndexStoreRefreshManager.IndexState

    public enum Reason {
        case notNeeded
        case needed
        case forced
        case timeout
        case error(Error)
    }

    public var description: String {
        let status = success ? "✅" : "❌"
        let reasonText = switch reason {
        case .notNeeded: "not needed"
        case .needed: "needed"
        case .forced: "forced"
        case .timeout: "timeout"
        case .error(let error): "error: \(error.localizedDescription)"
        }

        return "\(status) Refresh \(reasonText) (took \(String(format: "%.2f", duration))s)"
    }
}

struct AnyError: LocalizedError {

    // MARK: - Properties

    var message: String

    var recoveryHint: String?

    // MARK: - LocalizedError

    var errorDescription: String? { failureReason }

    var failureReason: String? { localizedFailureReason }

    var localizedFailureReason: String? { message }

    var recoverySuggestion: String? { recoveryHint }

    // MARK: - Lifecycle

    init(_ message: String, recoveryHint: String? = nil) {
        self.message = message
        self.recoveryHint = recoveryHint
    }
}
