//
//  Receiving.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 04.01.17.
//
//

import Dispatch

public protocol WaitableProtocol {
    
    associatedtype Element
    
    @discardableResult
    func wait() throws -> Element
    
    @discardableResult
    func wait(timeout: DispatchTime) throws -> Element
}
