import Foundation
import TINUIORegistry

print(TINUIORegistry.IONVRAM.getString(forKey: "boot-args") ?? "[Fail]")
print(TINUIORegistry.IODeviceTreeDisk.simpleList())

let iterator = IORecursiveIterator(plane: .service)

while iterator.next(){
    
    guard let entry = iterator.entry else{
        continue
    }
    
    guard var name = entry.getStringData(forKey: "name") else{
        continue
    }
    
    name.removeLast()
    
    //print(name)
    
    if name != "PNP0B00"{
        continue
    }
    
    guard let memory = entry.getProperty(forKey: "IODeviceMemory") as? [[[String: UInt]]] else{
        continue
    }
    
    print(memory)
}
