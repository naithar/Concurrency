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
    
    func `as`<T>(_ type: T.Type) -> Task<T> {
        return self.then {
            guard let new = $0 as? T else {
                throw Error.convertationError
            }
            
            return new
        }
    }
}

func combine<T>(tasks: [Task<T>]) -> Task<[T]> {
    let newTask = Task<[T]>()
    var (total, array) = (tasks.count, [T]())
    
    guard tasks.count > 0 else {
        newTask.send([])
        return newTask
    }
    
    for task in tasks {
        task
            .done { value in
                DispatchQueue.barrier.sync {
                    array.append(value)
                    if total == array.count {
                        newTask.send(array)
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
