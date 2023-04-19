//
//  Protocols.swift
//  IndexStoreTests
//
//  Created by CheekyGhost Labs on 19/4/2023.
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation

protocol RootProtocol {}

protocol ProtocolWithSystemInheritence: Equatable {}

class ProtocolName {}

protocol BaseProtocol {}

protocol ProtocolWithInheritence: BaseProtocol {}
