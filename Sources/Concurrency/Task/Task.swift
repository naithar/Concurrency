//
//  Task.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 05.01.17.
//
//

@_exported import Dispatch

public protocol TaskProtocol: Sendable, Waitable {
    
    associatedtype Element
    
    init(_ builder: (Task.Sending<Self>) throws -> Void) rethrows
}

public enum Task {
    
    public class Sending<T: Sendable>: Sendable {
        
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
    
    public class Waiting<T: Waitable>: Waitable {
        
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
    
    public enum Element<Element> {
        case value(Element)
        case error(Swift.Error)
    }
}
