//
//  ProcessInfo+Environment.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation

enum ProcessInfoError: LocalizedError, Equatable {
    case unableToFindValueForKey(String)

    public var code: Int {
        switch self {
        case .unableToFindValueForKey:
            return 0
        }
    }

    public var errorDescription: String? { failureReason }

    public var failureReason: String? {
        switch self {
        case .unableToFindValueForKey(let key):
            return "Unable to resolve value for key: `\(key)`"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .unableToFindValueForKey:
            return "Review the `environment` property to ensure expected values are present. Environment values change depending on where the process is running from"
        }
    }
}

// Default values for various environment values
struct EnvironmentKeys {
    static let PWD = "PWD"
    static let xcodeBuiltProducts = "__XCODE_BUILT_PRODUCTS_DIR_PATHS"
    static let testConfigurationPath = "XCTestConfigurationFilePath"
}

extension ProcessInfo {
    func environmentVariable(name: String) throws -> String {
        guard let value = self.environment[name] else {
            throw ProcessInfoError.unableToFindValueForKey(name)
        }
        return value
    }
}
