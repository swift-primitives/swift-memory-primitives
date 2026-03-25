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
    /// Self-owning contiguous typed memory region.
    ///
    /// `Memory.Contiguous<Element>` owns a heap-allocated buffer of
    /// `BitwiseCopyable` elements and deallocates it on destruction.
    /// It provides safe read access via ``span`` (conforming to
    /// ``Memory.Contiguous/Protocol``) and serves as the Level 2
    /// memory primitive — above raw pointers, below `Storage<Element>`.
    ///
    /// ## BitwiseCopyable Boundary
    ///
    /// The `BitwiseCopyable` constraint guarantees that bulk deallocation
    /// is sound — no per-element deinit is needed. Types requiring
    /// per-element lifecycle management use `Storage<Element>` (Level 3).
    ///
    /// ## Ownership
    ///
    /// The struct adopts a pointer at init and owns the memory exclusively.
    /// It is `~Copyable` (move-only) to prevent double-free. The deinit
    /// deallocates the buffer.
    ///
    /// ## Thread Safety
    ///
    /// `@unchecked Sendable` because the pointer is read-only after init.
    /// The struct provides no mutation API — only borrowed read access
    /// via ``span``.
    ///
    /// ## Type/View Pattern
    ///
    /// - `Memory.Contiguous<Element>` — the owned form (this type)
    /// - `Memory.Contiguous<Element>.View` (= `Span<Element>`) — the borrowed form
    @frozen
    @safe
    public struct Contiguous<Element: BitwiseCopyable>: ~Copyable, @unchecked Sendable {
        /// Preserves `Memory.Contiguous.Protocol` naming for all consumer code.
        public typealias `Protocol` = Memory.ContiguousProtocol

        @usableFromInline
        internal let pointer: UnsafePointer<Element>

        /// The base address of the memory region.
        ///
        /// - Warning: The pointer is only valid for the lifetime of this value.
        @unsafe
        @inlinable
        public var unsafeBaseAddress: UnsafePointer<Element> { unsafe pointer }

        /// The number of elements in the region.
        public let count: Int

        /// Adopts ownership of an allocated buffer.
        ///
        /// After this call, the struct owns the memory pointed to by `pointer`
        /// and will deallocate it on destruction. The caller must not use or
        /// deallocate the pointer after passing it here.
        ///
        /// - Parameters:
        ///   - pointer: A pointer to allocated memory containing `count` initialized elements.
        ///   - count: The number of elements in the buffer.
        @inlinable
        public init(adopting pointer: UnsafeMutablePointer<Element>, count: Int) {
            unsafe self.pointer = UnsafePointer(pointer)
            self.count = count
        }

        /// Transfers ownership of the underlying buffer to the caller.
        ///
        /// Returns the pointer and count. The caller is responsible for
        /// deallocation. This instance is consumed without deallocating.
        ///
        /// - Returns: A tuple of (pointer, count).
        @unsafe
        @inlinable
        public consuming func take() -> (pointer: UnsafeMutablePointer<Element>, count: Int) {
            let result = unsafe (UnsafeMutablePointer(mutating: pointer), count)
            discard self
            return unsafe result
        }

        @inlinable
        deinit {
            unsafe UnsafeMutablePointer(mutating: pointer).deallocate()
        }
    }
}
