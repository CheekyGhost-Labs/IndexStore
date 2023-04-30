//
//  SourceDetailsCollection.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import Foundation

/// `Sequence` conforming struct holding an array of source parents.
public struct SourceDetailsCollection: Sequence, Equatable {

    // MARK: - Properties

    /// Array of ``SourceSymbol`` representing the parent heirachy of a ``SourceSymbol`` instances.
    private(set) public var items: [SourceSymbol] = [] {
        didSet {
            lastCount = items.count
        }
    }

    /// The total number of items currently in the collection.
    public var count: Int { items.count }

    // MARK: - Properties: Internal

    var lastCount: Int = 0

    // MARK: - Lifecycle

    public init(items: [SourceSymbol]) {
        self.items = items
    }

    // MARK: - Sequence

    public mutating func append(_ item: SourceSymbol) {
        items.append(item)
    }

    public func makeIterator() -> AnyIterator<SourceSymbol> {
        var index = 0

        return AnyIterator {
            defer { index += 1 }
            return index < items.count ? items[index] : nil
        }
    }
}

/// `IteratorProtocol` concrete for iterating through parent source types for a source type.
/// When asking for `next` or `previous`, keep in mind that the iterator returns the current item before moving forward/back.
public class SourceDetailsIterator: IteratorProtocol, Equatable {

    // MARK: - Properties

    // The collection of source parents being iterated through.
    private(set) var collection: SourceDetailsCollection

    // The current index in the iterator.
    private(set) var index = 0

    /// The total number of items currently in the iterator.
    public var count: Int { collection.count }

    // MARK: - Lifecycle

    public init(_ collection: SourceDetailsCollection) {
        self.collection = collection
    }

    // MARK: - IteratorProtocol

    /// Will move to and return the next element in the iterator.
    /// - Returns: The next item in the iterator
    @discardableResult public func next() -> SourceSymbol? {
        defer { index += 1 }
        return index < collection.items.count ? collection.items[index] : nil
    }

    // MARK: - Conformance: Equatable

    public static func == (lhs: SourceDetailsIterator, rhs: SourceDetailsIterator) -> Bool {
        return lhs.collection == rhs.collection
    }
}
