//
//  IDGenerator.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 03.01.17.
//
//

public class IDGenerator {
    
    public typealias ID = String
    
    private var key: String
    private var index = 0
    private var mutex = DispatchMutex()
    
    internal init(key: String) {
        self.key = key
    }
    
    public func next() -> ID {
        self.mutex.lock()
        defer { self.mutex.unlock() }
        let id = "\(self.key)-\(self.index)"
        self.index += 1
        return id
    }
}
