//
//  Atomic+Operators.swift
//  SwiftAsync
//
//  Created by Sergey Minakov on 05.01.17.
//
//

// MARK: Equatable (==)

public func ==<Element: Equatable>(left: Atomic<Element>, right: Atomic<Element>) -> Bool {
    return left.value == right.value
}

public func ==<Element: Equatable>(left: Atomic<Element>, right: Element) -> Bool {
    return left.value == right
}

public func ==<Element: Equatable>(left: Element, right: Atomic<Element>) -> Bool {
    return left == right.value
}

// MARK: Equatable (!=)

public func !=<Element: Equatable>(left: Atomic<Element>, right: Atomic<Element>) -> Bool {
    return !(left.value == right.value)
}

public func !=<Element: Equatable>(left: Atomic<Element>, right: Element) -> Bool {
    return !(left.value == right)
}

public func !=<Element: Equatable>(left: Element, right: Atomic<Element>) -> Bool {
    return !(left == right.value)
}

// MARK: Bool (&&)

public func &&(left: Atomic<Bool>, right: Atomic<Bool>) -> Bool {
    return left.value && right.value
}

public func &&(left: Atomic<Bool>, right: Bool) -> Bool {
    return left.value && right
}

public func &&(left: Bool, right: Atomic<Bool>) -> Bool {
    return left && right.value
}

// MARK: Bool (||)

public func ||(left: Atomic<Bool>, right: Atomic<Bool>) -> Bool {
    return left.value || right.value
}

public func ||(left: Atomic<Bool>, right: Bool) -> Bool {
    return left.value || right
}

public func ||(left: Bool, right: Atomic<Bool>) -> Bool {
    return left || right.value
}

// MARK: Bool (!)

public prefix func !(value: Atomic<Bool>) -> Bool {
    return !value.value
}

// MARK: Comparable (>)

public func ><Element: Comparable>(left: Atomic<Element>, right: Atomic<Element>) -> Bool {
    return left.value > right.value
}

public func ><Element: Comparable>(left: Atomic<Element>, right: Element) -> Bool {
    return left.value > right
}

public func ><Element: Comparable>(left: Element, right: Atomic<Element>) -> Bool {
    return left > right.value
}

// MARK: Comparable (>=)

public func >=<Element: Comparable>(left: Atomic<Element>, right: Atomic<Element>) -> Bool {
    return left.value >= right.value
}

public func >=<Element: Comparable>(left: Atomic<Element>, right: Element) -> Bool {
    return left.value >= right
}

public func >=<Element: Comparable>(left: Element, right: Atomic<Element>) -> Bool {
    return left >= right.value
}

// MARK: Comparable (<)

public func <<Element: Comparable>(left: Atomic<Element>, right: Atomic<Element>) -> Bool {
    return left.value < right.value
}

public func <<Element: Comparable>(left: Atomic<Element>, right: Element) -> Bool {
    return left.value < right
}

public func <<Element: Comparable>(left: Element, right: Atomic<Element>) -> Bool {
    return left < right.value
}

// MARK: Comparable (<=)

public func <=<Element: Comparable>(left: Atomic<Element>, right: Atomic<Element>) -> Bool {
    return left.value <= right.value
}

public func <=<Element: Comparable>(left: Atomic<Element>, right: Element) -> Bool {
    return left.value <= right
}

public func <=<Element: Comparable>(left: Element, right: Atomic<Element>) -> Bool {
    return left <= right.value
}
