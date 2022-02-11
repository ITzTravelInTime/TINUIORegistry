//
//  File.swift
//  
//
//  Created by ITzTravelInTime on 11/02/22.
//

import Foundation

#if os(macOS)

public protocol DiskPointer: Codable, Equatable{
    var DeviceIdentifier: BSDID { get }
}

public protocol DiskProtocol: DiskPointer{
    var ejectable: Bool { get }
    var removable: Bool { get }
    var Content: String? { get }
    var Size: UInt64 { get }
    var writable: Bool { get }
    var id: UUID { get }
    var name: String? { get }
}

#endif
