extension Affine.Discrete.Ratio where From: ~Copyable, To == Memory {

    @inlinable
    public static var stride: Self { .init(MemoryLayout<From>.stride) }
}
