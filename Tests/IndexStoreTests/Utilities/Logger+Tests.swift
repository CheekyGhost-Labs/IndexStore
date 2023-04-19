//
//  Logger+Tests.swift
//  IndexStoreTests
//
//  Created by CheekyGhost Labs on 19/4/2023.
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation
import Logging

private let testInstance: Logger = Logger(label: "com.cheekyghost.MimicKit.tests")

extension Logger {

    /// Unit testing Logger instance
    static var test: Logger { testInstance }
}
