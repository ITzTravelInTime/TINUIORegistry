import Foundation
import TINUIORegistry

print(TINUIORegistry.IONVRAM.getString(forKey: "boot-args") ?? "[Fail]")
print(TINUIORegistry.IODeviceTreeDisk.simpleList())
