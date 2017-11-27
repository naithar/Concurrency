////
////  Task+Options.swift
////  Concurrency
////
////  Created by Sergey Minakov on 15.05.17.
////
////
//


import Foundation
import Dispatch

public struct State: OptionSet {
    
    public private(set) var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    static let success = State(rawValue: 1 << 1)
    static let failure = State(rawValue: 1 << 2)
    
    static let all: State = [.success, .failure]
}

public enum TaskState<Element> {
    
    enum Error: Swift.Error {
        case timeout
    }
    
    case ready
    case success(Element)
    case failure(Swift.Error)
    case timeout
    
    var result: TaskResult<Element>? {
        switch self {
        case .ready:
            return nil
        case .success(let el):
            return .success(el)
        case .failure(let er):
            return .failure(er)
        case .timeout:
            return .failure(Error.timeout)
        }
    }
}


public enum TaskResult<Element> {
    
    case success(Element)
    case failure(Swift.Error)
    
    var value: Element? {
        switch self {
        case .success(let el): return el
        default: return nil
        }
    }
    
    var isError: Bool {
        switch self {
        case .success: return false
        case .failure: return true
        }
    }
}

public typealias TaskClosure<Element> = (TaskResult<Element>) -> Void
public struct TaskAction<Element> {
    
    let callback: TaskClosure<Element>
}

public let yield = ()

public protocol TaskProtcol {
    
    associatedtype Element
    
    var state: TaskState<Element> { get }
    var result: TaskResult<Element>? { get }
    
    //    func then() -> Self
    //    func `catch`() -> Self
    //
    //    func `do`() -> Self
    //    func always() -> Self
    //
    //    func timeout() -> Self
    
    func add(action: @escaping TaskClosure<Element>) -> Self
    
    func set(state: TaskState<Element>)
}

public class Task<T>: TaskProtcol {
    
    
    public typealias Element = T
    
    public var state: TaskState<Element> = .ready
    public var result: TaskResult<Element>? {
        return self.state.result
    }
    
    let lock = NSRecursiveLock()
    
    var actions = [TaskAction<Element>]()
    
    public func add(action: @escaping TaskClosure<Element>) -> Self {
//        print("adding")
        self.lock.lock()
        if let result = result {
//            print("doing")
            self.lock.unlock()
            action(result)
        } else {
            self.lock.unlock()
//            print("adding---")
            self.actions.append(TaskAction(callback: action))
        }
        
        return self
    }
    
    init() {
        
    }
    
    public init(in queue: DispatchQueue? = nil, value: Element) {
        
    }
    
    public init(in queue: DispatchQueue? = nil) {
        
    }
    public init(in queue: DispatchQueue? = nil, action: @escaping (Task<Element>) -> Void) {
        (queue ?? taskQueue).async {
            action(self)
        }
    }
    
    public init(state: TaskState<Element>) {
        self.state = state
    }
    
    public func set(state: TaskState<Element>) {
//        print("about to set")
        
        self.lock.lock()
        guard case .ready = self.state else { return }
        
//        print("doing to set")
        
        self.state = state
        self.lock.unlock()
        
        self.perform()
    }
    
    func perform() {
//        print("about to perform")
        guard let result = self.result else { return }
        
//        print("performing")
        for action in self.actions {
            action.callback(result)
        }
        
        self.actions = []
    }
}

let taskQueue = DispatchQueue.init(label: "label", attributes: .concurrent)

public extension Task {
    
    @discardableResult
    func perform(in queue: DispatchQueue? = nil, on state: State = .all, callback: @escaping (TaskResult<Element>) -> ()) -> Self {
        return self.add { result in
            (queue ?? taskQueue).async {
                if state == .all {
                    callback(result)
                } else if state == .failure && result.isError {
                    callback(result)
                } else if state == .success && !result.isError {
                    callback(result)
                }
            }
        }
    }
    
    func then<U>(in queue: DispatchQueue? = nil,
                 on state: State = .all,
                 callback: @escaping (Element) throws -> (U)) -> Task<U> {
        let task = Task<U>.init()

        self.perform(in: queue, on: state) { result in
            switch result {
            case .success(let element):
                do {
                    let result = try callback(element)
                    task.send(result)
                } catch {
                    task.throw(error)
                }
            case .failure(let error):
                task.throw(error)
            }
        }
        
        return task
    }
    
    func send(_ element: Element) {
        self.set(state: .success(element))
    }
    
    func `throw`(_ error: Swift.Error) {
        self.set(state: .failure(error))
    }
    
    func `catch`(in queue: DispatchQueue? = nil, callback: @escaping (Swift.Error) -> Void) -> Self {
        return self.perform(in: queue, on: .failure) { result in
            switch result {
            case .failure(let error):
                callback(error)
            default: return
            }
        }
    }
    
    func done(in queue: DispatchQueue? = nil,
              callback: @escaping (Element) -> Void) -> Self {
        return self.perform(in: queue, on: .success) { result in
            guard let value = result.value else { return }
            callback(value)
        }
    }
    
    func always(in queue: DispatchQueue? = nil,
                callback: @escaping (TaskResult<Element>) -> Void) -> Self {
        return self.perform(in: queue, callback: callback)
    }
    
//    func timeout() -> Self {
//
//    }
    
}

public extension Task where T: TaskProtcol {
    
    typealias UnderlyingTaskType = T.Element
    
    func unwrap(in queue: DispatchQueue? = nil) -> Task<UnderlyingTaskType> {
        let unwrappedTask = Task<UnderlyingTaskType>.init()
        
        self.perform(in: queue) { result in
            switch result {
            case .success(let task):
                unwrappedTask.set(state: task.state)
            case .failure(let error):
                unwrappedTask.throw(error)
            }
        }
        
        return unwrappedTask
    }
}



