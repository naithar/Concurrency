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

    
    public func lock(_ closure: (Void) -> Void) {
        self.lock()
        defer { self.unlock() }
        closure()
    }
    
    public func lock() {
        pthread_mutex_lock(&self.mutex)
    }
    
    public func unlock() {
        pthread_mutex_unlock(&self.mutex)
    }
    
    deinit {
        pthread_mutex_destroy(&self.mutex)
    }
}
