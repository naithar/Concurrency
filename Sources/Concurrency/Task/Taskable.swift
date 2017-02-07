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
    
    init(on queue: DispatchQueue?, _ builder: @escaping (Task.Sending<Self>) throws -> Void)
    init(on queue: DispatchQueue?, delay: @autoclosure @escaping () -> DispatchTime, _ builder: @escaping (Task.Sending<Self>) throws -> Void)
}
