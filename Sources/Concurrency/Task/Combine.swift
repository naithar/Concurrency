//
//  Combine.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

import Foundation

extension Task {
    
    enum Error: Swift.Error {
        case convertationError
    }
    
    func `as`<T>(_ type: T.Type, conversion: ((Element) -> T?)? = nil) -> Task<T> {
        return self.then {
            guard let new = conversion?($0) ?? $0 as? T else {
                throw Error.convertationError
            }
            
            return new
        }
    }
}

func combine<T>(tasks: [Task<T>]) -> Task<[T]> {
    let newTask = Task<[T]>()
    var (total, count) = (tasks.count, 0)
    
    guard tasks.count > 0 else {
        newTask.send([])
        return newTask
    }
    
    for task in tasks {
        task.done { value in
                DispatchQueue.barrier.sync {
                    count += 1
                    if total == count {
                        newTask.send(tasks.flatMap { $0.state.result?.value })
                    }
                }
            }
            .catch { error in
                DispatchQueue.barrier.sync {
                    newTask.throw(error)
                }
        }
    }
    
    return newTask
}

extension Array where Element: Taskable {

    func combine() -> Task<[Element.Element]> {
        return Concurrency.combine(tasks: self.flatMap { $0 as? Task<Element.Element> })
    }
}
