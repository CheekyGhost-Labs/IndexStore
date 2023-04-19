//
//  ProcessInfo+Environment.swift
//  IndexStore
//
//  Created by CheekyGhost Labs on 19/4/2023.
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation

// Default values for various environment values
struct EnvironmentKeys {
    static let PWD = "PWD"
    static let xcodeBuiltProducts = "__XCODE_BUILT_PRODUCTS_DIR_PATHS"
}

extension ProcessInfo {
    func environmentVariable(name: String) throws -> String {
        guard let value = self.environment[name] else {
            let message = "Missing environment value for key `\(name)`"
            throw NSError(
                domain: "com.cheekyghost.IndexStore.error",
                code: 0,
                userInfo: [NSLocalizedFailureReasonErrorKey: message]
            )
        }
        return value
    }
}
