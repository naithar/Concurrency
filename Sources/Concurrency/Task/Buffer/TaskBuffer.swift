//
//  Buffer.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 03.01.17.
//
//

import Dispatch

let TaskBufferIDGenerator = IDGenerator(key: "task-buffer")

public enum TaskBufferError: Swift.Error {
    case closed
    case empty
}

extension Task {
    public final class Buffer<T>: TaskProtocol {
        
        public typealias ID = IDGenerator.ID
        public typealias Element = T
        public typealias Value = Task.Element<Element>
        public typealias Error = TaskBufferError
        
        fileprivate var condition = DispatchCondition()
        
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
        
        private var _closed = false
        public var isClosed: Bool {
            set {
                guard !self._closed else { return }
                self._closed = newValue
            }
            get {
                return self._closed
            }
        }
        
        public init() { }
        
        public required init(_ builder: (Task.Sendable<Buffer>) throws -> Void) {
            
        }
        
        public required init(_ closure: @autoclosure @escaping (Void) throws -> Element) {
            
        }
    }
}

extension Task.Buffer {
    
    fileprivate func shouldWait() -> Bool {
        return self.first == nil && !self.isClosed
    }
    
    fileprivate func receiveElement() throws -> Element {
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
    
    
    //    public mutating func append(_ value: Value) throws {
    //        guard !self.isClosed else {
    //            throw Error.closed
    //        }
    //
    //        if case .size(let count) = self.capacity,
    //            self.array.count + 1 > count {
    //            throw Error.exceededCapacity
    //        }
    //
    //        self.array.append(value)
    //    }
    //
    //    public mutating func append(values: [Value]) throws {
    //        guard !self.isClosed else {
    //            throw Error.closed
    //        }
    //
    //        if case .size(let count) = self.capacity,
    //            self.array.count + values.count > count {
    //            throw Error.exceededCapacity
    //        }
    //
    //        self.array.append(contentsOf: values)
    //    }
    //
    //    public mutating func remove(at index: Index) throws -> Value {
    //        guard !self.isClosed else { throw Error.closed }
    //        guard self.array.count > 0 else { throw Error.empty }
    //        return self.array.remove(at: index)
    //    }
}

// MARK: Sendable


extension Task.Buffer: SendableProtocol {
    
    public func send(_ value: T) throws {
        self.condition.mutex.lock()
        defer {
            self.condition.broadcast()
            self.condition.mutex.unlock()
        }
        
        self.array.append(.value(value))
    }

    public func `throw`(_ error: Swift.Error) throws {
        self.condition.mutex.lock()
        defer {
            self.condition.broadcast()
            self.condition.mutex.unlock()
        }
        
        self.array.append(.error(error))
    }
    
}

// MARK: Waitable

extension Task.Buffer: WaitableProtocol {
    
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


extension Task.Buffer: Hashable {
    
    public var hashValue: Int {
        return self.id.hashValue
    }
    
    public static func ==(lhs: Task.Buffer, rhs: Task.Buffer) -> Bool {
        return lhs.id == rhs.id
    }
    
    public static func !=(lhs: Task.Buffer, rhs: Task.Buffer) -> Bool {
        return !(lhs == rhs)
    }
}
