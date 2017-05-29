//
//  Task+Then.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

import Dispatch

public struct TaskState: OptionSet {
    
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let any: TaskState = [.success, .fail]
    public static let success = TaskState(rawValue: 1 << 1)
    public static let fail = TaskState(rawValue: 1 << 2)
}

public extension Task {

    
    private func observe<Result>(on state: TaskState,
                         in queue: DispatchQueue,
                         delay: (() -> DispatchTime)?,
                         task: Task<Result>,
                         with action: @escaping (Element) throws -> Result) {
        
        let handler = Observer<Element>
            .Handler(
                queue: queue,
                delay: delay) { result in
                    switch result {
                    case .some(let value):
                        guard state.contains(.success) else { return }
                        do {
                            let value = try action(value)
                            task.send(value)
                        } catch {
                            guard state.contains(.fail) else { return }
                            task.throw(error)
                        }
                    case .error(let error):
                        guard state.contains(.fail) else { return }
                        task.throw(error)
                    }
        }
        
        self.condition.mutex.in {
            self.observer.add(handler: handler)
        }
        self.update()
    }
    
    
    @discardableResult
    public func then<Result>(on state: TaskState = .any,
                     in queue: DispatchQueue = .task,
                     _ action: @escaping (Element) throws -> Result) -> Task<Result> {
        let newTask = Task<Result>()
        
        self.observe(on: state,
                     in: queue,
                     delay: nil,
                     task: newTask,
                     with: action)
        
        return newTask
    }
    
    @discardableResult
    public func then<Result>(on state: TaskState = .any,
                     in queue: DispatchQueue = .task,
                     delay: @autoclosure @escaping () -> DispatchTime,
                     _ action: @escaping (Element) throws -> Result) -> Task<Result> {
        let newTask = Task<Result>()
        
        self.observe(on: state,
                     in: queue,
                     delay: delay,
                     task: newTask,
                     with: action)
        
        return newTask
    }
}

public extension Task where Element: _Taskable {
    
    public typealias TaskElement = Element.Element
    
    private func unwrap(to newTask: Task<TaskElement>,
                        on state: TaskState = .any,
                        in queue: DispatchQueue,
                        delay: (() -> DispatchTime)?) {
        
        func unwrap<T: _Taskable>(from task: T) {
            guard let task = task as? Task<TaskElement> else {
                newTask.throw(TaskError.unwrapError)
                return
            }
            
            task
                .done { value in
                    guard state.contains(.success) else { return }
                    newTask.send(value) }
                .catch { error in
                    guard state.contains(.fail) else { return }
                    newTask.throw(error) }
        }
        
        if let delay = delay {
            self.then(in: queue, delay: delay()) { actualTask in
                unwrap(from: actualTask)
            }
        } else {
            self.then(in: queue) { actualTask in
                unwrap(from: actualTask)
            }
        }
    }
    
    @discardableResult
    public func unwrap(on: TaskState = .any,
                       in queue: DispatchQueue = .task) -> Task<TaskElement> {
        let newTask = Task<TaskElement>()
        
        self.unwrap(to: newTask, in: queue, delay: nil)
        
        return newTask
    }
    
    @discardableResult
    public func unwrap(on: TaskState = .any,
                       in queue: DispatchQueue = .task,
                       delay: @autoclosure @escaping () -> DispatchTime) -> Task<TaskElement> {
        let newTask = Task<TaskElement>()
        
        self.unwrap(to: newTask, in: queue, delay: nil)
        
        return newTask
    }
}
