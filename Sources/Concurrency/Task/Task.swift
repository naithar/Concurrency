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
        if self.index >= Int.max {
            self.index = 0
            self.key += "_"
        } else {
            self.index += 1
        }
        return "\(self.key)\(self.index)"
    }
}

let taskGenId = IDGenerator(key: "task-")

extension DispatchQueue {
    
    static let taskQueue = DispatchQueue(label: "concurrency.task.queue", attributes: .concurrent)
    
    static let barrier = DispatchQueue(label: "concurrency.task.queue.barrier", attributes: [.concurrent])
    
    static func performTask(in queue: DispatchQueue?,
                            delay: (() -> DispatchTime)? = nil,
                            action: @escaping () -> Void) {
        if let delay = delay {
            let value = delay()
            //            let time = DispatchTime.now()
            
            //
            //            //print(value)
            //            //print(time)
            (queue ?? .taskQueue).asyncAfter(deadline: value) {
                action()
            }
        } else {
            (queue ?? .taskQueue).async {
                action()
            }
        }
    }
}

public struct State: OptionSet {
    
    public private(set) var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let success = State(rawValue: 1 << 1)
    public static let failure = State(rawValue: 1 << 2)
    
    public static let all: State = [.success, .failure]
}

public enum TaskState<Element> {
    
    enum Error: Swift.Error {
        case timeout
        case didNotStart
        case convertationError
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

public class Task<T>: TaskProtocol {
    
    public typealias Element = T
    
    let id = taskGenId.next()
    
    public var state: TaskState<Element> = .ready
    public var result: TaskResult<Element>? {
        return self.state.result
    }
    
    deinit {
        ////print("task deinit")
    }
    
    var conditions = (
        set: DispatchCondition(),
        perform: DispatchCondition()
    )
    
    var actions = [TaskAction<Element>]()
    
    public func add(action: @escaping TaskClosure<Element>) -> Self {
        return self.conditions.set.in {
            if let result = result {
                action(result)
            } else {
                self.actions.append(TaskAction(callback: action))
            }
            
            return self
        }
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
        self.set(state: state, force: false)
    }
    
