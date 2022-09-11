/*
 TINUNotifications: A Swift library to access information from the IORegistry in a Swift-friendly easy-to-use way.
 Copyright (C) 2022 Pietro Caruso

 This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

import Foundation

#if os(macOS) || targetEnvironment(macCatalyst)

import SwiftPackagesBase

///Type used to represent BSD device names for storage devices
public struct BSDID: Codable, Hashable, Equatable, RawRepresentable{
    ///Checks if the provvided string is a valid storage device BSD name
    public static func isValid(_ str: String) -> Bool{
        return !driveNumbers(relativeTo: str).isEmpty
    }
    
    private static var diskPrefix: String{
        return "disk"
    }
    
    private static var numberSeparator: Character{
        return "s"
    }
    
    public init() {
        self.rawValue = ""
    }
    
    public init(rawValue: String){
        self.init(rawValue)
    }
    
    public init(_ str: String){
        assert(BSDID.isValid(str), "BSDID must be valid before using it")
        
        self.rawValue = str
        
        //assert(isValid, "BSDID must be valid before using it")
    }
    
    public init(_ str: String.Element){
        self.init(rawValue: String(str))
    }
    
    public init(other: BSDID){
        assert(BSDID.isValid(other.rawValue), "BSDID must be valid and initialised before using it")
        self.rawValue = other.rawValue
    }
    
    public var rawValue: String
    
    ///Returns the number components of the povvided disk BSD name string
    private static func driveNumbers(relativeTo str: String) -> [UInt]{
        if !(str.isAlphanumeric && str.starts(with: diskPrefix) && !str.isEmpty){
            return []
        }
        
        let nums = str.deletingPrefix(diskPrefix).split(separator: numberSeparator)
        
        if nums.count < 1 || nums.count > 3{
            return []
        }
        
        var ret = [UInt]()
        
        for n in nums{
            guard let uintVal: UInt = "\(n)".uIntValue() else{
                return []
            }
            
            ret.append(uintVal)
        }
        
        return ret
    }
    
    ///Checks if the current instance is a valid BSD name and it's properly initialised
    public var isValid: Bool{
        return Self.isValid(rawValue)
    }
    
    ///Returns the numeric components of the BSD name
    public func driveNumbers() -> [UInt]{
        return BSDID.driveNumbers(relativeTo: rawValue)
    }
    
    public var hashValue: Int { return self.rawValue.hashValue }
    
    public func hash(into hasher: inout Hasher){
        hasher.combine(self.rawValue)
    }
    
    ///Returns the BSDID of the current disk's drive
    public var driveID: BSDID{
        
        let numbers = driveNumbers()
        
        assert(!numbers.isEmpty, "BSDID must be valid and properly initalised before using it")
        
        let tmpBSDName = "\(numbers.first!)"
        
        return BSDID(BSDID.diskPrefix + tmpBSDName)
    }
    
    ///Returns the partition BSD name of the current instance (mainly used for BSD names of APFS snapshots)
    public var partitionID: BSDID?{
        if self.isDrive{
            return nil
        }
        
        let numbers = driveNumbers()
        
        if numbers.count < 2 {
            return nil
        }
        
        return BSDID(BSDID.diskPrefix + String(numbers[0]) + String(BSDID.numberSeparator) + String(numbers[1]))
    }
    
    ///Returns if the current instance represents a drive BSD name
    public var isDrive: Bool{
        return driveID == self
    }
    
    ///Returns if the current instance represents the BSD name of a volume/partition
    public var isVolume: Bool{
        return partitionID == self
    }
    
    ///Returns if the current instance represents the BSD name of an APFS snapshot
    public var isSnapshot: Bool{
        return !isDrive && !isVolume
    }
    
    ///Returns if the drive number component of the current BSD name
    public var driveNumber: UInt?{
        return driveNumbers().first
    }
    
    ///Returns if the partition number component of the current BSD name (if applicable)
    public var partitionNumber: UInt?{
        
        if isDrive{
            return nil
        }
        
        let str = driveNumbers()
        
        if str.count < 2{
            return nil
        }
        
        return str[1].uIntValue()
    }
    
}

#endif
