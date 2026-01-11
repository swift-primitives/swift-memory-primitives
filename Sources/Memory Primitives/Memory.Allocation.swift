// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-memory-primitives open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-memory-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

extension Memory {
    /// Namespace for allocation tracking and introspection utilities.
    ///
    /// These are userspace utilities for observing and measuring memory allocator
    /// behavior. They use platform-specific APIs (libmalloc on Darwin, LD_PRELOAD
    /// hooks on Linux) to track allocations without kernel involvement.
    ///
    /// For kernel memory operations (mmap, mlock), see `Kernel.Memory` in
    /// swift-kernel-primitives.
    public enum Allocation {}
}
