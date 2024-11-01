//
//  Logger+Tests.swift
//  IndexStoreTests
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Foundation
import OSLog

private let testInstance: Logger = .init(subsystem: "com.cheekyghost.MimicKit.tests", category: "unit-tests")

extension Logger {
    /// Unit testing Logger instance
    static var test: Logger { testInstance }
}
