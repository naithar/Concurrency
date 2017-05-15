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

func combine<T>(_ tasks: [Task<T>]) -> Task<[T]> {
    let newTask = Task<[T]>()
    var (total, array) = (tasks.count, [T]())
    
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

//extension Array where Element: Task<Equatable> {
//
//    func combine() {
//
//    }
//}
//
//func f() {
//
//    [Task<Int>(), Task<Int>()].co
//}
