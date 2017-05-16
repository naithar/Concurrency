//
//  Task+MapReduce.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

extension Task where Element: Sequence {
    
    public typealias ArrayElement = Element.Iterator.Element
    
    public func map<U>(_ transform: @escaping (ArrayElement) throws -> U) -> Task<[U]> {
        return self.then { array in
            return try array.map { try transform($0) }
        }
    }
    
    public func flatMap<U>(_ transform: @escaping (ArrayElement) throws -> U?) -> Task<[U]> {
        return self.then { array in
            return try array.flatMap { try transform($0) }
        }
    }
    
    public func reduce<Result>(_ initial: Result,
                _ transform: @escaping (Result, ArrayElement) throws -> Result) -> Task<Result> {
        return self.then { array in
            return try array.reduce(initial, transform)
        }
        
    }
    
    public func filter(_ isIncluded: @escaping (ArrayElement) throws -> Bool) -> Task<[ArrayElement]> {
        return self.then { array in
            return try array.filter(isIncluded)
        }
    }
}
