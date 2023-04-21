//
//  Protocols.swift
//  IndexStoreTests
//
//  Copyright (c) CheekyGhost Labs 2022. All Rights Reserved.
//

import Foundation

protocol RootProtocol {}

protocol ProtocolWithSystemInheritence: Equatable {}

class ProtocolName {}

protocol BaseProtocol {}

protocol ProtocolWithInheritence: BaseProtocol {}
