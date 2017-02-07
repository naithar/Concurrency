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
            self.mutex.in {
                self._value = newValue
            }
        }
        get {
            return self.mutex.in {
                return self._value
            }
        }
    }
    
    init(_ value: Element) {
        self._value = value
    }
}
