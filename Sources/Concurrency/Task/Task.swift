////
////  Task+Options.swift
////  Concurrency
////
////  Created by Sergey Minakov on 15.05.17.
////
////
//


import Foundation
@_exported import Dispatch

extension DispatchQueue {
    
    static let taskQueue = DispatchQueue(label: "concurrency.task.queue", attributes: .concurrent)
    
    static func performTask(in queue: DispatchQueue?, action: @escaping () -> Void) {
        (queue ?? .taskQueue).async {
            print("perform")
            action()
        }
    }
}

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

public protocol TaskProtocol {
    
    associatedtype Element
    
    var state: TaskState<Element> { get }
    
    func add(action: @escaping TaskClosure<Element>) -> Self
    
    func set(state: TaskState<Element>)
}

extension NSRecursiveLock {
    
    func `in`(_ action: () -> Void) {
        self.lock()
        defer { self.unlock() }
        action()
    }
}

public class Task<T>: TaskProtocol {
    
    public typealias Element = T
    
    public var state: TaskState<Element> = .ready
    public var result: TaskResult<Element>? {
        return self.state.result
    }
    
    deinit {
        print("task deinit")
    }
    
    
    let locks = (
        actions: NSRecursiveLock(),
        perform: NSRecursiveLock()
    )
    
    var actions = [TaskAction<Element>]()
    
    public func add(action: @escaping TaskClosure<Element>) -> Self {
        self.locks.actions.in {
            if let result = result {
                self.locks.actions.unlock()
                action(result)
            } else {
                self.actions.append(TaskAction(callback: action))
                self.locks.actions.unlock()
            }
        }
        
        return self
    }
    
    public init() { }
    
    public init(in queue: DispatchQueue? = nil, value: Element) {
        if let queue = queue {
            DispatchQueue.performTask(in: queue) {
                self.set(state: .success(value))
            }
        } else {
            self.set(state: .success(value))
        }
        
    }
    
    public init(in queue: DispatchQueue? = nil, error: Swift.Error) {
        if let queue = queue {
            DispatchQueue.performTask(in: queue) {
                self.set(state: .failure(error))
            }
        } else {
            self.set(state: .failure(error))
        }
    }
    
    
    public init(in queue: DispatchQueue? = nil, action: @escaping (Task<Element>) -> Void) {
        DispatchQueue.performTask(in: queue) {
            action(self)
        }
    }
    
    public init(in queue: DispatchQueue? = nil, state: TaskState<Element>) {
        if let queue = queue {
            DispatchQueue.performTask(in: queue) {
                self.set(state: state)
            }
        } else {
            self.set(state: state)
        }
    }
    
    public func set(state: TaskState<Element>) {
        self.locks.actions.in {
            guard case .ready = self.state else { return }
            self.state = state
            self.perform()
        }
    }
    
    func perform() {
        guard let result = self.result else { return }
        
        for action in self.actions {
            action.callback(result)
        }
        
        self.actions = []
    }
    
}

public extension Task {
    
    @discardableResult
    fileprivate func perform(in queue: DispatchQueue? = nil,
                             on state: State = .all,
                             delay: DispatchTime? = nil,
                             callback: @escaping (TaskResult<Element>) -> ()) -> Self {
        return self.add { result in
            self.locks.perform.lock()
            print("locks")
            DispatchQueue.performTask(in: queue) {
                if state == .all {
                    callback(result)
                } else if state == .failure && result.isError {
                    callback(result)
                } else if state == .success && !result.isError {
                    callback(result)
                }
                self.locks.perform.unlock()
                print("unlocks")
            }
        }
    }
    
    public func then<U>(in queue: DispatchQueue? = nil,
                        on state: State = .all,
                        delay: DispatchTime? = nil,
                        callback: @escaping (Element) throws -> (U)) -> Task<U> {
        print("then")
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
    
    public func send(_ element: Element) {
        self.set(state: .success(element))
    }
    
    public func `throw`(_ error: Swift.Error) {
        self.set(state: .failure(error))
    }
    
    public func `catch`(in queue: DispatchQueue? = nil, callback: @escaping (Swift.Error) -> Void) -> Self {
        return self.perform(in: queue, on: .failure) { result in
            switch result {
            case .failure(let error):
                callback(error)
            default: return
            }
        }
    }
    
    public func done(in queue: DispatchQueue? = nil,
                     callback: @escaping (Element) -> Void) -> Self {
        print("done")
        return self.perform(in: queue, on: .success) { result in
            guard let value = result.value else { return }
            callback(value)
        }
    }
    
    public func always(in queue: DispatchQueue? = nil,
                       callback: @escaping (TaskResult<Element>) -> Void) -> Self {
        print("always")
        return self.perform(in: queue, callback: callback)
    }
    
    public func timeout(after: DispatchTime) -> Self {
        return self
    }
    
    public func recover(callback: @escaping (Swift.Error) throws -> Element) -> Self {
        return self
    }
    
    public func wait() throws -> Element {
        throw TaskState<Element>.Error.timeout
    }
    
    public func wait(for time: DispatchTime? = nil) throws -> Element {
        throw TaskState<Element>.Error.timeout
    }
}

public extension Task {
    
    public func `as`<T>(_ type: T.Type) -> Task<T> {
        return Task<T>.init()
    }
}

public extension Task where Element == Void {
    
    public func finish() {
        self.set(state: .success(()))
    }
}

public extension Task where Element: Sequence {
    
    public typealias ArrayElement = Element.Iterator.Element
    
    public func map<U>(callback: (ArrayElement) -> U) -> Task<[U]> {
        return Task<[U]>()
    }
    
    public func filter(callback: (ArrayElement) -> Bool) -> Task<[ArrayElement]> {
        return Task<[ArrayElement]>()
    }
    
    public func flatMap<U>(callback: (ArrayElement) -> U?) -> Task<[U]> {
        return Task<[U]>()
    }
    
    public func reduce<Result>(_ initial: Result,
                               _ transform: @escaping (Result, ArrayElement) throws -> Result) -> Task<Result> {
        return Task<Result>.init()
    }

}

public extension Sequence where Element: TaskProtocol {
    
    typealias TaskElement = Element.Element
    func combine() -> Task<[TaskElement]> {
        return Task<[TaskElement]>()
    }
}

public func combine<T>(tasks: [Task<T>]) -> Task<[T]> {
    let newTask = Task<[T]>()
//    var (total, count, errored) = (tasks.count, 0, false)
//
//    guard tasks.count > 0 else {
//        newTask.send([])
//        return newTask
//    }
//
//    for task in tasks {
//        task.done { value in
//            DispatchQueue.barrier.sync {
//                guard !errored else { return }
//                count += 1
//                if total == count {
//                    newTask.send(tasks.flatMap { $0.state.result?.value })
//                }
//            }
//            }
//            .catch { error in
//                DispatchQueue.barrier.sync {
//                    errored = true
//                    newTask.throw(error)
//                }
//        }
//    }
//
    return newTask
}


extension Task where Element: TaskProtocol {
    
    public typealias UnderlyingTaskType = Element.Element
    
    public func unwrap(in queue: DispatchQueue? = nil) -> Task<UnderlyingTaskType> {
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
