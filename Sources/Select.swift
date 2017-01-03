//
//  Select.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 03.01.17.
//
//

public func select(_ action: (SelectSwitch) -> Void) {
    let builder = SelectSwitch()
    action(builder)
    builder.wait()
}

protocol SelectCase {
    
}

public class TaskCase<T>: SelectCase {
    
    public typealias Action = (T?, Swift.Error?) -> Void
    var task: Task<T>
    var action: Action
    
    init(task: Task<T>, action: @escaping Action) {
        self.task = task
        self.action = action
    }
    
    func execute() {
//        self.action()
    }
}

public class SelectSwitch {
    
    var cases = [SelectCase]()
    var otherwise: ((Void) -> Void)?
    
    public func receive<Element>(_ task: Task<Element>, action: @escaping TaskCase<Element>.Action) {
        
    }
    
    public func otherwise(action: @escaping (Void) -> Void) {
        guard self.otherwise == nil else {
            return
        }
        
        self.otherwise = action
    }
    
    internal func wait() {
        
        //check all
        //wait for signal
    }
    
    private func checkAllTasks() -> Bool {
        return false
    }
}
