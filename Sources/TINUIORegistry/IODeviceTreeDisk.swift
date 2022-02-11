//
//  IOKitList.swift
//  Disk List
//
//  Created by Pietro Caruso on 03/08/21.
//

import Foundation

#if os(macOS)
public struct IODeviceTreeDisk: DiskProtocol{
    public var DeviceIdentifier: BSDID
    public let ejectable: Bool
    public let removable: Bool
    public let Content: String?
    public let Size: UInt64
    public let whole: Bool
    public let writable: Bool
    public let uuid: UUID?
    public let name: String?
    public let leaf: Bool
    
    private(set) var backupID: UUID? = UUID()
    
    public var id: UUID{
        return uuid ?? backupID!
    }
    
    public static func simpleList() -> [Self]{
        let iterator = IORecursiveIterator()
        var disks = [Self]()
        
        while iterator.next(){
            guard let bsdNameString = iterator.entry?.getString(forKey: "BSD Name") else{
                continue
            }
            
            guard BSDID.isValid(bsdNameString) else {
                continue
            }
            
            let bsdName = BSDID(bsdNameString)
            
            guard let ejectable = iterator.entry?.getBool(forKey: "Ejectable"), let removable = iterator.entry?.getBool(forKey: "Removable"), let content = iterator.entry?.getString(forKey: "Content"), let size: UInt64 = iterator.entry?.getInteger(forKey: "Size"), let whole = iterator.entry?.getBool(forKey: "Whole"), let writable = iterator.entry?.getBool(forKey: "Writable"), let leaf = iterator.entry?.getBool(forKey: "Leaf") else{
                continue
            }
            
            let name = iterator.entry?.getString(forKey: "FullName")
            
            var uuid: UUID? = nil
            
            if let tuuid = iterator.entry?.getString(forKey: "UUID"){
                uuid = UUID(uuidString: tuuid)
            }
            
            disks.append(.init(DeviceIdentifier: bsdName, ejectable: ejectable, removable: removable, Content: content, Size: size, whole: whole, writable: writable, uuid: uuid, name: name, leaf: leaf))
        }
        
        return disks.sorted(by: { ($0.DeviceIdentifier.driveNumber ?? 0 <= $1.DeviceIdentifier.driveNumber ?? 0) && ($0.DeviceIdentifier.partitionNumber ?? 0 <= $1.DeviceIdentifier.partitionNumber ?? 0) && ($0.DeviceIdentifier.driveNumbers().count <= $1.DeviceIdentifier.driveNumbers().count ) })
    }
}

@available(macOS 10.14, *) extension IODeviceTreeDisk: Identifiable{
    
}

#endif
