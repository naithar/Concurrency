//
//  Observer.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

public struct Observer<Element> {
    
    public typealias Handler = Runnable<Result<Element>>
    
    private var handlers = [Handler]()
    
    mutating func add(handler: Handler) {
        self.handlers.append(handler)
    }
    
    func fire(with result: Result<Element>, finished: () -> Void) {
        for item in self.handlers {
            item.perform(with: result)
        }
        
        finished()
    }
    
    mutating func clear() {
        self.handlers.removeAll()
    }
}
