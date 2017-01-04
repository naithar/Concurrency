//
//  Async.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 03.01.17.
//
//

import Dispatch

extension DispatchQueue {
    
    static let defaultCoroutineQueue = DispatchQueue(
        label: "swift-async.concurrent.queue",
        attributes: [.concurrent])
}

func coroutine(_ closure: (Void) -> Void) {
    
}

func coroutine<Element>(on queue: DispatchQueue? = nil,
               after delay: DispatchTime? = nil,
               _ closure: @autoclosure @escaping (Void) throws -> Element) -> Channel<Element> {
    let channel = Channel<Element>()
    
    func action() {
        do {
            let value = try closure()
            try? channel.send(value)
        } catch {
            try? channel.throw(error)
        }
    }

    let queue = queue ?? DispatchQueue.defaultCoroutineQueue
    
    if let delay = delay {
        queue.asyncAfter(deadline: delay, execute: action)
    } else {
        queue.async(execute: action)
    }
    
    return channel
}
