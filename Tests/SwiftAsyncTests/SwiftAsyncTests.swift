import XCTest
@testable import Concurrency

import Foundation

class SwiftAsyncTests: XCTestCase {
    
    func testExample() {
        
        let task = Task.Value<Int>(value: 10)

        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {

            let a = try? task.wait()

            print(a!)
        }

        
        DispatchQueue(label: "aa").asyncAfter(deadline: .now()) {
            try? task.send(10)
        }
    
        sleep(3)
    }
    
    func testAsync() {
        
    }
    
    func testSelect() {
        
//        var a: Int = 0
//        coroutine {
//            a = 10
//            print(a)
//        }
//        
//        let coro = coroutine { Void -> Int in
//            return 0
//        }
        
        
//        func foo<T: Receiving>(aa: T) where T.Element == Int {
//            
//        }
//        
//        foo(aa: Task<Int>())
//        
//        select { when in
//            
//        }
    }
    
    func testWait() {
        
//        let con = DispatchCondition()
//        
//        con.signal()
//        con.wait()
//        print("a")
    }

    static var allTests : [(String, (SwiftAsyncTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
