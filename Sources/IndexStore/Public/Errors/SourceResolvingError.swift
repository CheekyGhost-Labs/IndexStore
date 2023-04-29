//
//  SourceResolvingError.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Foundation

/// Enumeration of errors that can be thrown while resolving source symbols and details.
public enum SourceResolvingError: Equatable, LocalizedError {
    case sourcePathDoesNotExist(path: String)
    case sourceContentsIsEmpty(path: String)
    case unableToReadContents(path: String, cause: String)
    case unableToResolveSourceLine(name: String, path: String, line: Int)

    public var code: Int {
        switch self {
        case .sourcePathDoesNotExist:
            return 0
        case .sourceContentsIsEmpty:
            return 1
        case .unableToReadContents:
            return 2
        case .unableToResolveSourceLine:
            return 3
        }
    }

    public var errorDescription: String? { failureReason }

    public var failureReason: String? {
        switch self {
        case .sourcePathDoesNotExist(let path):
            return "No source file exists for path: `\(path)`"
        case .sourceContentsIsEmpty(let path):
            return "Source contents is empty for file at path: `\(path)`"
        case .unableToReadContents(let path, let cause):
            return "Unable to read contents empty for file at path: `\(path)`. Cause: `\(cause)`"
        case .unableToResolveSourceLine(let name, let path, let line):
            return
                "Unable to resolve declaration line `\(line)` for `\(name)` in file at path: `\(path)`."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .sourcePathDoesNotExist:
            return
                "The source reference is probably cached in the index but the file has been removed. Please restore the file or ignore the declaration"
        case .sourceContentsIsEmpty:
            return
                "The contents of the resolved source path is empty. The source reference is probably cached in the index but the contents has been removed. This is treated as an error due to the reference not being present."
        case .unableToReadContents:
            return
                "The contents of the resolved source path was not able to be read. Please review the `cause` and ensure adequate permissions are granted."
        case .unableToResolveSourceLine:
            return
                "The contents of the resolved source path were found but the line in the source symbols instance was not resolvable. The reference is probably a cached reference but the file has been modified. Please ensure any indexing has completed and try again."
        }
    }
}
