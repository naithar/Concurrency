//
//  State.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

public enum State<Element> {
    case ready
    case finished(Element)
    case error(Swift.Error)
    
    var result: Result<Element>? {
        switch self {
        case .finished(let value):
            return Result<Element>.some(value)
        case .error(let error):
            return Result<Element>.error(error)
        case .ready:
            return nil
        }
    }
}
