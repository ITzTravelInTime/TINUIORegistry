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
    private (set) public var plane: IOPlane = .service
    
    private var memParent: IOEntry? = nil
    private var memChild: IOEntry? = nil
    
    public convenience init?(fromRegistryPath path: String, options: IOOptionBits = 0, plane: IOPlane = .service){
        let entry = IORegistryEntryFromPath(IOServiceGetMatchingService(kIOMasterPortDefault, nil), path)
        
        if entry == MACH_PORT_NULL{
            return nil
        }
        
        self.init(value: entry, options: options, plane: plane)
    }
    
    internal required init?(value: io_registry_entry_t, options: IOOptionBits = 0, avoidRelease: Bool = false, plane: IOPlane = .service) {
        if value == 0 || value == MACH_PORT_NULL{
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
    
    public func getEntryName(usingPlane: Bool = false) -> String?{
        let pathName = UnsafeMutablePointer<io_string_t>.allocate(capacity: 1);
                            
        let int8NamePointer = UnsafeMutableRawPointer(pathName).bindMemory(to: Int8.self,capacity: 1)
        
        if usingPlane{
            if IORegistryEntryGetNameInPlane(value, plane.iOKitName, int8NamePointer) != kIOReturnSuccess{
                return nil
            }
        }else{
            if IORegistryEntryGetName(value, int8NamePointer) != kIOReturnSuccess{
                return nil
            }
        }
        
        return String(cString: int8NamePointer)
    }
    
    public func getNameProperty() -> String?{
        if var name = getString(forKey: "name"){
            if name.last == "\0"{
                name.removeLast()
            }
            
            return name
        }
        
        if var name = getStringData(forKey: "name"){
            if name.last == "\0"{
                name.removeLast()
            }
            
            return name
        }
        
        return nil
    }
    
    public func getName() -> String?{
        if let name = getEntryName(){
            return name
        }
        
        if let name = getEntryName(usingPlane: true){
            return name
        }
        
        if let name = getNameProperty(){
            return name
        }
        
        return nil
    }
    
    
    
    public func getPath() -> String?{
        return value.getPath(relativeTo: plane)
    }
        
    public var parentEntry: IOEntry?{
        
        if memParent != nil{
            return memParent
        }
        
        guard let entry = value.getParentEntry(relativeTo: self.plane) else{
            return nil
        }
        
        guard let entryPath = entry.getPath(relativeTo: self.plane) else{
            return nil
        }
        
        memParent = IOEntry(fromRegistryPath: entryPath, options: IOOptionBits(kIORegistryIterateRecursively), plane: plane)
        
        IOObjectRelease(entry)
        
        return memParent
    }
    
    public var firstChildEntry: IOEntry?{
        
        if memChild != nil{
            return memChild
        }
        
        guard let entry = value.getFirstChildEntry(relativeTo: self.plane) else{
            return nil
        }
        
        guard let entryPath = entry.getPath(relativeTo: self.plane) else{
            return nil
        }
        
        memChild = IOEntry(fromRegistryPath: entryPath, options: IOOptionBits(kIORegistryIterateRecursively), plane: plane)
        
        IOObjectRelease(entry)
        
        return memChild
    }
    
    public func getPropertyTable() -> [String: Any]?{
        var tdict: Unmanaged<CFMutableDictionary>? = nil
        
        if IORegistryEntryCreateCFProperties(value, &tdict, kCFAllocatorDefault, options) != kIOReturnSuccess{
            return nil
        }
        
        guard let dictionary: NSDictionary = tdict?.takeRetainedValue() else{
            //tdict?.release()
            return nil
        }
        
        var ret: [String: Any] = [:]
        
        for (_, obj) in dictionary.enumerated(){
            ret["\(obj.key)"] = obj.value
        }
        
        //tdict?.release()
        return ret
    }
    
    ///reads a generic property from the entry
    public func getProperty(forKey key: String) -> CFTypeRef?{
        guard let property = IORegistryEntryCreateCFProperty(self.value, NSString(string: key), kCFAllocatorDefault, options) else{
            return nil
        }
        
        let ret: CFTypeRef? = property.takeRetainedValue()
        
        property.release()
        
        return ret
    }
    
    public func getTypeProperties<T: CFTypeRef>(forKeys keys: [String]) -> [String: T]?{
        var ret = [String: T]()
        
        for i in keys{
            guard let property = getProperty(forKey: i) as? T else{
                return nil
            }
            
            ret[i] = property
        }
        
        return ret
    }

    ///Gets an integer property from the entry
    public func getInteger<T: FixedWidthInteger>(forKey key: String) -> T?{
        return getProperty(forKey: key) as? T
    }

    ///Gets a bool property from the entry
    public func getBool(forKey key: String) -> Bool?{
        return  getProperty(forKey: key) as? CBool
    }
    
    ///Gets a data property from the entry
    public func getData(forKey key: String) -> Data?{
        guard let data = getProperty(forKey: key) as? NSData else{
            return nil
        }
        
        return Data(referencing: data)
    }

    public func getString(forKey key: String) -> String?{
        guard let str = getProperty(forKey: key) as? NSString else{
            return nil
        }
        
        return String(str)
    }
    
    public func getStringData(forKey key: String) -> String?{
        guard let data = getData(forKey: key) else{
            return nil
        }
        
        return String(data: data, encoding: .ascii)
    }
    
    public func setProperty(forKey key: String, value: CFTypeRef!) -> Bool{
        assert(!Sandbox.isEnabled, "IOKit write functions works only for non-sandboxed apps")
        
        return IORegistryEntrySetCFProperty(self.value, NSString(string: key), value) == kIOReturnSuccess
    }
    
    public func setData(forKey key: String, value: Data) -> Bool{
        return setProperty(forKey: key, value: NSData(data: value))
    }
    
    ///Sets a string into the entry
    public func setStringData(forKey key: String, value: String) -> Bool {
        
        guard let data = value.data(using: .ascii) else{
            return false
        }
        
        return setData(forKey: key, value: data)
    }
    
    public func setString(forKey key: String, value: String) -> Bool {
       return setProperty(forKey: key, value: NSString(utf8String: value))
    }
    
    ///Sets an integer value into the entry
    public func setIntegerData<T: FixedWidthInteger>(forKey key: String, value: T) -> Bool {
        var val: T = value
        
        let data = Data(bytes: &val, count: MemoryLayout<T>.size)
        
        return setData(forKey: key, value: data)
    }
    
    ///Sets an integer value into the entry
    public func setInteger<T: FixedWidthInteger>(forKey key: String, value: T) -> Bool {
        return setProperty(forKey: key, value: NSNumber(nonretainedObject: String(value).uInt64Value))
    }
}

#endif