    public func set(state: TaskState<Element>, force: Bool) {
        self.conditions.set.in {
            if force {
                self.state = state
                self.perform()
            } else if case .ready = self.state {
                self.state = state
                self.perform()
            }
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
                             delay:  (() -> DispatchTime)? = nil,
                             callback: @escaping (TaskResult<Element>) -> ()) -> Self {
        return self.add { result in
            
            self.conditions.perform.lock()
            ////print("locks")
            DispatchQueue.performTask(in: queue, delay: delay) {
                if state == .all {
                    callback(result)
                } else if state == .failure && result.isError {
                    callback(result)
                } else if state == .success && !result.isError {
                    callback(result)
                }
                
                //print("broadcasting \(self.id) perform with \(address(of: &self.conditions.perform))")
                self.conditions.perform.unlock()
                ////print("unlocks")
            }
        }
    }
    
    @discardableResult
    public func then<U>(in queue: DispatchQueue? = nil,
                        on state: State = .all,
                        delay: (() -> DispatchTime)? = nil,
                        callback: @escaping (Element) throws -> (U)) -> Task<U> {
        let task = Task<U>.init()
        
        self.perform(in: queue, on: state, delay: delay) { result in
            //print(delay)
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
    
    @discardableResult
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
        ////print("done")
        return self.perform(in: queue, on: .success) { result in
            guard let value = result.value else { return }
            callback(value)
        }
    }
    
    @discardableResult
    public func always(in queue: DispatchQueue? = nil,
                       callback: @escaping (TaskResult<Element>) -> Void) -> Self {
        return self.perform(in: queue, callback: callback)
    }
    
    public func timeout(after: (() -> DispatchTime)) -> Self {
        return self
    }
    
    public func recover(callback: @escaping (Swift.Error) throws -> Element) -> Task<Element> {
        let task = Task<Element>()
        
        self.perform { result in
            switch result {
            case .success(let element):
                task.set(state: .success(element))
            case .failure(let error):
                do {
                    let result = try callback(error)
                    task.set(state: .success(result))
                } catch {
                    task.set(state: .failure(error))
                }
            }
        }
        
        return task
    }
    
    
}

public extension Task {
    public func send(_ element: Element) {
        self.set(state: .success(element))
    }
    
    public func `throw`(_ error: Swift.Error) {
        self.set(state: .failure(error))
    }
}

public extension Task {
    
    private func shouldWait() -> Bool {
        if case .ready = self.state {
            return true
        }
        
        return false
    }
    
    private func receiveElement() throws -> Element {
        switch self.state {
        case .success(let element):
            return element
        case .failure(let error):
            throw error
        case .timeout:
            throw TaskState<Element>.Error.timeout
        case .ready:
            throw TaskState<Element>.Error.didNotStart
        }
    }
    
    public func wait() throws -> Element {
        return try self.conditions.set.in {
            
            while self.shouldWait() {
                self.conditions.set.wait()
            }
            
            return try self.receiveElement()
        }
    }
    
    public func wait(for time: (() -> DispatchTime)) throws -> Element {
        return try self.conditions.set.in {
            
            let value = time()
            
            while self.shouldWait() && self.conditions.set.wait(timeout: value) { }
            
            //print("finishing wait at \(DispatchTime.now())")
            return try self.receiveElement()
        }
    }
}

public extension Task where Element == Void {
    
    @discardableResult
    public func finish() -> Self {
        self.set(state: .success(()))
        return self
    }
}

public extension Task where Element: Sequence {
    
    public typealias ArrayElement = Element.Iterator.Element
    
    public func map<U>(_ transform: @escaping (ArrayElement) throws -> U) -> Task<[U]> {
        return self.then { array in
            return try array.map { try transform($0) }
        }
    }
    
    public func flatMap<U>(_ transform: @escaping (ArrayElement) throws -> U?) -> Task<[U]> {
        return self.then { array in
            return try array.flatMap { try transform($0) }
        }
    }
    
    public func reduce<Result>(_ initial: Result,
                               _ transform: @escaping (Result, ArrayElement) throws -> Result) -> Task<Result> {
        return self.then { array in
            return try array.reduce(initial, transform)
        }
        
    }
    
    public func filter(_ isIncluded: @escaping (ArrayElement) throws -> Bool) -> Task<[ArrayElement]> {
        return self.then { array in
            return try array.filter(isIncluded)
        }
    }
    
}

public extension Task {
    
    public func `as`(_ type: Void.Type, _ convert: ((Element) -> T?)? = nil) -> Task<Void> {
        return self.then { _ in () as Void }
    }
    
    public func `as`<T>(_ type: T.Type, _ convert: ((Element) -> T?)? = nil) -> Task<T> {
        return self.then {
            guard let new = convert?($0) ?? $0 as? T else {
                throw TaskState<Element>.Error.convertationError
            }
            
            return new
        }
    }
}

public func combine<T>(tasks: [Task<T>]) -> Task<[T]> {
    let newTask = Task<[T]>()
    var (total, count, errored) = (tasks.count, 0, false)
    
    guard tasks.count > 0 else {
        newTask.send([])
        return newTask
    }
    
    for task in tasks {
        task.done { value in
            DispatchQueue.barrier.sync {
                guard !errored else { return }
                count += 1
                if total == count {
                    newTask.send(tasks.flatMap { $0.state.result?.value })
                }
            }
            }
            .catch { error in
                DispatchQueue.barrier.sync {
                    errored = true
                    newTask.throw(error)
                }
        }
    }
    
    return newTask
}

public extension Array where Element: TaskProtocol {
    
    public func combine() -> Task<[Element.Element]> {
        return Concurrency.combine(tasks: self.flatMap { $0 as? Task<Element.Element> })
    }
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
