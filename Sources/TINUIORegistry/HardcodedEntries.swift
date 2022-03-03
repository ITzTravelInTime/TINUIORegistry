
import Foundation

#if os(macOS)

///NVRAM registry entry
public let IONVRAM = IOEntry(fromRegistryPath: "IODeviceTree:/options", plane: .service)!

#endif
