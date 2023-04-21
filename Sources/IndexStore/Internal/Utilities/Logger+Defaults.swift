//
//  Logger+Defaults.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation
import Logging

private let defaultInstance: Logger = Logger(label: "com.cheekyghost.IndexStore")

extension Logger {

    /// Default client Logger instance
    static var `default`: Logger { defaultInstance }
}
