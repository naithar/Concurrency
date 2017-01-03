import XCTest
@testable import SwiftAsync

class SwiftAsyncTests: XCTestCase {
    
    func testExample() {
        
        let task = Task<Int>()
        
        DispatchQueue.global().async {
            
            let a = try? task.receive(timeout: .now() + .seconds(1))
            
            print(a)
        }
        
        DispatchQueue(label: "aa").asyncAfter(deadline: .now() + 1) {
            try? task.send(value: 10)
        }
        
        sleep(3)
    }

    static var allTests : [(String, (SwiftAsyncTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
