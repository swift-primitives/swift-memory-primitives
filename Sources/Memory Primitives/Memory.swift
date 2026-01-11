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

/// Namespace for userspace memory utilities.
///
/// Memory provides allocation introspection, profiling, and tracking utilities.
/// These are userspace operations that observe or instrument the allocator,
/// NOT kernel syscalls for memory management.
///
/// For kernel memory operations (mmap, mlock, shm), see `Kernel.Memory` in
/// swift-kernel-primitives.
///
/// ## Overview
///
/// - ``Memory/Allocation``: Allocation tracking and statistics
///   - ``Memory/Allocation/Statistics``: Query allocator statistics
///   - ``Memory/Allocation/Tracker``: Track allocations during execution
///   - ``Memory/Allocation/LeakDetector``: Detect memory leaks
///   - ``Memory/Allocation/PeakTracker``: Track peak memory usage
///   - ``Memory/Allocation/Profiler``: Profile allocation patterns
public enum Memory {}
