//
//  Task+DispatchQueue.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

import Dispatch

public extension DispatchQueue {
    
    static let task = DispatchQueue(label: "concurrency.task.queue", attributes: [.concurrent])
    static let instant = DispatchQueue(label: "concurrency.task.queue.instant", attributes: [])
}
