import XCTest
@testable import Concurrency

import Foundation

class SwiftAsyncTests: XCTestCase {
    
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
        
        self.wait(for: [expectation], timeout: 5)
        XCTAssertEqual(20, value)
    }
    
    func testThrow() {
        let expectation = self.expectation(description: "expectation")
        var error: Swift.Error?
        
        let task = Task<Int>()
            .catch { error = $0 }
            .always { _ in expectation.fulfill() }
        
        task.throw(Error.er)
        
        self.wait(for: [expectation], timeout: 5)
        XCTAssertNotNil(error)
    }
    
    func testRecover() {
        var expectation = self.expectation(description: "expectation")
        var error: Swift.Error?
        var value = 0
        
        var task = Task<Int>()
            .done { value = $0 * 2 }
            .catch { error = $0 }
            .recover { _ in 10 }
            .always { _ in expectation.fulfill() }
        
        task.throw(Error.er)
        
        self.wait(for: [expectation], timeout: 5)
        XCTAssertNil(error)
        XCTAssertEqual(20, value)
        
        expectation = self.expectation(description: "expectation")
        value = 0
        task = Task<Int>()
            .done { value = $0 * 2 }
            .catch { error = $0 }
            .recover { throw $0 }
            .always { _ in expectation.fulfill() }
        
        task.throw(Error.er)
        
        self.wait(for: [expectation], timeout: 5)
        XCTAssertNotNil(error)
        XCTAssertEqual(0, value)
    }
    
    func testInitializerBuild() {
        let expectation = self.expectation(description: "expectation")
        var value = 0
        
        Task<Int> { task in
                task.send(10)
            }
            .done { value = $0 * 2 }
            .always { _ in expectation.fulfill() }
        
        self.wait(for: [expectation], timeout: 5)
        XCTAssertEqual(20, value)
    }
    
    func testInitializerValue() {
        let expectation = self.expectation(description: "expectation")
        var value = 0
        
        Task<Int>(10)
            .done { value = $0 * 2 }
            .always { _ in expectation.fulfill() }
        
        self.wait(for: [expectation], timeout: 5)
        XCTAssertEqual(20, value)
    }
    
    func testInitializerState() {
        let expectation = self.expectation(description: "expectation")
        var value = 0
        
        Task<Int>(state: .finished(10))
            .done { value = $0 * 2 }
            .always { _ in expectation.fulfill() }
        
        self.wait(for: [expectation], timeout: 5)
        XCTAssertEqual(20, value)
    }
    
    func testChain() {
        var expectation = self.expectation(description: "expectation")
        var value = 0
        
        Task<Int>(10)
            .then { $0 + 5 }
            .then { $0 * 2 }
            .recover { _ in 40 }
            .then { value = $0 }
            .always { _ in expectation.fulfill() }
        
        self.wait(for: [expectation], timeout: 5)
        XCTAssertEqual(30, value)
        
        expectation = self.expectation(description: "expectation")
        value = 0
        
        Task<Int>(10)
            .then { $0 + 5 }
            .then { $0 * 2 }
            .then { _ in throw Error.er }
            .recover { _ in 40 }
            .then { value = $0 }
            .always { _ in expectation.fulfill() }
        
        self.wait(for: [expectation], timeout: 5)
        XCTAssertEqual(40, value)
    }
    
    func testQueue() {
        var expectation = self.expectation(description: "expectation")
        var value = 0
        var main = true
        
        Task<Int>(10)
            .then { $0 + 5 }
            .then(on: .global()) { main = Thread.isMainThread; return $0 * 2 }
            .then { value = $0 }
            .always { _ in expectation.fulfill() }
        
        self.wait(for: [expectation], timeout: 5)
        XCTAssertEqual(30, value)
        XCTAssertEqual(false, main)
        
        expectation = self.expectation(description: "expectation")
        main = false
        value = 0
        
        Task<Int>(10)
            .then { $0 + 5 }
            .then { $0 * 2 }
            .then { _ in throw Error.er }
            .recover { _ in 40 }
            .then(on: .main) { main = Thread.isMainThread; value = $0 }
            .always { _ in expectation.fulfill() }
        
        self.wait(for: [expectation], timeout: 5)
        XCTAssertEqual(40, value)
        XCTAssertEqual(true, main)
    }
    
    func testDelay() {
        let expectation = self.expectation(description: "expectation")
        var value = 0
        
        let delay = DispatchTime.now() + 2
        Task<Int>(10)
            .then(delay: delay) { $0 * 2 }
            .done { value = $0 }
            .always { _ in expectation.fulfill() }
        
        self.wait(for: [expectation], timeout: 5)
        XCTAssertEqual(20, value)
    }
    
    func testUpdate() {
        let expectation = self.expectation(description: "expectation")
        var value = 0
        
        let task = Task<Int>(10)
            .then(delay: .now() + 3) { $0 * 2 }
            
        DispatchQueue.global().async {
            task.then { $0 * 2 }
                .then { $0 + 5 }
                .done { value = $0 }
                .always { _ in expectation.fulfill() }
        }
        
        self.wait(for: [expectation], timeout: 6)
        XCTAssertEqual(45, value)
    }
    
    static var allTests : [(String, (SwiftAsyncTests) -> () throws -> Void)] {
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
