//
//  IndexStoreDB+Hashable.swift
//
//
//  Copyright (c) CheekyGhost Labs 2023. All Rights Reserved.
//

import IndexStoreDB

// Extensions that adds Hashable support to IndexStoreDB types so can use OrderedSet results

extension SymbolOccurrence: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(symbol.hashValue)
        hasher.combine(location.hashValue)
        hasher.combine(roles.hashValue)
        hasher.combine(relations.hashValue)
    }
}

extension Symbol: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(usr.hashValue)
        hasher.combine(name.hashValue)
        hasher.combine(kind.hashValue)
        hasher.combine(properties.hashValue)
    }
}

extension SymbolLocation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(path.hashValue)
        hasher.combine(moduleName.hashValue)
        hasher.combine(isSystem.hashValue)
        hasher.combine(line.hashValue)
        hasher.combine(utf8Column.hashValue)
    }
}

extension SymbolRelation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(symbol.hashValue)
        hasher.combine(roles.hashValue)
    }
}
