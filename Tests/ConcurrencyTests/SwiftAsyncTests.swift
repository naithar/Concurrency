import XCTest
@testable import Concurrency

import Dispatch
import Foundation

class ConcurrencyTests: XCTestCase {
    
    enum Error: Swift.Error {
        case er
    }
    
    func testSend() {
        let expectation = self.expectation(description: "expectation")
        var value = 0
        
        let task = Task<Int>()
            .done { value = $0 * 2 }
            .always { _ in expectation.fulfill() }
        
        task.send(10)
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(20, value)
        }
    }
    
    func testThrow() {
        let expectation = self.expectation(description: "expectation")
        var taskError: Swift.Error?
        
        let task = Task<Int>()
            .catch { taskError = $0 }
            .always { _ in expectation.fulfill() }
        
        task.throw(Error.er)
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertNotNil(taskError)
        }
    }
    
    func testRecover() {
        var expectation = self.expectation(description: "expectation")
        var taskError: Swift.Error?
        var value = 0
        
        var task = Task<Int>()
            .done { value = $0 * 2 }
            .catch { taskError = $0 }
            .recover { _ in 10 }
            .always { _ in expectation.fulfill() }
        
        task.throw(Error.er)
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertNil(taskError)
            XCTAssertEqual(20, value)
        }
        
        expectation = self.expectation(description: "expectation")
        value = 0
        task = Task<Int>()
            .done { value = $0 * 2 }
            .catch { taskError = $0 }
            .recover { throw $0 }
            .always { _ in expectation.fulfill() }
        
        task.throw(Error.er)
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertNotNil(taskError)
            XCTAssertEqual(0, value)
        }
    }
    
    func testInitializerBuild() {
        let expectation = self.expectation(description: "expectation")
        var value = 0
        
        Task<Int> { task in
            task.send(10)
            }
            .done { value = $0 * 2 }
            .always { _ in expectation.fulfill() }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(20, value)
        }
    }
    
    func testInitializerValue() {
        let expectation = self.expectation(description: "expectation")
        var value = 0
        
        Task<Int>(value: 10)
            .done { value = $0 * 2 }
            .always { _ in expectation.fulfill() }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(20, value)
        }
    }
    
    func testInitializerState() {
        let expectation = self.expectation(description: "expectation")
        var value = 0
        
        Task<Int>(state: .finished(10))
            .done { value = $0 * 2 }
            .always { _ in expectation.fulfill() }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(20, value)
        }
    }
    
    func testChain() {
        var expectation = self.expectation(description: "expectation")
        var value = 0
        
        Task<Int>(value: 10)
            .then { $0 + 5 }
            .then { $0 * 2 }
            .recover { _ in 40 }
            .then { value = $0 }
            .always { _ in expectation.fulfill() }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(30, value)
        }
        
        
        expectation = self.expectation(description: "expectation")
        value = 0
        
        Task<Int>(value: 10)
            .then { $0 + 5 }
            .then { $0 * 2 }
            .then { _ in throw Error.er }
            .recover { _ in 40 }
            .then { value = $0 }
            .always { _ in expectation.fulfill() }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(40, value)
        }
    }
    
    func testQueue() {
        var expectation = self.expectation(description: "expectation")
        var value = 0
        var main = true
        
        Task<Int>(value: 10)
            .then { $0 + 5 }
            .then(on: .global()) { main = Thread.isMainThread; return $0 * 2 }
            .then { value = $0 }
            .always { _ in expectation.fulfill() }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(30, value)
            XCTAssertEqual(false, main)
        }
        
        expectation = self.expectation(description: "expectation")
        main = false
        value = 0
        
        Task<Int>(value: 10)
            .then { $0 + 5 }
            .then { $0 * 2 }
            .then { _ in throw Error.er }
            .recover { _ in 40 }
            .then(on: .main) { main = Thread.isMainThread; value = $0 }
            .always { _ in expectation.fulfill() }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(40, value)
            XCTAssertEqual(true, main)
        }
    }
    
    func testDelay() {
        let expectation = self.expectation(description: "expectation")
        var value = 0
        
        let delay = DispatchTime.now() + 2
        Task<Int>(value: 10)
            .then(delay: delay) { $0 * 2 }
            .done { print("delay \($0)"); value = $0 }
            .always { _ in print("delay"); expectation.fulfill() }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(20, value)
        }
    }
    
    func testUpdate() {
        let expectation = self.expectation(description: "expectation")
        var value = 0
        
        let task = Task<Int>(value: 10)
            .then(delay: .now() + 3) { $0 * 2 }
        
        DispatchQueue.main.async {
            task.then { $0 * 2 }
                .then { $0 + 5 }
                .done { value = $0 }
                .always { _ in expectation.fulfill() }
        }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(45, value)
        }
    }
    
    func testMultiple() {
        let expectation = self.expectation(description: "expectation")
        let e1 = self.expectation(description: "expectation1")
        let e2 = self.expectation(description: "expectation2")
        
        
        let task = Task<Int>(on: .main, value: 10)
            .then(on: .main) { _ in expectation.fulfill() }
        
        task.then(on: .main) { e1.fulfill() }
        
        task.then(on: .main) { e2.fulfill() }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
    }
    
    static var allTests : [(String, (ConcurrencyTests) -> () throws -> Void)] {
        return [
            ("testSend", testSend),
            ("testThrow", testThrow),
            ("testRecover", testRecover),
            ("testInitializerBuild", testInitializerBuild),
            ("testInitializerValue", testInitializerValue),
            ("testInitializerState", testInitializerState),
            ("testChain", testChain),
            ("testQueue", testQueue),
            ("testDelay", testDelay),
            ("testUpdate", testUpdate),
        ]
    }
}
