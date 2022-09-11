/*
 TINUNotifications: A library for sandbox-friendly retrival of information about disks and partitions present in the current macOS system.
 Copyright (C) 2022 Pietro Caruso

 This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

 */

import Foundation

#if os(macOS) || targetEnvironment(macCatalyst)

import IOKit
import SwiftPackagesBase

///Type used to interact with registry entries
public class IOEntry: FetchProtocolDataInstance{
    private let value: io_registry_entry_t
    private let options: IOOptionBits
    private let avoidRelease: Bool
    private (set) public var plane: IOPlane = .service
    
    private var memParent: IOEntry? = nil
    private var memChild: IOEntry? = nil
    
    ///Initializes a new instance from a registry entry path
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
        memChild = nil
        memParent = nil
    }
    
    ///Gets the IORegistryEntry name for the current instance
    public func getEntryName(usingPlane: Bool = false) -> String?{
        return MemoryManagement.getString(bufferSize: 1024, { cString in
            if usingPlane{
                if IORegistryEntryGetNameInPlane(value, plane.iOKitName, cString) != kIOReturnSuccess{
                    return false
                }
            }else{
                if IORegistryEntryGetName(value, cString) != kIOReturnSuccess{
                    return false
                }
            }
            
            return true
        })
        
    }
    
    ///If the entry has a name property, encoded either as data or as a string this function returns it, otherwise nil is returned.
    public func getNameProperty() -> String?{
        if var name = getString("name"){
            if name.last == "\0"{
                name.removeLast()
            }
            
            return name
        }
        
        if var name = getStringData("name"){
            if name.last == "\0"{
                name.removeLast()
            }
            
            return name
        }
        
        return nil
    }
    
    ///Gets the main name for the current entry, either the IORegistry name or the name property value
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
    
    ///Returns the IORegistry path of the entry
    public func getPath() -> String?{
        return value.getPath(relativeTo: plane)
    }
        
    ///Returns the parent entry of the current entry
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
    
    ///Returns the first child entry of the current entry
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
    
    @available(*, deprecated, renamed: "getRawPropertyTable" )
    public func getPropertyTable() -> [String: Any]?{
        return getRawPropertyTable()
    }
    
    ///Returns the complete property table of the current entry, including the values
    public func getRawPropertyTable() -> [String: Any]?{
        var tdict: Unmanaged<CFMutableDictionary>? = nil
        
        if IORegistryEntryCreateCFProperties(value, &tdict, kCFAllocatorDefault, options) != kIOReturnSuccess{
            return nil
        }
        
        guard let dict: NSDictionary = tdict?.takeRetainedValue()  else{
            return nil
        }
        
        var ret: [String: Any] = [:]
        
        for (_, obj) in dict.enumerated(){
            ret["\(obj.key)"] = obj.value
        }
        
        return ret
    }
    
    @available(*, deprecated, renamed: "getRawProperty" )
    public func getProperty(_ key: String) -> CFTypeRef?{
        return getRawProperty(key)
    }
    
    ///Returns the specified property, if it exists in the entry's property table, otherwise nil is returned.
    public func getRawProperty(_ key: String) -> CFTypeRef?{
        
        let namePointer = UnsafeMutablePointer<NSString>.allocate(capacity: 1)
        defer{
            namePointer.deallocate()
        }
        
        namePointer.pointee = NSString(string: key)
        
        var ret: CFTypeRef? = nil
        
        ret = IORegistryEntryCreateCFProperty(self.value, namePointer.pointee, kCFAllocatorDefault, options)?.takeRetainedValue()
        
        return ret
    }
    
    @available(*, deprecated, renamed: "getRawPropertyTableOfTypeFiltered" )
    public func getTypeProperties<T: CFTypeRef>(_ keys: [String]) -> [String: T]?{
        return getRawPropertyTableOfTypeFiltered(list: keys, returnsNilIfListedPropertiesAreMissing: true)
    }
    
    ///Returns all of the properties in the IOEntry's property table that are of the type specified by the reciever that are also included into the list.
    ///
    ///     Returns: `nil` if the property table can't be fetched or the `returnsNilIfListedPropertiesAreMissing` parameter is set to `true` and entries from the `list` parameter are missing from the raw property table. An empty dictionary is returned if there isn't any property of the specified Type in the table.
    public func getRawPropertyTableOfTypeFiltered<T: CFTypeRef>(list keys: [String], returnsNilIfListedPropertiesAreMissing: Bool = true) -> [String: T]?{
        
        guard let table: [String: T] = getRawPropertyTableOfType() else { return nil }
        
        if keys.filter({ table.keys.contains($0) }).isEmpty && returnsNilIfListedPropertiesAreMissing{
            return nil
        }
        
        return table.filter({ keys.contains( $0.key ) })
    }
    
    ///Returns all of the properties in the IOEntry's property table that are of the type specified by the reciever.
    ///
    ///     Returns: `nil` if the property table can't be fetched and an empty dictionary if there isn't any property of the specified Type in the table.
    public func getRawPropertyTableOfType<T: CFTypeRef>() -> [String: T]?{
        
        guard let table = getRawPropertyTable() else { return nil }
        
        var ret = [String: T]()
        
        for i in table {
            guard let property = i.value as? T else{
                continue
            }
            
            ret[i.key] = property
        }
        
        return ret
    }

    ///Returns the specified interger property, if it exists in the entry's property table, otherwise nil is returned.
    public func getInteger<T: FixedWidthInteger>(_ key: String) -> T?{
        return getRawProperty(key) as? T
    }

    ///Returns the specified bool property, if it exists in the entry's property table, otherwise nil is returned.
    public func getBool(_ key: String) -> Bool?{
        return  getRawProperty(key) as? CBool
    }
    
    ///Returns the specified data property, if it exists in the entry's property table, otherwise nil is returned.
    public func getData(_ key: String) -> Data?{
        guard let obj = getRawProperty(key) else{
            return nil
        }
        
        guard let data = obj as? NSData else{
            return nil
        }
        
        return Data(referencing: data)
    }

    ///Returns the specified string property, if it exists in the entry's property table, otherwise nil is returned.
    public func getString(_ key: String) -> String?{
        guard let obj = getRawProperty(key) else{
            return nil
        }
        
        guard let str = obj as? NSString else{
            return nil
        }
        
        return String(str)
    }
    
    ///Returns the specified data property, if it exists in the entry's property table, encoded as a string, otherwise nil is returned.
    public func getStringData(_ key: String) -> String?{
        guard let data = getData(key) else{
            return nil
        }
        
        return String(data: data, encoding: .ascii)
    }
    
    ///Returns the specified data property, if it exists in the entry's property table, encoded as the specified Integer type (if possible), otherwise nil is returned.
    public func getIntegerData<T: FixedWidthInteger>(_ key: String) -> T?{
        guard let data = getData(key) else{
            return nil
        }
        
        if data.count != MemoryLayout<T>.size{
            return nil
        }
        
        let ret = Data(data).withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return rawPtr.load(as: T.self)
        })
                    
        return ret
    }
    
    /*
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
    }*/
}

#endif
