//
//  Logger+Defaults.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Foundation
import OSLog

private let defaultInstance: Logger = .init(subsystem: "com.cheekyghost.IndexStore", category: "client")

extension Logger {
    /// Default client Logger instance
    static var `default`: Logger { defaultInstance }
}
