//
//  Async.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 03.01.17.
//
//

import Dispatch

extension DispatchQueue {
    
    static let asyncQueue = DispatchQueue(
        label: "swift-async.concurrent.queue",
        attributes: [.concurrent])
}

@discardableResult
func async<Element>(on queue: DispatchQueue? = nil,
           after delay: DispatchTime? = nil,
           _ closure: @autoclosure @escaping (Void) throws -> Element) -> Task<Element> {
    let task = Task<Element>()
    
    func action() {
        do {
            let value = try closure()
            try? task.send(value)
        } catch {
            try? task.throw(error)
        }
    }
    
    let taskQueue = queue ?? DispatchQueue.asyncQueue
    
    if let delay = delay {
        taskQueue.asyncAfter(deadline: delay, execute: action)
    } else {
        taskQueue.async(execute: action)
    }
    
    return task
}
