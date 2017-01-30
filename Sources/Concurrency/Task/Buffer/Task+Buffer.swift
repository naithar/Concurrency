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
        
        public required convenience init(on: DispatchQueue? = nil, _ builder: (Task.Sending<Task.Buffer<T>>) throws -> Void) rethrows {
            self.init()
            
            do {
                try builder(self.sending)
            } catch {
                try self.throw(error)
            }
        }
    }
}

// MARK: Fileprivate extensions

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
}

// MARK: Public extensions

extension Task.Buffer {

    // TODO: loop breaking
    public func loop(on: DispatchQueue? = nil, action: @escaping (Element?, Swift.Error?) -> ()) {
        // TODO: loop in queue
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
