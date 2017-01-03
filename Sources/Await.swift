//
//  Await.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 03.01.17.
//
//

import Dispatch

@discardableResult
func await<Element>(_ task: @autoclosure (Void) -> Task<Element>) throws -> Element {
    let task = task()
    let value = try task.receive()
    return value
}

@discardableResult
func await<Element>(timeout: DispatchTime, task: @autoclosure (Void) -> Task<Element>) throws -> Element {
    let task = task()
    let value = try task.receive(timeout: timeout)
    return value
}
