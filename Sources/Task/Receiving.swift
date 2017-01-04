//
//  Receiving.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 04.01.17.
//
//

import Dispatch

public protocol Receiving {
    
    associatedtype Element
    
    @discardableResult
    func receive() throws -> Element
    
    @discardableResult
    func receive(timeout: DispatchTime) throws -> Element
}
