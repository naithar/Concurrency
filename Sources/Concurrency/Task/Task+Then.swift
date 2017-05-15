//
//  Task+Then.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

extension Task {
    
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
        
        self.observer.add(handler: handler)
    }
    
    @discardableResult
    public func then<Result>(on queue: DispatchQueue = .main,
                     _ action: @escaping (Element) throws -> Result) -> Task<Result> {
        let newTask = Task<Result>()
        
        self.observe(on: queue,
                     delay: nil,
                     task: newTask,
                     with: action)
        
        return newTask
    }
    
    @discardableResult
    public func then<Result>(on queue: DispatchQueue = .main,
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
