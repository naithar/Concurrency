//
//  Task+Options.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

import Dispatch

public struct Options<Element> {
    
    typealias StartHandler = Runnable<Task<Element>>
    typealias DoneHandler = Runnable<Element>
    typealias ErrorHandler = Runnable<Swift.Error>
    typealias AlwaysHandler = Runnable<Result<Element>>
    
    var start: StartHandler?
    
    var recover: ((Swift.Error) throws -> Element)?
    
    mutating func recover(from error: Swift.Error, at task: Task<Element>) -> State<Element>? {
        defer { self.recover = nil }
        guard let action = self.recover else { return nil }
        
        do {
            let value = try action(error)
            return .finished(value)
        } catch {
            return .error(error)
        }
    }
    
    var done: DoneHandler?
    var error: ErrorHandler?
    var always: AlwaysHandler?
    
    mutating func clear() {
        self.done = nil
        self.recover = nil
        self.error = nil
        self.always = nil
    }
}

public extension Task {
    
    @discardableResult
    public func recover(_ action: @escaping (Swift.Error) throws -> Element) -> Self {
        self.condition.mutex.in {
            self.options.recover = action
        }
        self.update()
        return self
    }
}

public extension Task {
    
    @discardableResult
    public func done(on queue: DispatchQueue = .task,
                     _ action: @escaping (Element) -> Void) -> Self {
        self.condition.mutex.in {
            self.options.done = Options<Element>
                .DoneHandler(
                    queue: queue,
                    delay: nil,
                    action: action)
        }
        self.update()
        return self
    }
    
    @discardableResult
    public func done(on queue: DispatchQueue = .task,
                     delay: @autoclosure @escaping () -> DispatchTime,
                     _ action: @escaping (Element) -> Void) -> Self {
        self.condition.mutex.in {
            self.options.done = Options<Element>
                .DoneHandler(
                    queue: queue,
                    delay: delay,
                    action: action)
        }
        self.update()
        return self
    }
    
    @discardableResult
    public func always(on queue: DispatchQueue = .task,
                       _ action: @escaping (Result<Element>) -> Void) -> Self {
        self.condition.mutex.in {
            self.options.always = Options<Element>
                .AlwaysHandler(
                    queue: queue,
                    delay: nil,
                    action: action)
        }
        self.update()
        return self
    }
    
    @discardableResult
    public func always(on queue: DispatchQueue = .task,
                       delay: @autoclosure @escaping () -> DispatchTime,
                       _ action: @escaping (Result<Element>) -> Void) -> Self {
        self.condition.mutex.in {
            self.options.always = Options<Element>
                .AlwaysHandler(
                    queue: queue,
                    delay: delay,
                    action: action)
        }
        self.update()
        return self
    }
    
    @discardableResult
    public func `catch`(on queue: DispatchQueue = .task,
                        _ action: @escaping (Swift.Error) -> Void) -> Self {
        self.condition.mutex.in {
            self.options.error = Options<Element>
                .ErrorHandler(
                    queue: queue,
                    delay: nil,
                    action: action)
        }
        self.update()
        return self
    }
    
    @discardableResult
    public func `catch`(on queue: DispatchQueue = .task,
                        delay: @autoclosure @escaping () -> DispatchTime,
                        _ action: @escaping (Swift.Error) -> Void) -> Self {
        self.condition.mutex.in {
            self.options.error = Options<Element>
                .ErrorHandler(
                    queue: queue,
                    delay: delay,
                    action: action)
        }
        self.update()
        return self
    }
}
