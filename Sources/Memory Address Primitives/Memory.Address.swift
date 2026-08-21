import Affine_Primitives
import Cardinal_Primitives
public import Ordinal_Primitives
public import Tagged_Primitives

extension Memory {

    public typealias Address = Tagged<Memory, Ordinal>
}

extension Tagged where Tag == Memory, Underlying == Ordinal {

    @inlinable
    public init(_ pointer: UnsafeRawPointer) {
        self.init(_unchecked: Ordinal(UInt(bitPattern: pointer)))
    }

    @inlinable
    public init<T>(_ pointer: UnsafePointer<T>) {
        unsafe self.init(UnsafeRawPointer(pointer))
    }

    @inlinable
    public init<T>(_ pointer: UnsafeMutablePointer<T>) {
        unsafe self.init(UnsafeRawPointer(pointer))
    }

    @inlinable
    public init(_ pointer: UnsafeMutableRawPointer) {
        unsafe self.init(UnsafeRawPointer(pointer))
    }
}

extension Tagged where Tag == Memory, Underlying == Ordinal {

    @inlinable
    public init(_ pointer: UnsafeRawPointer?) throws(Self.Error) {
        guard let pointer = unsafe pointer else { throw .null }
        unsafe self.init(pointer)
    }

    @inlinable
    public init<T>(_ pointer: UnsafePointer<T>?) throws(Self.Error) {
        guard let pointer = unsafe pointer else { throw .null }
        unsafe self.init(pointer)
    }

    @inlinable
    public init<T>(_ pointer: UnsafeMutablePointer<T>?) throws(Self.Error) {
        guard let pointer = unsafe pointer else { throw .null }
        unsafe self.init(pointer)
    }

    @inlinable
    public init(_ pointer: UnsafeMutableRawPointer?) throws(Self.Error) {
        guard let pointer = unsafe pointer else { throw .null }
        unsafe self.init(pointer)
    }
}

extension Tagged where Tag == Memory, Underlying == Ordinal {

    @inlinable
    public var bitPattern: UInt { underlying.rawValue }
}

extension UnsafeRawPointer {

    @inlinable
    public init(_ address: Memory.Address) {

        unsafe self = UnsafeRawPointer(bitPattern: address.bitPattern)!
    }

    @inlinable
    public init<Tag: ~Copyable & ~Escapable>(_ address: Tagged<Tag, Memory.Address>) {
        unsafe self.init(address.underlying)
    }
}

extension UnsafeMutableRawPointer {

    @inlinable
    public init(_ address: Memory.Address) {

        unsafe self = UnsafeMutableRawPointer(bitPattern: address.bitPattern)!
    }

    @inlinable
    public init<Tag: ~Copyable & ~Escapable>(_ address: Tagged<Tag, Memory.Address>) {
        unsafe self.init(address.underlying)
    }
}

extension Tagged where Tag == Memory, Underlying == Ordinal {

    @inlinable
    public var mutablePointer: UnsafeMutableRawPointer {
        unsafe UnsafeMutableRawPointer(self)
    }

    @inlinable
    public var pointer: UnsafeRawPointer {
        unsafe UnsafeRawPointer(self)
    }
}
