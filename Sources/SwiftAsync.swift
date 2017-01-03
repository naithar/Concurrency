#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import Dispatch


@discardableResult
func async<Element>(on queue: DispatchQueue? = nil, _ closure: @autoclosure (Void) throws -> Element) -> Task<Element> {
    return Task<Element>()
}

@discardableResult
func await<Element>(_ closure: @autoclosure (Void) -> Task<Element>) throws -> Element? {
    return nil
}
