//
//  Runnable.swift
//  Concurrency
//
//  Created by Sergey Minakov on 15.05.17.
//
//

import Dispatch

public struct Runnable<T> {
    var queue: DispatchQueue
    var delay: (() -> DispatchTime)?
    var action: (T) -> Void
    
    func perform(with value: T) {
        if let delay = self.delay {
            self.queue
                .asyncAfter(deadline: delay()) {
                    self.action(value)
            }
        } else {
            self.queue
                .async {
                    self.action(value)
            }
        }
    }
}
