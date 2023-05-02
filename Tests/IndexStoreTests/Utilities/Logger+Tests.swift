//
//  Logger+Tests.swift
//  IndexStoreTests
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Foundation
import Logging

private let testInstance: Logger = .init(label: "com.cheekyghost.MimicKit.tests")

extension Logger {
    /// Unit testing Logger instance
    static var test: Logger { testInstance }
}
