//
//  IODeviceTreeRecursive.swift
//  Disk List
//
//  Created by Pietro Caruso on 03/08/21.
//

import Foundation

#if os(macOS)
import IOKit

///type used to perform recursive iterations trought the IORegistry tree structure
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
    
    ///The current entry pointed by the recursive iteration
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
    
    ///Makes the recursive iteration go to the next step
    public func next() -> Bool{
        child = IOIteratorNext(iterator)
        memEntry = nil
        
        return child != 0
    }
    
    ///Gets the parent entry of the current entry pointed by the iteration process
    public func parent() -> io_registry_entry_t?{
        var parent: io_registry_entry_t = 0
        IORegistryEntryGetParentEntry(child, kIOServicePlane, &parent)
        
        if parent == 0{
            return nil
        }
        
        return parent
    }
    
    ///Resets the iteration process to the beginning
    public func reset(){
        IOObjectRelease(child)
        child = 0
        IOIteratorReset(iterator)
        IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(plane.iOKitName), &iterator)
        child = IOIteratorNext(iterator)
    }
}

#endif
