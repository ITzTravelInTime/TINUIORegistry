//
//  File.swift
//  
//
//  Created by ITzTravelInTime on 11/02/22.
//

import Foundation

internal extension String{
    @inline(__always) func copy()-> String{
        return String(self)
    }
    
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    
    func deletingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }
    
    @inline(__always) mutating func deletePrefix(_ prefix: String){
         self = self.deletingPrefix(prefix)
    }
    
    @inline(__always) mutating func deleteSuffix(_ suffix: String){
        self = self.deletingSuffix(suffix)
    }
    
    var isInt: Bool {
        if isEmpty { return false }
        return Int(self) != nil
    }
    
    var intValue: Int! {
        return Int(self)
    }
    
    var isUInt: Bool {
        if isEmpty { return false }
        return UInt(self) != nil
    }
    
    var uIntValue: UInt! {
        return UInt(self)
    }
    
    var isUInt64: Bool{
        if isEmpty { return false }
        return UInt64(self) != nil
    }
    
    var uInt64Value: UInt64! {
        return UInt64(self)
    }
    
    func contains(_ str: String) -> Bool{
        return self.range(of: str) != nil
    }
    
    var isAlphanumeric: Bool{
        
        if self.isEmpty{
            return false
        }
        
        //let ref = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890"
        for i in self{
            if (!i.isLetter && !i.isNumber){
                return false
            }
            
            /*
            if !ref.contains(i){
                return false
            }
            */
        }
        
        return true
    }
    
}

#if os(macOS)

import IOKit

public extension io_registry_entry_t{
    func getPath(relativeTo plane: IOPlane) -> String?{
        let pathName = UnsafeMutablePointer<io_string_t>.allocate(capacity: 1);
                            
        let int8NamePointer = UnsafeMutableRawPointer(pathName).bindMemory(to: Int8.self,capacity: 1)
                            
        if IORegistryEntryGetPath(self, plane.iOKitName, int8NamePointer) != kIOReturnSuccess{
            return nil
        }
        
        return String(cString: int8NamePointer)
    }
    
    func getParentEntry(relativeTo plane: IOPlane) -> Self?{
        var entry: io_registry_entry_t = 0
        
        if IORegistryEntryGetParentEntry(self, plane.iOKitName, &entry) != kIOReturnSuccess{
            return nil
        }
        
        return entry
    }
    
    func getFirstChildEntry(relativeTo plane: IOPlane) -> Self?{
        var entry: io_registry_entry_t = 0
        
        if IORegistryEntryGetChildEntry(self, plane.iOKitName, &entry) != kIOReturnSuccess{
            return nil
        }
        
        return entry
    }
}

#endif
