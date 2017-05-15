//
//  Task+MapReduce.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

extension Task where Element: Sequence {
    
    typealias ArrayElement = Element.Iterator.Element
    
    func map<U>(_ action: (ArrayElement) throws -> U) -> Task<[U]> {
        let newTask = Task<[U]>()
        
        return newTask
    }
    
    func flatMap<U>(_ action: (ArrayElement) throws -> U?) -> Task<[U]> {
        let newTask = Task<[U]>()
        
        return newTask
    }
    
    func reduce<Result>(_ initial: Result, _ action: (Result, ArrayElement) throws -> Result) -> Task<Result> {
        let newTask = Task<Result>()
        
        return newTask
    }
}

//func foo() {

//    [Task<Int>(), Task<Int>()].combine().map(<#T##action: (Int) -> U##(Int) -> U#>)
//}
