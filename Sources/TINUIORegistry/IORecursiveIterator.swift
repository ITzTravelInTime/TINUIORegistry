//
//  IODeviceTreeRecursive.swift
//  Disk List
//
//  Created by Pietro Caruso on 03/08/21.
//

import Foundation

#if os(macOS)
import IOKit

public class IORecursiveIterator {
    private var child: io_registry_entry_t
    private var iterator: io_iterator_t
    private let plane: IOPlane
    private var memEntry: IOEntry? = nil
    
    //private let matching: CFDictionary = IOServiceMatching(kIOServicePlane)
    
    internal required init(child: io_registry_entry_t, iterator: io_iterator_t, plane: IOPlane, reset: Bool){
        self.child = child
        self.iterator = iterator
        self.plane = plane
        
        if reset{
            self.reset()
        }
    }
    
    public convenience init(plane: IOPlane = .service){
        self.init(child: 0, iterator: 0, plane: plane, reset: true)
    }
    
    deinit {
        if IOIteratorIsValid(iterator) != 0{
            reset()
        }
    }
    
    public var entry: IOEntry?{
        if memEntry != nil{
            return memEntry
        }
        
        let pathName = UnsafeMutablePointer<io_string_t>.allocate(capacity: 1);
                            
        let int8NamePointer = UnsafeMutableRawPointer(pathName).bindMemory(to: Int8.self,capacity: 1)
                            
        if IORegistryEntryGetPath(child, self.plane.iOKitName, int8NamePointer) != kIOReturnSuccess{
            return nil
        }
        
        memEntry = IOEntry(fromRegistryPath: String(cString: int8NamePointer), options: IOOptionBits(kIORegistryIterateRecursively))
        
        return memEntry
    }
    
    
    public func next() -> Bool{
        child = IOIteratorNext(iterator)
        memEntry = nil
        
        return child != 0
    }
    
    public func parentIterator(inPlane plane: IOPlane) -> Self{
        
        var iter: io_iterator_t = 0
        
        IORegistryEntryGetParentIterator(child, plane.iOKitName, &iter)
        
        return Self.init(child: 0, iterator: iter, plane: plane, reset: false)
    }
    
    public func parentIterator() -> Self{
        return parentIterator(inPlane: self.plane)
    }
    
    public func parent() -> io_registry_entry_t?{
        var parent: io_registry_entry_t = 0
        IORegistryEntryGetParentEntry(child, kIOServicePlane, &parent)
        
        if parent == 0{
            return nil
        }
        
        return parent
    }
    
    public func reset(){
        IOObjectRelease(child)
        child = 0
        IOIteratorReset(iterator)
        IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(plane.iOKitName), &iterator)
        child = IOIteratorNext(iterator)
    }
}

#endif
