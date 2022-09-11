
#if os(macOS) || targetEnvironment(macCatalyst)
import XCTest
@testable import TINUIORegistry

final class TINUIORegistryTests: XCTestCase {
    func testFetch() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        //XCTAssertEqual(TINUIOKit().text, "Hello, World!")
        
        XCTAssertNotEqual(TINUIORegistry.IONVRAM.getString("boot-args"), "Can't get the boot args from IOKit!!")

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
            
            for i in entry.getRawPropertyTable() ?? [:]{
                print(i)
            }
            
            break
        }
    }
}
#endif
