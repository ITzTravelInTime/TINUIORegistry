import Foundation

#if os(macOS)
import TINUIORegistry

print(TINUIORegistry.IONVRAM.getString("boot-args") ?? "[Fail]")
//print(TINUIORegistry.IODeviceTreeDisk.simpleList())

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
    
    for i in entry.getPropertyTable() ?? [:]{
        print(i)
    }
    
    break
}
#endif
