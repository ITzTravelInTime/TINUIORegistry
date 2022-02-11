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
    private var memEntry: IOEntry? = nil
    
    public let plane: IOPlane
    
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
        
        guard let entryPath = child.getPath(relativeTo: self.plane) else{
            return nil
        }
        
        memEntry = IOEntry(fromRegistryPath: entryPath, options: IOOptionBits(kIORegistryIterateRecursively), plane: plane)
        
        return memEntry
    }
    
    public func next() -> Bool{
        child = IOIteratorNext(iterator)
        memEntry = nil
        
        return child != 0
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
