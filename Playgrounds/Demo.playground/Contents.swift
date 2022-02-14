import Foundation
import TINUIORegistry

print(TINUIORegistry.IONVRAM.getString(forKey: "boot-args") ?? "[Fail]")
print(TINUIORegistry.IODeviceTreeDisk.simpleList())

let iterator = IORecursiveIterator(plane: .service)

while iterator.next(){
    
    guard let entry = iterator.entry else{
        continue
    }
    
    guard let name = entry.getName() else{
        continue
    }
    
    //print(name)
    
    if name != "TMR"{
        continue
    }
    
    for i in entry.getPropertyTable() ?? [:]{
        print(i)
    }
    
    break
}
