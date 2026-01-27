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
        public typealias Error = Never

        public init() {}

        @inlinable
        public func allocate(
            count: Index<UInt8>.Count,
            alignment: Index<UInt8>.Count
        ) throws(Never) -> Memory.Address.Mutable {
            Memory.Address.Mutable.allocate(count: count, alignment: alignment)
        }

        @inlinable
        public func deallocate(
            _ address: Memory.Address.Mutable,
            count: Index<UInt8>.Count,
            alignment: Index<UInt8>.Count
        ) {
            // System allocator doesn't need count/alignment for deallocation
            address.deallocate()
        }
    }
}
