//
//  Task+Wait.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

import Dispatch

extension Task {
    
    private func shouldWait() -> Bool {
        if case .ready = self.state {
            return true
        }
        
        return false
    }
    
    private func receiveElement() throws -> Element {
        switch self.state {
        case .finished(let element):
            return element
        case .error(let error):
            throw error
        case .ready:
            throw TaskError.timeout
        }
    }
    
    
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
    public func wait(for timeout: @autoclosure () -> DispatchTime) throws -> Element {
        self.condition.mutex.lock()
        defer {
            self.condition.broadcast()
            self.condition.mutex.unlock()
        }
        
        if self.shouldWait() {
            self.condition.wait(timeout: timeout())
        }
        
        return try self.receiveElement()
    }
}
