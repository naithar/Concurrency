//
//  Task+Options.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

import Dispatch

public struct Options<Element> {
    
    private var task: Task<Element>?
    
    init(task: Task<Element>) {
        self.task = task
    }
    
    typealias StartHandler = Runnable<Task<Element>>
    typealias DoneHandler = Runnable<Element>
    typealias ErrorHandler = Runnable<Swift.Error>
    typealias AlwaysHandler = Runnable<Result<Element>>
    
    var start: StartHandler?
    
    var recover: ((Swift.Error) throws -> Element)?
    
    mutating func recover(from error: Swift.Error) -> Bool {
        guard let task = self.task else { return false }
        defer { self.recover = nil }
        guard let action = self.recover else { return false }
        
        do {
            let value = try action(error)
            task.send(value)
        } catch {
            task.throw(error)
        }
        
        return true
    }
    
    var done: DoneHandler?
    var error: ErrorHandler?
    var always: AlwaysHandler?
    
    mutating func clear() {
        self.task = nil
        self.done = nil
        self.recover = nil
        self.error = nil
        self.always = nil
    }
}

extension Task {
    
    @discardableResult
    public func recover(_ action: @escaping (Swift.Error) throws -> Element) -> Self {
        self.options.recover = action
        return self
    }
}

extension Task {
    
    @discardableResult
    public func done(on queue: DispatchQueue = .main,
                     _ action: @escaping (Element) -> Void) -> Self {
        self.options.done = Options<Element>
            .DoneHandler(
                queue: queue,
                delay: nil,
                action: action)
        return self
    }
    
    @discardableResult
    public func done(on queue: DispatchQueue = .main,
                     delay: @autoclosure @escaping () -> DispatchTime,
                     _ action: @escaping (Element) -> Void) -> Self {
        self.options.done = Options<Element>
            .DoneHandler(
                queue: queue,
                delay: delay,
                action: action)
        return self
    }
    
    @discardableResult
    public func always(on queue: DispatchQueue = .main,
                       _ action: @escaping (Result<Element>) -> Void) -> Self {
        self.options.always = Options<Element>
            .AlwaysHandler(
                queue: queue,
                delay: nil,
                action: action)
        return self
    }
    
    @discardableResult
    public func always(on queue: DispatchQueue = .main,
                       delay: @autoclosure @escaping () -> DispatchTime,
                       _ action: @escaping (Result<Element>) -> Void) -> Self {
        self.options.always = Options<Element>
            .AlwaysHandler(
                queue: queue,
                delay: delay,
                action: action)
        return self
    }
    
    @discardableResult
    public func `catch`(on queue: DispatchQueue = .main,
                        _ action: @escaping (Swift.Error) -> Void) -> Self {
        self.options.error = Options<Element>
            .ErrorHandler(
                queue: queue,
                delay: nil,
                action: action)
        return self
    }
    
    @discardableResult
    public func `catch`(on queue: DispatchQueue = .main,
                        delay: @autoclosure @escaping () -> DispatchTime,
                        _ action: @escaping (Swift.Error) -> Void) -> Self {
        self.options.error = Options<Element>
            .ErrorHandler(
                queue: queue,
                delay: delay,
                action: action)
        return self
    }
}
