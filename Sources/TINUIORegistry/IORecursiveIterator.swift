/*
 TINUNotifications: A library for sandbox-friendly retrival of information about disks and partitions present in the current macOS system.
 Copyright (C) 2022 Pietro Caruso

 This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

 */

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
