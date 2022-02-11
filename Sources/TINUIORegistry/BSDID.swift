//
//  BSDID.swift
//  Disk List
//
//  Created by Pietro Caruso on 03/08/21.
//

import Foundation

#if os(macOS)

public struct BSDID: Codable, Hashable, Equatable, RawRepresentable{
    
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
        self.rawValue = other.rawValue
    }
    
    public var rawValue: String
    
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
            guard let uintVal = "\(n)".uIntValue else{
                return []
            }
            
            ret.append(uintVal)
        }
        
        return ret
    }
    
    public var isValid: Bool{
        return Self.isValid(rawValue)
    }
    
    public func driveNumbers() -> [UInt]{
        return BSDID.driveNumbers(relativeTo: rawValue)
    }
    
    public var hashValue: Int { return self.rawValue.hashValue }
    public func hash(into hasher: inout Hasher){
        hasher.combine(self.rawValue)
    }
    
    public var driveID: BSDID{
        
        let numbers = driveNumbers()
        
        assert(!numbers.isEmpty, "BSDID must be valid before using it")
        
        let tmpBSDName = "\(numbers.first!)"
        
        return BSDID(BSDID.diskPrefix + tmpBSDName)
    }
    
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
    
    public var isDrive: Bool{
        return driveID == self
    }
    
    public var isVolume: Bool{
        return partitionID == self
    }
    
    public var isSnapshot: Bool{
        return !isDrive && !isVolume
    }
    
    public var driveNumber: UInt?{
        return driveNumbers().first
    }
    
    public var partitionNumber: UInt?{
        
        if isDrive{
            return nil
        }
        
        let str = driveNumbers()
        
        if str.count < 2{
            return nil
        }
        
        return UInt(str[1])
    }
    
}

#endif
