//
//  TaskValue.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 03.01.17.
//
//

import Dispatch



let TaskValueIDGenerator = IDGenerator(key: "task-value")


extension Task {
    
    public final class Value<T>: TaskProtocol {
        
        public enum Error: Swift.Error {
            case notEmpty
            case empty
        }
        
        public typealias ID = IDGenerator.ID
        public typealias Element = T
        public typealias Value = Task.Element<Element>
        
        public fileprivate(set) var isFinished = false
        
        fileprivate var condition = DispatchCondition()
        
        fileprivate var value: Value?
        
        public var id: ID = TaskValueIDGenerator.next()
        
        public var isEmpty: Bool {
            get {
                return self.value == nil
            }
        }
        
        public init() { }
        
        public required init(_ builder: (Task.Sending<Task.Value<T>>) throws -> Void) {
        }
        
        public required init(_ closure: @autoclosure @escaping (Void) throws -> Element) {
            
        }
        
        
    }
}

extension Task.Value {
    
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

extension Task.Value: Sendable {
    
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
        self.isFinished = true
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
        self.isFinished = true
    }
}

// MARK: Waitable

extension Task.Value: Waitable {
    
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

// MARK: Hashable

extension Task.Value: Hashable {
    
    public var hashValue: Int {
        return self.id.hashValue
    }
    
    public static func ==<T>(lhs: Task.Value<T>, rhs: Task.Value<T>) -> Bool {
        return lhs.id == rhs.id
    }
    
    public static func !=<T>(lhs: Task.Value<T>, rhs: Task.Value<T>) -> Bool {
        return !(lhs == rhs)
    }
}
