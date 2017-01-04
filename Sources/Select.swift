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

public class SelectCase: Hashable {
    
    public var hashValue: Int {
        return 0
    }
    
    public static func ==(lhs: SelectCase, rhs: SelectCase) -> Bool {
        return false
    }
}

public class ChannelCase<T>: SelectCase {
    
    public typealias Action = (T?, Swift.Error?) -> Void
    var task: Channel<T>
    var action: Action
    
    init(task: Channel<T>, action: @escaping Action) {
        self.task = task
        self.action = action
    }
    
    func execute() -> Bool {
        return false
    }
    
    public override var hashValue: Int {
        return self.task.hashValue
    }
    
    public static func ==(lhs: ChannelCase, rhs: ChannelCase) -> Bool {
        return lhs.task == rhs.task
    }
}

public class SelectSwitch {
    
    var cases = [SelectCase]()
    var otherwise: ((Void) -> Void)?
    
    public func receive<Element>(_ task: Channel<Element>, action: @escaping ChannelCase<Element>.Action) {
        let `case` = ChannelCase(task: task, action: action)
        if !self.cases.contains(`case`) {
            self.cases.append(`case`)
        }
    }
    
    public func timeout() {
        
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
