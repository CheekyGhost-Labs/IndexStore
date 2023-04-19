//
//  Logger+Defaults.swift
//  IndexStore
//
//  Created by CheekyGhost Labs on 19/4/2023.
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation
import Logging

private let defaultInstance: Logger = Logger(label: "com.cheekyghost.IndexStore")

extension Logger {

    /// Unit testing Logger instance
    static var test: Logger { defaultInstance }
}
