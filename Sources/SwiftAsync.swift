#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import Dispatch

public class DispatchMutex {
    
    private lazy var mutex: pthread_mutex_t = {
        var mutex = pthread_mutex_t()
        pthread_mutex_init(&mutex, nil)
        return mutex
    }()
    
    public func lock(_ closure: (Void) -> Void) {
        self.lock()
        defer { self.unlock() }
        closure()
    }
    
    public func lock() {
        pthread_mutex_lock(&mutex)
    }
    
    public func unlock() {
        pthread_mutex_unlock(&mutex)
    }
    
    deinit {
        pthread_mutex_destroy(&self.mutex)
    }
}

public struct Atomic<T> {
    
    public typealias Element = T
    
    private var mutex = DispatchMutex()
    private var _value: Element
    
    public var value: Element {
        set {
            self.mutex.lock {
                self._value = newValue
            }
        }
        get {
            self.mutex.lock()
            defer { self.mutex.unlock() }
            return self._value
        }
    }
    
    init(_ value: Element) {
        self._value = value
    }
}

public enum TaskBufferValue<Element> {
    case value(Element)
    case error(Swift.Error)
}

public enum TaskBufferCapacity {
    case infinite
    case size(Int)
}

public enum TaskBufferError: Swift.Error {
    case unknown
}

public enum TaskError: Swift.Error {
    case unknown
}

public struct TaskBuffer<T> {
    
    public typealias Element = T
    
    public typealias Value = TaskBufferValue<Element>
    public typealias Index = Int
    
    public typealias Capacity = TaskBufferCapacity
    
    public typealias Error = TaskBufferError
    
    private var mutex = DispatchMutex()
    
    private var array = [Value]()
    public private (set) var capacity: Capacity
    
    public var isClosed = false
    
    public init() {
        self.init(capacity: .infinite)
    }
    
    public var count: Int {
        return self.array.count
    }
    
    public var first: Value? {
        return self.array.first
    }
    
    public var last: Value? {
        return self.array.last
    }
    
    public init(capacity: Capacity) {
        self.capacity = capacity
    }
    
    public mutating func append(_ value: Value) throws {
        self.mutex.lock()
        defer { self.mutex.unlock() }
        
        if case .size(let count) = self.capacity,
            count > self.array.count {
            throw Error.unknown
        }
        
        self.array.append(value)
    }
    
    public mutating func append(values: [Value]) throws {
        self.mutex.lock()
        defer { self.mutex.unlock() }
        
        //check capacity
        self.array.append(contentsOf: values)
    }
    
    public mutating func remote(at index: Index) throws -> Value {
        self.mutex.lock()
        defer { self.mutex.unlock() }
        guard self.array.count > 0 else { throw Error.unknown }
        return self.array.remove(at: index)
    }
}

public class Task<T> {
    
    public typealias Element = T
    
    public typealias Buffer = TaskBuffer<Element>
    
    private var semaphore = DispatchSemaphore(value: 0)
    private var buffer = Buffer()
    
    public typealias Error = TaskError
    
    public var isClosed = false
    
    public convenience init(value: Element...) {
        self.init(values: value)
    }
    
    public init(values: [Element]) {
        self.semaphore = DispatchSemaphore(value: values.count)
        _ = try? self.buffer.append(values: values.map { Buffer.Value.value($0) })
    }
    
    public convenience init(capacity: Int, value: Element...) throws {
        try self.init(capacity: capacity, values: value)
    }
    
    public init(capacity: Int, values: [Element]) throws {
        guard capacity > 0 else { throw Error.unknown }
        self.semaphore = DispatchSemaphore(value: values.count)
        self.buffer = Buffer(capacity: .size(capacity))
        try self.buffer.append(values: values.map { Buffer.Value.value($0) })
    }
    
    public func send(value: Element) throws {
        try self.buffer.append(.value(value))
    }
    
    public func `throw`(error: Swift.Error) throws {
        try self.buffer.append(.error(error))
    }
    
    @discardableResult
    public func receive(wait: DispatchTime? = nil) throws -> Element? {
        return nil
    }
}

@discardableResult
func async<Element>(on queue: DispatchQueue? = nil, _ closure: @autoclosure (Void) throws -> Element) -> Task<Element> {
    return Task<Element>()
}

@discardableResult
func await<Element>(_ closure: @autoclosure (Void) -> Task<Element>) throws -> Element? {
    return nil
}
