//
//  Condition.swift
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

public class DispatchCondition {
    
    public let mutex: DispatchMutex
    
    fileprivate var condition: pthread_cond_t
    
    public convenience init(){
        self.init(mutex: DispatchMutex())
    }
    
    public init(mutex: DispatchMutex){
        self.mutex = mutex
        self.condition = pthread_cond_t()
        pthread_cond_init(&self.condition, nil)
    }
    
    @discardableResult
    public func broadcast() -> Bool {
        return pthread_cond_broadcast(&self.condition) == 0
    }
    
    @discardableResult
    public func wait() -> Bool {
        return pthread_cond_wait(&self.condition, &self.mutex.mutex) == 0
    }
    
    @discardableResult
    public func wait(timeout: DispatchTime) -> Bool {
        return self.wait(ms: timeout.ms)
    }
    
    private func wait(ms: Int) -> Bool {
        var tv = timeval()
        var ts = timespec()
        gettimeofday(&tv, nil)
        ts.tv_sec = time(nil) + ms / 1000
        let tmp = 1000 * 1000 * (ms % 1000)
        ts.tv_nsec = Int(Int32(tv.tv_usec * 1000) + Int32(tmp))
        ts.tv_sec += ts.tv_nsec / 1000000000
        ts.tv_nsec %= 1000000000
        
        return pthread_cond_timedwait(&self.condition, &self.mutex.mutex, &ts) == 0
    }
    
    @discardableResult
    public func signal() -> Bool {
        return pthread_cond_signal(&self.condition) == 0
    }
    
    deinit {
        pthread_cond_destroy(&self.condition)
    }
}
