//
//  Result.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

public enum Result<Element> {
    case some(Element)
    case error(Swift.Error)
}
