//
//  Async.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 03.01.17.
//
//

import Foundation
import Dispatch


@discardableResult
func async<Element>(on queue: DispatchQueue? = nil,
           _ closure: @autoclosure (Void) throws -> Element) -> Task<Element> {
    return Task<Element>()
}

@discardableResult
func async<Element>(on queue: DispatchQueue? = nil,
           after timeout: DispatchTime,
           _ closure: @autoclosure (Void) throws -> Element) -> Task<Element> {
    return Task<Element>()
}

@discardableResult
func async<Element>(on queue: DispatchQueue? = nil,
           after timeout: TimeInterval,
           _ closure: @autoclosure (Void) throws -> Element) -> Task<Element> {
    return Task<Element>()
}
