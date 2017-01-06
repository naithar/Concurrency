//
//  TaskValue.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 03.01.17.
//
//

import Dispatch

public enum TaskValueError: Swift.Error {
    case notEmpty
    case empty
}

let TaskValueIDGenerator = IDGenerator(key: "task-value")


public final class TaskValue<T>: TaskProtocol {
    
    public typealias ID = IDGenerator.ID
    public typealias Element = T
    public typealias Value = TaskElement<Element>
    public typealias Error = TaskValueError
    
    fileprivate var condition = DispatchCondition()
    
    fileprivate var value: Value?
    
    public var id: ID = TaskValueIDGenerator.next()
    
    public init() { }
    
    public required init(_ builder: (TaskValue<Element>) throws -> Void) {
        
    }
    
    public required init(_ closure: @autoclosure @escaping (Void) throws -> Element) {
        
    }
//    
//    public var isClosed: Bool {
//        get {
//            return self.buffer.isClosed
//        }
//        set {
//            self.condition.mutex.lock()
//            defer {
//                self.condition.broadcast()
//                self.condition.mutex.unlock()
//            }
//            self.buffer.isClosed = newValue
//        }
//    }
    
//    public convenience init(_ value: Element) {
//        self.value =
//    }
    
//    public init(values: [Element]) {
//        self.buffer = Buffer()
//        _ = try? self.buffer.append(values: values.map { Buffer.Value.value($0) })
//    }
//    
//    public convenience init(capacity: Int, value: Element...) throws {
//        try self.init(capacity: capacity, values: value)
//    }
//    
//    public init(capacity: Int, values: [Element]) throws {
//        guard capacity > 0 else { throw Error.negativeCapacity }
//        self.buffer = Buffer(capacity: .size(capacity))
//        try self.buffer.append(values: values.map { Buffer.Value.value($0) })
//    }
}

extension TaskValue {
    
    fileprivate func receiveElement() throws -> Element {
        guard let value = self.value else {
            throw Error.empty
        }
        
        switch value {
        case .value(let element):
            return element
        case .error(let error):
            throw error
        }
    }
}

// MARK: Sendable

extension TaskValue: Sendable {
    
    public func send(_ value: Element) throws {
        self.condition.mutex.lock()
        defer {
            self.condition.broadcast()
            self.condition.mutex.unlock()
        }
        
        guard self.value == nil else {
            throw Error.notEmpty
        }
        
        self.value = .value(value)
    }
    
    public func `throw`(_ error: Swift.Error) throws {
        self.condition.mutex.lock()
        defer {
            self.condition.broadcast()
            self.condition.mutex.unlock()
        }
        
        guard self.value == nil else {
            throw Error.notEmpty
        }
        
        self.value = .error(error)
    }
}

// MARK: Waitable

extension TaskValue: Waitable {
    
    @discardableResult
    public func wait() throws -> Element {
        self.condition.mutex.lock()
        defer {
            self.condition.broadcast()
            self.condition.mutex.unlock()
        }
        
        while self.value == nil {
            self.condition.wait()
        }
        
        return try self.receiveElement()
    }
    
    @discardableResult
    public func wait(timeout: DispatchTime) throws -> Element {
        self.condition.mutex.lock()
        defer {
            self.condition.broadcast()
            self.condition.mutex.unlock()
        }
        
        if self.value == nil {
            self.condition.wait(timeout: timeout)
        }
        
        return try self.receiveElement()
    }
}
