public import Memory_Address_Primitives
public import Memory_Primitive

extension Memory {

    public protocol Region: ~Copyable {

        var base: Memory.Address { get }

        var capacity: Memory.Address.Count { get }
    }
}
