//
//  Task.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 05.01.17.
//
//

import Dispatch

public protocol TaskProtocol: Sendable, Waitable {
    
    associatedtype Element
}

public enum E: Swift.Error {
    case unknown
}

public struct SendableTask<T: Sendable>: Sendable {
    
    public typealias Task = T
    public typealias Element = T.Element
    
    public func send(_ value: Element) throws {
        
    }
    
    public func `throw`(_ error: Swift.Error) throws {
        
    }

}

public struct WaitableTask<T: Waitable>: Waitable {
    
    public typealias Task = T
    public typealias Element = T.Element
    
    @discardableResult
    public func wait() throws -> Element {
        throw E.unknown
    }
    
    @discardableResult
    public func wait(timeout: DispatchTime) throws -> Element {
        throw E.unknown
    }
}

public struct Task<T> {
    
    public typealias Waitable = WaitableTask<Channel<T>>
    public typealias Sendable = WaitableTask<Channel<T>>
}
