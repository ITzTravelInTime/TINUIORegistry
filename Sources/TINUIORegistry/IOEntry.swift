//
//  File.swift
//  
//
//  Created by ITzTravelInTime on 11/02/22.
//

import Foundation

#if os(macOS)

import IOKit

public class IOEntry{
    private let value: io_registry_entry_t
    private let options: IOOptionBits
    private let avoidRelease: Bool
    
    public convenience init?(fromRegistryPath path: String, options: IOOptionBits = 0){
        let entry = IORegistryEntryFromPath(IOServiceGetMatchingService(kIOMasterPortDefault, nil), path)
        self.init(value: entry, options: options)
    }
    
    internal required init?(value: io_registry_entry_t, options: IOOptionBits = 0, avoidRelease: Bool = false) {
        
        if value == 0{
            return nil
        }
        
        self.value = value
        self.options = options
        self.avoidRelease = avoidRelease
    }
    
    deinit{
        if !avoidRelease{
            IOObjectRelease(value)
        }
    }
    
    ///reads a generic property from the entry
    public func getProperty(forKey key: String) -> Unmanaged<CFTypeRef>!{
        return IORegistryEntryCreateCFProperty(self.value, NSString(string: key), kCFAllocatorDefault, options)
    }

    ///Gets an integer property from the entry
    public func getInteger<T: FixedWidthInteger>(forKey key: String) -> T?{
        return getProperty(forKey: key)?.takeRetainedValue() as? T
    }

    ///Gets a bool property from the entry
    public func getBool(forKey key: String) -> Bool?{
        return  getProperty(forKey: key)?.takeRetainedValue() as? CBool
    }
    
    ///Gets a data property from the entry
    public func getData(forKey key: String) -> Data?{
        guard let data = getProperty(forKey: key)?.takeRetainedValue() as? NSData else{
            return nil
        }
        
        return Data(referencing: data)
    }

    public func getString(forKey key: String) -> String?{
        guard let str = getProperty(forKey: key)?.takeRetainedValue() as? NSString else{
            return nil
        }
        
        return String(str)
    }
    
    public func setData(forKey key: String, value: Data) -> Bool{
        assert(!Sandbox.isEnabled, "IOKit write functions works only for non-sandboxed apps")
        let valueRef = NSData(data: value)
        
        return IORegistryEntrySetCFProperty(self.value, NSString(string: key), valueRef) == kIOReturnSuccess
    }
    
    ///Sets a string into the entry
    public func setString(forKey key: String, value: String) -> Bool {
        
        guard let data = value.data(using: .ascii) else{
            return false
        }
        
        return setData(forKey: key, value: data)
    }
    
    ///Sets an integer value into the entry
    public func setInteger<T: FixedWidthInteger>(forKey key: String, value: T) -> Bool {
        var val: T = value
        
        let data = Data(bytes: &val, count: MemoryLayout<T>.size)
        
        return setData(forKey: key, value: data)
    }
}

#endif
