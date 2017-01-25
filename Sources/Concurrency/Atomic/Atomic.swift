//
//  Atomic.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 03.01.17.
//
//

public struct Atomic<T> {
    
    public typealias Element = T
    
    private var mutex = DispatchMutex()
    private var _value: Element
    
    public var value: Element {
        set {
            self.mutex.lock()
            defer { self.mutex.unlock() }
            self._value = newValue
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
