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
    /// ## Safety Invariant
    ///
    /// `Memory.Contiguous` is `@frozen struct ~Copyable` owning an
    /// `UnsafePointer<Element>` that `deinit` deallocates. The encapsulation
    /// invariant — unsafe pointer behind a safe API — is asserted by
    /// adjacent `// SAFETY:` invariant comment per [MEM-SAFE-025a]; the
    /// `@safe` attribute is forbidden in `Sources/` per [MEM-SAFE-025b].
    /// The pointer is `internal let` (read-only after init) and the
    /// struct provides no mutation API. Under unique ownership, the
    /// only reader at any time is the current owner; cross-thread transfer
    /// via move relinquishes the sender's access, so no concurrent read +
    /// deallocate race is possible.
    ///
    /// ## Intended Use
    ///
    /// - Moving a loaded contiguous buffer to a worker or actor for
    ///   read-only processing.
    /// - Handing a `BitwiseCopyable` element region across isolation
    ///   boundaries where bulk deallocation is the cleanup model.
    ///
    /// ## Non-Goals
    ///
    /// - Not shareable — only one owner exists at a time.
    /// - Does not expose mutation; consumers that need mutable access must
    ///   build on a different primitive.
    /// - `unsafeBaseAddress` is a deliberate escape hatch; sharing the
    ///   returned pointer independently of the `Memory.Contiguous` owner is
    ///   unsafe and unsupported.
    ///
    /// ## Owned / Borrowed Pattern
    ///
    /// - `Memory.Contiguous<Element>` — the owned form (this type), which
    ///   conforms to `Span.\`Protocol\`` (the namespace-neutral OWNED
    ///   span-vending capability) and vends read access via ``span``.
    /// - A borrowed contiguous view is a bare `Swift.Span<Element>`, surfaced
    ///   through `Span.\`Protocol\`` (`Swift.Span` self-conforms). There
    ///   is no nominal borrowed-contiguous type at this layer — the invariant-free
    ///   nominal was pruned per the orthogonality decision (keep-nominal is
    ///   reserved for Path/String).
    @frozen
    @safe
    public struct Contiguous<Element: BitwiseCopyable>: ~Copyable, @unsafe @unchecked Sendable {
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
