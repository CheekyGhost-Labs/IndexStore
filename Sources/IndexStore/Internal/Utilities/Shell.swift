//
//  Shell.swift
//  IndexStore
//
//  Created by CheekyGhost Labs on 19/4/2023.
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation

enum ShellError: LocalizedError {
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
