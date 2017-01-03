//
//  DispatchTime+Extensions.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 03.01.17.
//
//

import Foundation
import Dispatch


extension DispatchTime {
    
    public var timeInterval: TimeInterval {
        let timeDelta = self.rawValue - DispatchTime.now().rawValue
        let interval = Double(timeDelta) / Double(NSEC_PER_SEC)
        return interval
    }
}

extension DispatchWallTime {
    
    public var timeInterval: TimeInterval {
        let timeDelta = DispatchWallTime.now().rawValue - self.rawValue
        let interval = Double(timeDelta) / Double(NSEC_PER_SEC)
        return interval
    }
}
