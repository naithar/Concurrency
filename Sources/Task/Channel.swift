//
//  Channel.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 03.01.17.
//
//

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import Dispatch

public enum TaskError: Swift.Error {
    case negativeCapacity
}

let TaskIDGenerator = IDGenerator(key: "task")

public class Channel<T> {
    
    public typealias ID = IDGenerator.ID
    public typealias Element = T
    public typealias Buffer = TaskBuffer<Element>
    public typealias Error = TaskError
    
    fileprivate var condition = DispatchCondition()
    fileprivate var buffer: Buffer
//    fileprivate var selectConditions = [DispatchCondition]()
    
    public var id: ID = TaskIDGenerator.next()
    
    public var isClosed: Bool {
        get {
            return self.buffer.isClosed
        }
        set {
            self.condition.mutex.lock()
            defer {
                self.condition.broadcast()
                self.condition.mutex.unlock()
            }
            self.buffer.isClosed = newValue
        }
    }
    
    public convenience init(value: Element...) {
        self.init(values: value)
    }
    
    public init(values: [Element]) {
        self.buffer = Buffer()
        _ = try? self.buffer.append(values: values.map { Buffer.Value.value($0) })
    }
    
    public convenience init(capacity: Int, value: Element...) throws {
        try self.init(capacity: capacity, values: value)
    }
    
    public init(capacity: Int, values: [Element]) throws {
        guard capacity > 0 else { throw Error.negativeCapacity }
        self.buffer = Buffer(capacity: .size(capacity))
        try self.buffer.append(values: values.map { Buffer.Value.value($0) })
    }
}

extension Channel {
    
    fileprivate func receiveElement() throws -> Element {
        let value = try self.buffer.remove(at: 0)
        
        switch value {
        case .value(let element):
            return element
        case .error(let error):
            throw error
        }
    }
}

// MARK: Sending

extension Channel: Sending {
    
    public func send(_ value: Element) throws {
        self.condition.mutex.lock()
        defer {
            self.condition.broadcast()
            self.condition.mutex.unlock()
        }
        try self.buffer.append(.value(value))
    }
    
    public func `throw`(_ error: Swift.Error) throws {
        self.condition.mutex.lock()
        defer {
            self.condition.broadcast()
            self.condition.mutex.unlock()
        }
        try self.buffer.append(.error(error))
    }
}

// MARK: Receiving

extension Channel: Receiving {
    
    @discardableResult
    public func receive() throws -> Element {
        self.condition.mutex.lock()
        defer {
            self.condition.broadcast()
            self.condition.mutex.unlock()
        }
        
        while self.buffer.wait() {
            self.condition.wait()
        }
        
        return try self.receiveElement()
    }
    
    @discardableResult
    public func receive(timeout: DispatchTime) throws -> Element {
        self.condition.mutex.lock()
        defer {
            self.condition.broadcast()
            self.condition.mutex.unlock()
        }
        
        if self.buffer.wait() {
            self.condition.wait(timeout: timeout)
        }
        
        return try self.receiveElement()
    }
}

// MARK: Select

//extension Task {
//    
////    internal func append(condition: DispatchCondition, for select: SelectBuilder.ID) -> Int {
////        self.selectConditions.append(condition)
////        return self.selectConditions.count - 1
////    }
////    
////    internal func remove(conditionAt index: Int) {
////        
////    }
//    
//    internal func select() -> Buffer.Value? {
//        self.condition.mutex.lock()
//        defer {
//            self.condition.mutex.unlock()
//        }
//        
//        guard let first = try? self.buffer.remove(at: 0) else {
//            return nil
//        }
//        
//        return first
//    }
//}
