//
//  Task+Value.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 03.01.17.
//
//

import Dispatch

let TaskValueIDGenerator = IDGenerator(key: "task-value")


extension Task {
    
    public final class Value<T>: Taskable {
        
        public enum Error: Swift.Error {
            case notEmpty
            case empty
        }
        
        public typealias ID = IDGenerator.ID
        public typealias Element = T
        public typealias Value = Task.Element<Element>
        
        public fileprivate (set) var isFinished = false
        
        public fileprivate (set) var error: Swift.Error?
        
        fileprivate var condition = DispatchCondition()
        
        fileprivate var value: Value?
        
        public var id: ID = TaskValueIDGenerator.next()
        
        public var isEmpty: Bool {
            get {
                return self.value == nil
            }
        }
        
        public private (set) lazy var sending: Task.Sending<Task.Value<T>> = Task.Sending(container: self)
        public private (set) lazy var waiting: Task.Waiting<Task.Value<T>> = Task.Waiting(container: self)
        
        public init() { }
        
        //TODO: queue usage
        
        public convenience init(on queue: DispatchQueue? = nil, delay: DispatchTime? = nil, _ builder: @escaping (Task.Sending<Task.Value<T>>) throws -> Void) {
            let taskQueue = queue ?? Task.defaultQueue
            
            self.init()
            
            func action() {
                do {
                    try builder(self.sending)
                } catch {
                    try? self.throw(error)
                }
            }
            
            if let delay = delay {
                taskQueue.asyncAfter(deadline: delay, execute: action)
            } else {
                taskQueue.async(execute: action)
            }
        }
        
        public required convenience init(on queue: DispatchQueue? = nil, delay: DispatchTime? = nil, _ closure: @autoclosure @escaping (Void) throws -> Element) {
            let taskQueue = queue ?? Task.defaultQueue
            
            self.init()
            
            func action() {
                do {
                    let value = try closure()
                    try self.send(value)
                } catch {
                    try? self.throw(error)
                }
            }

            if let delay = delay {
                taskQueue.asyncAfter(deadline: delay, execute: action)
            } else {
                taskQueue.async(execute: action)
            }
        }
        
        
    }
}

extension Task.Value {
    
    fileprivate func shouldWait() -> Bool {
        return self.value == nil && self.error == nil
    }
    
    fileprivate func receiveElement() throws -> Element {
        guard self.error == nil else {
            throw self.error!
        }
        
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
        
        guard self.error == nil else {
            throw self.error!
        }
        
        guard self.value == nil else {
            let error = Error.notEmpty
            self.error = error
            throw error
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
        
        guard self.error == nil else {
            throw self.error!
        }
        
        guard self.value == nil else {
            let error = Error.notEmpty
            self.error = error
            throw error
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
        
        while self.shouldWait() {
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
        
        if self.shouldWait() {
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
