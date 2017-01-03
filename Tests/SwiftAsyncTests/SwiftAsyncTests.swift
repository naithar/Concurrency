import XCTest
@testable import SwiftAsync

import Foundation

class SwiftAsyncTests: XCTestCase {
    
    func testExample() {
        
        let task = Task<Int>()
        
        DispatchQueue.global().async {
            
            let a = try? task.receive()
            
            print(a)
        }
        
        
        DispatchQueue(label: "aa").asyncAfter(deadline: .now() + 1) {
            try? task.send(10)
        }
        
        sleep(3)
    }
    
    func testAsync() {
        
        let task = async(1)
        let value = try! await(task)
        
        print(value)
    }

    static var allTests : [(String, (SwiftAsyncTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
