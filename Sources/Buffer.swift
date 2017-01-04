//
//  Buffer.swift
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

public enum TaskBufferValue<Element> {
    case value(Element)
    case error(Swift.Error)
}

public enum TaskBufferCapacity {
    case infinite
    case size(Int)
}

public enum TaskBufferError: Swift.Error {
    case exceededCapacity
    case closed
    case empty
}

public struct TaskBuffer<T> {
    
    public typealias Element = T
    public typealias Value = TaskBufferValue<Element>
    public typealias Index = Int
    public typealias Capacity = TaskBufferCapacity
    public typealias Error = TaskBufferError
    
    public var count: Int {
        return self.array.count
    }
    
    public var first: Value? {
        return self.array.first
    }
    
    public var last: Value? {
        return self.array.last
    }
    
    fileprivate var array = [Value]()
    
    public private (set) var capacity: Capacity
    
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
    
    public init() {
        self.init(capacity: .infinite)
    }
    
    public init(capacity: Capacity) {
        self.capacity = capacity
    }
    
    public func wait() -> Bool {
        return self.array.first == nil && !self.isClosed
    }
}

extension TaskBuffer {
    
    public mutating func append(_ value: Value) throws {
        guard !self.isClosed else {
            throw Error.closed
        }
        
        if case .size(let count) = self.capacity,
            self.array.count + 1 > count {
            throw Error.exceededCapacity
        }
        
        self.array.append(value)
    }
    
    public mutating func append(values: [Value]) throws {
        guard !self.isClosed else {
            throw Error.closed
        }
        
        if case .size(let count) = self.capacity,
            self.array.count + values.count > count {
            throw Error.exceededCapacity
        }
        
        self.array.append(contentsOf: values)
    }
    
    public mutating func remove(at index: Index) throws -> Value {
        guard !self.isClosed else { throw Error.closed }
        guard self.array.count > 0 else { throw Error.empty }
        return self.array.remove(at: index)
    }
}
