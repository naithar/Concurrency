//
//  Task+MapReduce.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

extension Task where Element: Sequence {
    
    typealias ArrayElement = Element.Iterator.Element
    
    func map<U>(transform: @escaping (ArrayElement) throws -> U) -> Task<[U]> {
        return self.then { array in
            return try array.map { try transform($0) }
        }
    }
    
    func flatMap<U>(transform: @escaping (ArrayElement) throws -> U?) -> Task<[U]> {
        return self.then { array in
            return try array.flatMap { try transform($0) }
        }
    }
    
    func reduce<Result>(_ initial: Result,
                _ transform: @escaping (Result, ArrayElement) throws -> Result) -> Task<Result> {
        return self.then { array in
            return try array.reduce(initial, transform)
        }
    }
}
