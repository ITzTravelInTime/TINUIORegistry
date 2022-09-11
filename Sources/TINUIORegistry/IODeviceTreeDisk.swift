/*
 TINUNotifications: A library for sandbox-friendly retrival of information about disks and partitions present in the current macOS system.
 Copyright (C) 2022 Pietro Caruso

 This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

 */

import Foundation

#if os(macOS) || targetEnvironment(macCatalyst)

public struct IODeviceTreeDisk: DiskProtocol{
    ///The disk/partition BSD name, this object provvides useful methods to gather some extra info about this device.
    public var DeviceIdentifier: BSDID
    ///Let's you know if the current device/partition can be ejected.
    public let ejectable: Bool
    ///Let's you know if the current device/partition can be removed from the computer (aka hot swapped).
    public let removable: Bool
    ///Returns, if available, more info about the current device/partition, like the file system name.
    public let Content: String?
    ///The size in bytes of the current device/partition.
    public let Size: UInt64
    ///Let's you know if the current object is a whole disk (and so not a partition).
    public let whole: Bool
    ///Let's you know if the current disk/partition can be written on.
    public let writable: Bool
    ///The disk/partition UUID.
    public let uuid: UUID?
    ///The name (or tag, if available) of the current disk/partition.
    public let name: String?
    ///Let's you know if this disk/partition is a subdevice
    public let leaf: Bool
    
    private(set) var backupID: UUID? = UUID()
    
    ///This object's UUID to be used for the `Identifiable` protocol
    public var id: UUID{
        return uuid ?? backupID!
    }
    
    ///Returns a list of disks and partitions and relative info
    public static func simpleList() -> [Self]{
        let iterator = IORecursiveIterator()
        var disks = [Self]()
        
        while iterator.next(){
            guard let bsdNameString = iterator.entry?.getString("BSD Name") else{
                continue
            }
            
            guard BSDID.isValid(bsdNameString) else {
                continue
            }
            
            let bsdName = BSDID(bsdNameString)
            
            guard let ejectable = iterator.entry?.getBool("Ejectable"), let removable = iterator.entry?.getBool("Removable"), let content = iterator.entry?.getString("Content"), let size: UInt64 = iterator.entry?.getInteger("Size"), let whole = iterator.entry?.getBool("Whole"), let writable = iterator.entry?.getBool("Writable"), let leaf = iterator.entry?.getBool("Leaf") else{
                continue
            }
            
            let name = iterator.entry?.getString("FullName") ?? iterator.entry?.getName()
            
            var uuid: UUID? = nil
            
            if let tuuid = iterator.entry?.getString("UUID"){
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
