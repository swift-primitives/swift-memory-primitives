// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-memory-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-memory-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

extension Memory {
    /// Namespace for allocator-related types.
    public struct Allocator: Memory.Allocator.`Protocol`, Sendable {
        public init() {}

        @inlinable
        public func allocate(
            count: Memory.Address.Count,
            alignment: Memory.Address.Count
        ) throws(Never) -> Memory.Mutable.Address {
            Memory.Mutable.Address.allocate(count: count, alignment: alignment)
        }

        @inlinable
        public func deallocate(
            _ address: Memory.Mutable.Address,
            count: Memory.Address.Count,
            alignment: Memory.Address.Count
        ) {
            // System allocator doesn't need count/alignment for deallocation
            address.deallocate()
        }
    }
}
