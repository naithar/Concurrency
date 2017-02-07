//
//  Mutex.swift
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

public class DispatchMutex {
    
    internal var mutex: pthread_mutex_t
    
    public init() {
        self.mutex = pthread_mutex_t()
        pthread_mutex_init(&mutex, nil)
    }
    
    @discardableResult
    public func `in`<T>(_ closure: (Void) -> T) -> T {
        self.lock()
        defer { self.unlock() }
        return closure()
    }
    
    @discardableResult
    public func lock() -> Bool {
        return pthread_mutex_lock(&self.mutex) == 0
    }
    
    @discardableResult
    public func unlock() -> Bool {
        return pthread_mutex_unlock(&self.mutex) == 0
    }
    
    deinit {
        pthread_mutex_destroy(&self.mutex)
    }
}
