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
    
    init(_ builder: (Task<Element>.Sendable<Self>) throws -> Void)
    init(_ closure: @autoclosure @escaping (Void) throws -> Element)
}

public class SendableTask<T: Sendable>: Sendable {
    
    public typealias Container = T
    public typealias Element = T.Element
    
    private var container: Container
    
    init(container: Container) {
        self.container = container
    }
    
    public func send(_ value: Element) throws {
        try self.container.send(value)
    }
    
    public func `throw`(_ error: Swift.Error) throws {
        try self.container.throw(error)
    }

}

public class WaitableTask<T: Waitable>: Waitable {
    
    public typealias Container = T
    public typealias Element = T.Element
    
    private var container: Container
    
    init(container: Container) {
        self.container = container
    }
    
    @discardableResult
    public func wait() throws -> Element {
        return try self.container.wait()
    }

    @discardableResult
    public func wait(timeout: DispatchTime) throws -> Element {
        return try self.container.wait(timeout: timeout)
    }
}

public enum TaskElement<Element> {
    case value(Element)
    case error(Swift.Error)
}

public struct Task<T> {
    
    public typealias Sendable<C: TaskProtocol> = SendableTask<C> where C.Element == T
    public typealias Waitable<C: TaskProtocol> = WaitableTask<C> where C.Element == T
    
    public typealias Value = TaskValue<T>
    public typealias Buffer = TaskBuffer<T>
}
