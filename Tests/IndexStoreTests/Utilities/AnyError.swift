//
//  AnyError.swift
//  IndexStoreTests
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Foundation

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
