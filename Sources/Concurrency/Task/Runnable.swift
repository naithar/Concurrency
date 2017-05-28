//
//  Runnable.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

import Dispatch

public struct Runnable<T> {
    private(set) var queue: DispatchQueue
    private(set) var delay: (() -> DispatchTime)?
    private(set) var action: ((T) -> Void)?
    
    func perform(with value: T) {
        if let delay = self.delay {
            self.queue
                .asyncAfter(deadline: delay()) {
                    self.action?(value)
            }
        } else {
            self.queue
                .async {
                    self.action?(value)
            }
        }
    }
    
    mutating func clear() {
        self.delay = nil
        self.action = nil
    }
}
