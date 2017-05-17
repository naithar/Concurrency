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
            .recover { _ in return 10 }
            
            
        task.then { $0 }
            .done { value = $0 * 2 }
            .catch { taskError = $0 }
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
        
        Task<Int>(value: 10)
            .then { $0 + 5 }
            .then(in: .global()) { return $0 * 2 }
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
            .then(in: .main) { value = $0 }
            .always { _ in expectation.fulfill() }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(40, value)
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
        
        
        let task = Task<Int>(in: .main, value: 10)
            .then(in: .main) { _ in expectation.fulfill() }
        
        task.then(in: .main) { e1.fulfill() }
        
        task.then(in: .main) { e2.fulfill() }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
    }
    
    func testWait() {
        var value = try? Task<Int>(value: 10)
            .then { $0 * 2 }
            .then { $0 + 5 }
            .wait()
    
        XCTAssertEqual(25, value)
        
        value = try? Task<Int>(value: 10)
            .then { $0 * 2 }
            .then(delay: .now() + 10) { $0 + 5 }
            .wait()
        
        XCTAssertEqual(25, value)
    }
    
    func testWaitTimeout() {
        var value = try? Task<Int>(value: 10)
            .then { $0 * 2 }
            .then(delay: .now() + 5) { $0 + 5 }
            .wait(for: .now() + .seconds(10))

        XCTAssertEqual(25, value)

        value = 0

        do {
            value = try Task<Int>(value: 10)
            .then { $0 * 2 }
            .then(delay: .now() + 5) { $0 + 5 }
            .wait(for: .now() + .seconds(1))

            XCTFail("should throw")
        } catch {
            switch error {
            case let error as TaskError where error == .timeout:
                XCTAssertTrue(true)
            default:
                XCTFail("wrong error")
            }
        }

        XCTAssertEqual(0, value)
    }
    
    func testCombine() {
        var expectation = self.expectation(description: "e")
        var intTask = Task<Int>()
        var stringTask = Task<String>()
        var boolTask = Task<Bool>()
        var result = [Any]()
        
        [intTask.as(Any.self), stringTask.as(Any.self), boolTask.as(Any.self)]
            .combine()
            .done { result = $0 }
            .always { _ in expectation.fulfill() }

        intTask.send(10)
        stringTask.send("task string")
        boolTask.send(true)
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(3, result.count)
            guard result.count == 3 else {
                XCTFail()
                return
            }
            XCTAssertEqual(10, result[0] as? Int)
            XCTAssertEqual("task string", result[1] as? String)
            XCTAssertEqual(true, result[2] as? Bool)
        }
        
        expectation = self.expectation(description: "e")
        intTask = Task<Int>()
        stringTask = Task<String>()
        boolTask = Task<Bool>()
        result = [Any]()
        
        [intTask.as(Any.self), stringTask.as(Any.self), boolTask.as(Any.self)]
            .combine()
            .done { result = $0 }
            .always { _ in expectation.fulfill() }
        
        
        intTask.send(10)
        stringTask.throw(Error.er)
        boolTask.send(true)
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(0, result.count)
        }
    }
    
    func testMapReduce() {
        let task = Task<[Any]>(value: [10, 30, "ss", true, "aa"])
        
        let filterArray = try? task.filter { $0 is String }.wait()
        XCTAssertEqual(["ss", "aa"], (filterArray ?? []).flatMap { $0 as? String })
        
        let mapArray = try? task.map { String.init(describing: $0) }.wait()
        XCTAssertEqual(["10", "30", "ss", "true", "aa"], mapArray ?? [])
        
        let flatMapArray = try? task.flatMap { $0 as? String }.wait()
        XCTAssertEqual(["ss", "aa"], (flatMapArray ?? []))
        
        let reduce = try? task.reduce(0) { $0 + (($1 as? Int) ?? 1) }.wait()
        XCTAssertEqual(43, reduce)
    }
    
    func testUnwrap() {
        
        let yield: Void = { return }()
        let e = self.expectation(description: "e")
        var value = 0
        
        Task<Void>(value: yield)
            .then { _ in return Task<Int>(value: 10) }
            .then { $0.then { $0 * 2 } }
            .unwrap()
            .then { $0 + 5 }
            .then { value = $0 }
            .always { _ in e.fulfill() }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(25, value)
        }
    }
    
    func testThenOnState() {
        
        var e = self.expectation(description: "e")
        var value = ""
        func foo(_ string: String) {
            value = string
        }
        
        var task = Task<Int>()
            
        task.then(on: .success) { _ in foo("success") }
            .always { _ in e.fulfill() }
        
        task.then(on: .fail) { _ in foo("fail") }
            .always { _ in e.fulfill() }
        
        task.send(10)
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual("success", value)
        }
        
        e = self.expectation(description: "e")
        task = Task<Int>()
            
        task.then(on: .success) { _ in foo("success") }
            .always { _ in e.fulfill() }
        
        task.then(on: .fail) { $0 }
            .catch { _ in foo("fail") }
            .always { _ in e.fulfill() }
        
        task.throw(Error.er)
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual("fail", value)
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
            ("testMultiple", testMultiple),
            ("testWait", testWait),
            ("testWaitTimeout", testWaitTimeout),
            ("testCombine", testCombine),
            ("testUnwrap", testUnwrap),
        ]
    }
}
