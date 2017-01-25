//
//  Sending.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 04.01.17.
//
//

public protocol SendableProtocol {
    
    associatedtype Element
    
    func send(_ value: Element) throws
    
    func `throw`(_ error: Swift.Error) throws
}
