//
//  Channel+Hashable.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 04.01.17.
//
//

extension TaskValue: Hashable {
    
    public var hashValue: Int {
        return self.id.hashValue
    }
    
    public static func ==(lhs: TaskValue, rhs: TaskValue) -> Bool {
        return lhs.id == rhs.id
    }
    
    public static func !=(lhs: TaskValue, rhs: TaskValue) -> Bool {
        return !(lhs == rhs)
    }
}
