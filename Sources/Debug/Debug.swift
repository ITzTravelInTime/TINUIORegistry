/*
 TINUNotifications: A Swift library to access information from the IORegistry in a Swift-friendly easy-to-use way.
 Copyright (C) 2022 Pietro Caruso

 This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

import Foundation

//#if DEBUG

#if os(macOS) || targetEnvironment(macCatalyst)
import TINUIORegistry
import IOKit
#endif

//TODO: Activate or de-activate the dumps using command line args
final class Debugs{
    #if os(macOS) || targetEnvironment(macCatalyst)
    static var list: [() -> ()] = [debugProperty, debugPropertyTable, debugDisk]
    
    static func debugProperty(){
        //for _ in 0...30{
            print("Attempting at gathering the system boot args: ")
            print(TINUIORegistry.IONVRAM.getString("boot-args") ?? "[Fail]")
            print("Attempt completed.\n\n")
        //}
    }
    
    static func debugPropertyTable(){
        print("Attempting at getting a dump of the RTC Device's registry entry: ")
        let iterator = IORecursiveIterator(plane: .service)
        
        while iterator.next(){
            
            guard let entry = iterator.entry else{
                continue
            }
            
            guard let name = entry.getEntryName() else{
                continue
            }
            
            //print(name)
            
            if name != "TMR" && name != "RTC" && name != "RTC0" && name != "RTC1"{
                continue
            }
            
            print("Registry entry found, dumping: ")
            
            for i in entry.getRawPropertyTable() ?? [:]{
                print(i)
            }
            
            print("Attempt sucessul")
            return
        }
        print("Attempt failed, no property found for the RTC device.")
    }
    
    static func debugDisk(){
        
    }
    
    #else
    static var list: [() -> ()] = []
    #endif
}
//#endif
