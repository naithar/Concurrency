//
//  TaskBuffer+Hashable.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 07.01.17.
//
//

extension TaskBuffer: Hashable {
    
    public var hashValue: Int {
        return self.id.hashValue
    }
    
    public static func ==(lhs: TaskBuffer, rhs: TaskBuffer) -> Bool {
        return lhs.id == rhs.id
    }
    
    public static func !=(lhs: TaskBuffer, rhs: TaskBuffer) -> Bool {
        return !(lhs == rhs)
    }
}
