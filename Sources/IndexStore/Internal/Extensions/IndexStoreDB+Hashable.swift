//
//  IndexStoreDB+Hashable.swift
//
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import IndexStoreDB

// Extensions that adds Hashable support to IndexStoreDB types so can use OrderedSet results

#if swift(>=6.0)
extension SymbolOccurrence: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(symbol.hashValue)
        hasher.combine(location.hashValue)
        hasher.combine(roles.hashValue)
        hasher.combine(relations.hashValue)
    }
}
#else
extension SymbolOccurrence: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(symbol.hashValue)
        hasher.combine(location.hashValue)
        hasher.combine(roles.hashValue)
        hasher.combine(relations.hashValue)
    }
}
#endif

#if swift(>=6.0)
extension SymbolLocation: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(path.hashValue)
        hasher.combine(moduleName.hashValue)
        hasher.combine(isSystem.hashValue)
        hasher.combine(line.hashValue)
        hasher.combine(utf8Column.hashValue)
    }
}
#else
extension SymbolLocation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(path.hashValue)
        hasher.combine(moduleName.hashValue)
        hasher.combine(isSystem.hashValue)
        hasher.combine(line.hashValue)
        hasher.combine(utf8Column.hashValue)
    }
}
#endif

#if swift(>=6.0)
extension SymbolRelation: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(symbol.hashValue)
        hasher.combine(roles.hashValue)
    }
}
#else
extension SymbolRelation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(symbol.hashValue)
        hasher.combine(roles.hashValue)
    }
}
#endif
