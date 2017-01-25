//
//  Once.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 06.01.17.
//
//

public class DispatchOnce {
    
    private var mutex = DispatchMutex()
    
    public private (set) var isFinished = false
    
    public func reset() {
        self.mutex.lock()
        defer { self.mutex.unlock() }
        self.isFinished = false
    }
    
    public func perform(_ action: @autoclosure (Void) -> Void) {
        self.mutex.lock()
        defer { self.mutex.unlock() }
        
        guard !self.isFinished else { return }
        
        action()
        self.isFinished = true
    }
}
