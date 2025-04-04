//
//  Shell.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Foundation

enum ShellError: LocalizedError, Sendable {
    case unableToDecodeResult
}

/// Will perform a simple shell command and return the result.
/// - Parameter command: The command to invoke.
/// - Returns: ``String``
@discardableResult
func shell(_ command: String) throws -> String {
    let task = Process()
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")
    task.standardInput = nil

    try task.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let output = String(data: data, encoding: .utf8) else {
        throw ShellError.unableToDecodeResult
    }

    return output.trimmingCharacters(in: .whitespacesAndNewlines)
}
