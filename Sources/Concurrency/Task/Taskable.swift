//
//  Taskable.swift
//  Concurrency
//
//  Created by Sergey Minakov on 30.01.17.
//
//

import Dispatch

public protocol Taskable: Sendable, Waitable {
    
    associatedtype Element
    
    var error: Swift.Error? { get }
    
    //TODO: global error
    
    init(on queue: DispatchQueue?, delay: DispatchTime?, _ closure: @escaping (Task.Sending<Self>) throws -> Void)
}
