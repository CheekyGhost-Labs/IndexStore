//
//  SourceDetails.swift
//  IndexStore
//
//  Created by CheekyGhost Labs on 19/4/2023.
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation

/// Result returned by a ``SourceKitServer`` instance containing details about a resolved source type.
public struct SourceDetails: Identifiable, CustomStringConvertible, Equatable {

    // MARK: - Properties

    /// The name of the source. Defaults to empty string.
    public let name: String

    /// The symbol `usr` definition of the source.
    public let usr: String

    /// The kind of the source.
    /// - See: ``SourceKind``
    public let sourceKind: SourceKind

    /// OptionSet value representation of the roles the source plays.
    public let roles: SourceRole

    /// The location of the source.
    /// - See: ``SourceLocation``
    public let location: SourceLocation

    /// Optional parent type that declares/owns the declaration type.
    /// - See: ``SourceDetails``
    public var parent: SourceDetails? { _parents.first }

    /// Iterator holding an array of `SourceDetails` representing the parent heirachy that owns the declaration.
    ///
    /// Parent items are ordered from `0` being the immediate parent/declaring type, with each `next`/index being the next parent in the heirachy
    public var parentsIterator: AnyIterator<SourceDetails> {
        var parents: [SourceDetails] = []
        var nextParent: SourceDetails? = parent
        while nextParent != nil {
            if let element = nextParent {
                parents.append(element)
            }
            nextParent = nextParent?.parent
        }
        let baseIterator = SourceDetailsIterator(SourceDetailsCollection(items: parents))
        return AnyIterator<SourceDetails>(baseIterator)
    }

    /// Array of ``SourceDetails`` representing the source types that the declaration conforms to (or inherits from).
    ///
    /// Inheritence items are ordered from `0` being the immediate inheritence with each subsequent element being the next conforming type in the declaration.
    public let inheritance: [SourceDetails]

    // MARK: - Properties: Internal

    /// Array holding the direct parent ``SourceDetails`` instance (if any).
    ///
    /// This is used to avoid using a class and protocols as Value types can't recursively contain their own type.
    let _parents: [SourceDetails]

    // MARK: - Lifecycle

    public init(
        name: String,
        usr: String,
        sourceKind: SourceKind,
        roles: SourceRole,
        location: SourceLocation,
        parent: SourceDetails? = nil,
        inheritence: [SourceDetails] = []
    ) {
        self.name = name
        self.usr = usr
        self.sourceKind = sourceKind
        self.roles = roles
        self.location = location
        self.inheritance = inheritence
        if let parent = parent {
            _parents = [parent]
        } else {
            _parents = []
        }
    }

    // MARK: - Conformance: Identifiable

    public var id: String {
        "\(usr):\(name):\(location.path):\(location.line):\(location.column)"
    }

    // MARK: - Conformance: CustomStringConvertible

    public var description: String {
        "\(name) | \(sourceKind) | \(location.description)"
    }
}
