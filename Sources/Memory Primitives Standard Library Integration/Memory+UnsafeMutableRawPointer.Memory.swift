public import Index_Primitives
public import Memory_Address_Primitives
import Property_Primitives

extension UnsafeMutableRawPointer {

    @inlinable
    public var memory: Property_Primitives.Property<Memory, Self> {
        unsafe Property_Primitives.Property(self)
    }
}

extension Property_Primitives.Property
where Tag == Memory, Base == UnsafeMutableRawPointer {

    @inlinable
    @discardableResult
    public func initialize<T>(
        as type: T.Type,
        repeating value: T,
        count: Index_Primitives.Index<T>.Count
    ) -> UnsafeMutablePointer<T> {
        unsafe base.initializeMemory(as: type, repeating: value, count: Int(bitPattern: count))
    }

    @inlinable
    @discardableResult
    public func initialize<T>(
        as type: T.Type,
        from source: UnsafePointer<T>,
        count: Index_Primitives.Index<T>.Count
    ) -> UnsafeMutablePointer<T> {
        unsafe base.initializeMemory(as: type, from: source, count: Int(bitPattern: count))
    }

    @inlinable
    @discardableResult
    public func bind<T: ~Copyable>(
        to type: T.Type,
        capacity: Index_Primitives.Index<T>.Count
    ) -> UnsafeMutablePointer<T> {
        unsafe base.bindMemory(to: type, capacity: Int(bitPattern: capacity))
    }

    @inlinable
    public func copy(
        from source: UnsafeRawPointer,
        count: Memory.Address.Count
    ) {
        unsafe base.copyMemory(from: source, byteCount: Int(bitPattern: count))
    }

    @inlinable
    public var move: Property_Primitives.Property<Memory.Move, Base> {
        unsafe Property_Primitives.Property(base)
    }
}
