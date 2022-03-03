//
//  File.swift
//  
//
//  Created by ITzTravelInTime on 11/02/22.
//

import Foundation

#if os(macOS)

import IOKit

/*
 public var kIOServicePlane: String { get }
 public var kIOPowerPlane: String { get }
 public var kIODeviceTreePlane: String { get }
 public var kIOAudioPlane: String { get }
 public var kIOFireWirePlane: String { get }
 public var kIOUSBPlane: String { get }
 */

///Used to represent the IORegistry planes
public enum IOPlane: String, Equatable, CaseIterable, RawRepresentable{
    case service
    case audio
    case power
    case deviceTree
    case fireWire
    case usb
    
    internal var iOKitName: String{
        switch self{
        case .service:
            return kIOServicePlane
        case .audio:
            return kIOAudioPlane
        case .power:
            return kIOPowerPlane
        case .deviceTree:
            return kIODeviceTreePlane
        case .fireWire:
            return kIOFireWirePlane
        case .usb:
            return kIOUSBPlane
        }
    }
}

#endif
