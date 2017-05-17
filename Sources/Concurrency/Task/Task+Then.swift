//
//  Task+Then.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

import Dispatch

public extension Task {
    
    private func observe<Result>(on queue: DispatchQueue,
                         delay: (() -> DispatchTime)?,
                         task: Task<Result>,
                         with action: @escaping (Element) throws -> Result) {
        let handler = Observer<Element>
            .Handler(
                queue: queue,
                delay: delay) { result in
                    switch result {
                    case .some(let value):
                        do {
                            let value = try action(value)
                            task.send(value)
                        } catch {
                            task.throw(error)
                        }
                    case .error(let error):
                        task.throw(error)
                    }
        }
        
        self.condition.mutex.in {
            self.observer.add(handler: handler)
        }
        self.update()
    }
    
    @discardableResult
    public func then<Result>(on queue: DispatchQueue = .task,
                     _ action: @escaping (Element) throws -> Result) -> Task<Result> {
        let newTask = Task<Result>()
        
        self.observe(on: queue,
                     delay: nil,
                     task: newTask,
                     with: action)
        
        return newTask
    }
    
    @discardableResult
    public func then<Result>(on queue: DispatchQueue = .task,
                     delay: @autoclosure @escaping () -> DispatchTime,
                     _ action: @escaping (Element) throws -> Result) -> Task<Result> {
        let newTask = Task<Result>()
        
        self.observe(on: queue,
                     delay: delay,
                     task: newTask,
                     with: action)
        
        return newTask
    }
}

public extension Task where Element: Taskable {
    
    public typealias TaskElement = Element.Element
    
    private func unwrap(to newTask: Task<TaskElement>,
                        on queue: DispatchQueue,
                        delay: (() -> DispatchTime)?) {
        
        func unwrap<T: Taskable>(from task: T) {
            guard let task = task as? Task<TaskElement> else {
                newTask.throw(TaskError.unwrapError)
                return
            }
            
            task.done { newTask.send($0) }
                .catch { newTask.throw($0) }
        }
        
        if let delay = delay {
            self.then(on: queue, delay: delay()) { actualTask in
                unwrap(from: actualTask)
            }
        } else {
            self.then(on: queue) { actualTask in
                unwrap(from: actualTask)
            }
        }
    }
    
    @discardableResult
    public func unwrap(on queue: DispatchQueue = .task) -> Task<TaskElement> {
        let newTask = Task<TaskElement>()
        
        self.unwrap(to: newTask, on: queue, delay: nil)
        
        return newTask
    }
    
    @discardableResult
    public func unwrap(on queue: DispatchQueue = .task,
                       delay: @autoclosure @escaping () -> DispatchTime) -> Task<TaskElement> {
        let newTask = Task<TaskElement>()
        
        self.unwrap(to: newTask, on: queue, delay: nil)
        
        return newTask
    }
}
