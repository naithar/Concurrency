import XCTest
@testable import SwiftAsync

import Foundation

class SwiftAsyncTests: XCTestCase {
    
    func testExample() {
        
        let task = Task<Int>()
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            
            let a = try? task.receive()
            
            print(a)
        }
        
        
        DispatchQueue(label: "aa").asyncAfter(deadline: .now()) {
            try? task.send(10)
        }
        
        sleep(3)
    }
    
    func testAsync() {
        
        let task = async(1)
        let value = try! await(task)
        
        print(value)
    }
    
    func testSelect() {
        
        select { when in
            
        }
    }
    
    func testWait() {
        
        let con = DispatchCondition()
        
        con.signal()
        con.wait()
        print("a")
    }

    static var allTests : [(String, (SwiftAsyncTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
