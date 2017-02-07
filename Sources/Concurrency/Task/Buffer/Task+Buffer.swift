//
//  Task+Buffer.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 03.01.17.
//
//

import Dispatch

let TaskBufferIDGenerator = IDGenerator(key: "task-buffer")

extension Task {
    
    public final class Buffer<T>: Taskable {
        
        public enum Error: Swift.Error {
            case closed
            case empty
        }
        
        public typealias ID = IDGenerator.ID
        public typealias Element = T
        public typealias Value = Task.Element<Element>
        
        fileprivate var condition = DispatchCondition()
        
        public fileprivate (set) var error: Swift.Error?
        
        fileprivate var array = [Value]()
        
        public var id: ID = TaskBufferIDGenerator.next()
        
        public var count: Int {
            return self.array.count
        }
        
        public var first: Value? {
            return self.array.first
        }
        
        public var last: Value? {
            return self.array.last
        }
        
        //TODO: global error
        
        private var _closed = false
        public var isClosed: Bool {
            set {
                self.condition.mutex.lock()
                defer { self.condition.mutex.unlock() }
                guard !self._closed else { return }
                self._closed = newValue
            }
            get {
                return self._closed
            }
        }
        
        public private (set) lazy var sending: Task.Sending<Task.Buffer<T>> = Task.Sending(container: self)
        public private (set) lazy var waiting: Task.Waiting<Task.Buffer<T>> = Task.Waiting(container: self)
        
        public init() { }
        
        //TODO: queue usage
        
        public required convenience init(on queue: DispatchQueue? = nil, delay: DispatchTime? = nil, _ builder: @escaping (Task.Sending<Task.Buffer<T>>) throws -> Void) {
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
    }
}

// MARK: Fileprivate extensions

extension Task.Buffer {
    
    fileprivate func shouldWait() -> Bool {
        return self.first == nil && !self.isClosed && self.error == nil
    }
    
    fileprivate func receiveElement() throws -> Element {
        guard self.error == nil else {
            throw self.error!
        }
        
        guard self.array.count > 0 else {
            throw Error.empty
        }
        
        let value = self.array.remove(at: 0)
        
        switch value {
        case .value(let element):
            return element
        case .error(let error):
            throw error
        }
    }
}

// MARK: Public extensions

extension Task.Buffer {
    
    public func loop(on queue: DispatchQueue? = nil, action: @escaping (Int, Element?, Swift.Error?, inout Bool) -> ()) {
        var finished = false
        var index = 0
        while !finished {
            var actionElement: Element?
            var actionError: Swift.Error?
            
            do {
                actionElement = try self.wait()
            } catch {
                actionError = error
            }
            
            action(index, actionElement, actionError, &finished)
            
            index += 1
        }
    }
    
    public func loop(on queue: DispatchQueue? = nil, timeout: @autoclosure @escaping () -> DispatchTime, action: @escaping (Int, Element?, Swift.Error?, inout Bool) -> ()) {
        var finished = false
        var index = 0
        while !finished {
            var actionElement: Element?
            var actionError: Swift.Error?
            
            do {
                let timeoutValue = timeout()
                actionElement = try self.wait(timeout: timeoutValue)
            } catch {
                actionError = error
            }
            
            action(index, actionElement, actionError, &finished)
            
            index += 1
        }
    }
}

// MARK: Sendable


extension Task.Buffer: Sendable {
    
    public func send(_ value: T) throws {
        self.condition.mutex.lock()
        defer {
            self.condition.broadcast()
            self.condition.mutex.unlock()
        }
        
        guard self.error == nil else {
            throw self.error!
        }
        
        guard !self.isClosed else {
            let error = Error.closed
            self.error = error
            throw error
        }
        
        self.array.append(.value(value))
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
        
        guard !self.isClosed else {
            let error = Error.closed
            self.error = error
            throw error
        }
        
        self.array.append(.error(error))
    }
    
}

// MARK: Waitable

extension Task.Buffer: Waitable {
    
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

extension Task.Buffer: Hashable {
    
    public var hashValue: Int {
        return self.id.hashValue
    }
    
    public static func ==<T>(lhs: Task.Buffer<T>, rhs: Task.Buffer<T>) -> Bool {
        return lhs.id == rhs.id
    }
    
    public static func !=<T>(lhs: Task.Buffer<T>, rhs: Task.Buffer<T>) -> Bool {
        return !(lhs == rhs)
    }
}
