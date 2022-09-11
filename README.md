# TINUIORegistry
A Swift library to access information from the IORegistry in a Swift-friendly easy-to-use way.

## Features and usage

**Reading the NVRAM:**

This feature allows you to access the system NVRAM to gather values, here is an exmaple: 

(WARNING: This feature might not work with sandboxed apps)

```swift
import TINUIORegistry

let boot_args = TINUIORegistry.IONVRAM.getString("boot-args") ?? "[Fail]"

print(boot_args)

```

**Getting a list of disks and partitions with some info:**

This feature allows you to get a list of disks and patitions taken from the IORegistry.

This example lists all the BSD names of available disks and partitions: 

```swift
import TINUIORegistry

let list = TINUIORegistry.IODeviceTreeDisk.simpleList()

for item in list{
    print(item.DeviceIdentifier.rawValue)
}

```

**Iterating trought the IORegistry entries:**

This feature allows for recursive iteration trought the IORegistry tree structure entry by entry.

In this example it's used to find the RTC entry (for an intel mac) and then prints it's property table:

```swift
import TINUIORegistry

let iterator = IORecursiveIterator(plane: .service) // creates an iterator object

while iterator.next(){ //executes the iterations
    
    guard let entry = iterator.entry else{ //Tries to get the current registry entry pointed by the iterator.
        continue
    }
    
    guard let name = entry.getName() else{ //Gets the name of the obtained entry
        continue
    }
    
    //print(name)
    
    if name != "TMR" && name != "RTC" && name != "RTC0" && name != "RTC1"{ //checks if the entry name is that of the RTC device
        continue
    }
    
    //gets and prints the property table of the entry
    for i in entry.getRawPropertyTable() ?? [:]{
        print(i)
    }
    
    break //exits from the loop
}

```

**Using specific IORegistry entries:**

It's possible to interact with registry entries by initializing a new `IOEntry` object from a string containing a IORegistry entry's path.

Here is an example in which an `IOEntry` object is initialised using the registry path to the system nvram and then the "boot-arg" value is retrived from it:

```swift

import TINUIORegistry

let nvram = IOEntry(fromRegistryPath: "IODeviceTree:/options", plane: .service)

let boot_args = nvram?.getString("boot-args") ?? "[Fail]"

print(boot_args)

```

## Who should use this Library?

This library should be used by swift apps/programs for macOS that needs to retrive information from the IORegistry.

This code is intended for macOS only since it requires the system library 'IOKit'.

## About the project

This code was created for of my [TINU project](https://github.com/ITzTravelInTime/TINU) and it has been made into it's own library to make the main project's source less complex and more focused on it's aim. 

Also having this as it's own library allows for code to be updated separately and so various versions of the main TINU app will be able to be compiled all with the latest version of this library.

## Libraries used:

- [ITzTravelInTime/SwiftPackagesBase](https://github.com/ITzTravelInTime/SwiftPackagesBase) - Created, developed and maintained by ITzTravelInTime

## Credits

 - ITzTravelInTime (Pietro Caruso) - Project creator and main developer

## Contacts

 - ITzTravelInTime (Pietro Caruso): piecaruso97@gmail.com

## Legal info

TINUNotifications: A Swift library to access information from the IORegistry in a Swift-friendly easy-to-use way.
Copyright (C) 2022 Pietro Caruso

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
