//
//  Configuration.swift
//  IndexStore
//
//  Created by CheekyGhost Labs on 19/4/2023.
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation
import TSCBasic

/// Struct holding configuration values that can override any resolvable defaults.
public struct Configuration {

    /// The  root project directory path.
    public let projectDirectory: String

    /// The project index storePath path.
    public let indexStorePath: String

    /// The project index database path.
    public var indexDatabasePath: String

    /// /// The path to the libIndexStore dlyib.
    public var libIndexStorePath: String

    // MARK: - Lifecycle

    /// Will initialize a new configuration instance with the given details.
    /// - Parameters:
    ///   - projectDirectory: The root project directory the kit will be working in.
    ///   - indexStorePath: The project index database path. A default path derived from the build directory will by assigned if left as `nil`.
    public init(
        projectDirectory: String,
        indexStorePath: String? = nil,
        indexDatabasePath: String? = nil,
        libIndexStorePath: String? = nil
    ) throws {
        // Project directory path
        self.projectDirectory = projectDirectory
        // Database Path
        self.indexDatabasePath = indexDatabasePath ?? "\(NSTemporaryDirectory())index_\(getpid())"
        // Resolve xcode path for index store dylib
        if let libIndexStorePath {
            self.libIndexStorePath = libIndexStorePath
        } else {
            let path = try shell("xcode-select -p")
            self.libIndexStorePath = "\(path)/Toolchains/XcodeDefault.xctoolchain/usr/lib/libIndexStore.dylib"
        }
        // Resolve index store db path from active process
        let processInfo = ProcessInfo()
        // Running in swift/terminal etc
        guard processInfo.environment.keys.contains(EnvironmentKeys.xcodeBuiltProducts) else {
            let projectDirectory = try processInfo.environmentVariable(name: EnvironmentKeys.PWD)
            let buildRoot = projectDirectory + "/.build/debug"
            let buildRootPath = try AbsolutePath(validating: buildRoot)
            self.indexStorePath = indexStorePath ?? "\(buildRootPath.pathString)/Index/Store"
            return
        }
        // Xcode Process
        let buildRoot = try processInfo.environmentVariable(name: EnvironmentKeys.xcodeBuiltProducts)
        let buildRootPath = try AbsolutePath(validating: buildRoot).parentDirectory.parentDirectory.parentDirectory
        self.indexStorePath = indexStorePath ?? "\(buildRootPath.pathString)/Index.noindex/DataStore"
    }
}
