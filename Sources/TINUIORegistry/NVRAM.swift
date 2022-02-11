
import Foundation

#if os(macOS)

public let IONVRAM = IOEntry(fromRegistryPath: "IODeviceTree:/options", plane: .service)!

#endif
