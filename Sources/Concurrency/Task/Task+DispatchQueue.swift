//
//  Task+DispatchQueue.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

extension DispatchQueue {
    
    static let task = DispatchQueue(label: "concurrency.task.queue", attributes: .concurrent)
}
