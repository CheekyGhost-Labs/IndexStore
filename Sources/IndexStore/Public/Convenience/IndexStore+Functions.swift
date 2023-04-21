//
//  IndexStore+Functions.swift
//  IndexStore
//
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation

public extension IndexStore {

    func sourceDetails(forFunctionsMatching query: String, caseInsensitive: Bool = false) -> [SourceDetails] {
        sourceDetails(
            matchingType: query,
            kinds: [.instanceMethod],
            roles: [.definition, .canonical],
            anchorStart: false,
            anchorEnd: false,
            includeSubsequence: true,
            caseInsensitive: caseInsensitive
        )
    }
}
