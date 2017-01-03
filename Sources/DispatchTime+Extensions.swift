//
//  DispatchTime+Extensions.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 03.01.17.
//
//

import Dispatch


extension DispatchTime {
    
    public var ms: Int {
        let now = DispatchTime.now()
        guard self >= now else {
            return 0
        }
        let timeDelta = self.rawValue - now.rawValue
        let interval = timeDelta / NSEC_PER_MSEC
        return Int(interval)
    }
}
