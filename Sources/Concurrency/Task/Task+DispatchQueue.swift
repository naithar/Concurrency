//
//  Task+DispatchQueue.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

import Dispatch

public extension DispatchQueue {
    
    public static let task = DispatchQueue(label: "concurrency.task.queue", attributes: [.concurrent])
    
    public static let barrier = DispatchQueue(label: "concurrency.task.queue.barrier", attributes: [.concurrent])
}
