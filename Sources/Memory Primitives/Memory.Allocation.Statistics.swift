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

#if !hasFeature(Embedded)
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
public import Darwin_Memory_Primitives
import Darwin_Primitives
#elseif os(Linux)
public import Linux_Memory_Primitives
import Linux_Primitives
#elseif os(Windows)
public import Windows_Memory_Primitives
import Windows_Primitives
#endif
#endif

extension Memory.Allocation {
    /// Memory allocation statistics.
    ///
    /// Represents the allocation behavior of a code section, including
    /// the number of allocations, deallocations, and total bytes allocated.
    ///
    /// Example:
    /// ```swift
    /// let stats = Memory.Allocation.Statistics.capture()
    /// print("Allocations: \(stats.allocations)")
    /// print("Bytes: \(stats.bytes.allocated)")
    /// print("Net: \(stats.net.allocations)")
    /// ```
    public struct Statistics: Sendable, Equatable {
        /// Total number of allocations.
        public let allocations: Int

        /// Total number of deallocations.
        public let deallocations: Int

        /// Total bytes allocated (raw value).
        internal let _bytesAllocated: Int

        /// Initialize allocation statistics.
        ///
        /// - Parameters:
        ///   - allocations: Number of allocations.
        ///   - deallocations: Number of deallocations.
        ///   - bytesAllocated: Total bytes allocated.
        public init(allocations: Int = 0, deallocations: Int = 0, bytesAllocated: Int = 0) {
            self.allocations = allocations
            self.deallocations = deallocations
            self._bytesAllocated = bytesAllocated
        }
    }
}

// MARK: - Nested Accessors

extension Memory.Allocation.Statistics {
    /// Accessor for net (allocations - deallocations) values.
    public var net: Net { Net(self) }

    /// Accessor for byte-related values.
    public var bytes: Bytes { Bytes(self) }
}

extension Memory.Allocation.Statistics {
    /// Net allocation accessors.
    public struct Net: Sendable {
        private let stats: Memory.Allocation.Statistics

        internal init(_ stats: Memory.Allocation.Statistics) {
            self.stats = stats
        }

        /// Net allocations (allocations - deallocations).
        ///
        /// A positive value indicates potential memory leaks.
        public var allocations: Int {
            stats.allocations - stats.deallocations
        }

        /// Net bytes (bytes that haven't been freed).
        ///
        /// This is an approximation as we don't track individual allocation sizes on deallocation.
        public var bytes: Int {
            stats._bytesAllocated
        }
    }
}

extension Memory.Allocation.Statistics {
    /// Byte allocation accessors.
    public struct Bytes: Sendable {
        private let stats: Memory.Allocation.Statistics

        internal init(_ stats: Memory.Allocation.Statistics) {
            self.stats = stats
        }

        /// Total bytes allocated.
        public var allocated: Int {
            stats._bytesAllocated
        }
    }
}

// MARK: - Capture

extension Memory.Allocation.Statistics {
    /// Capture current allocation statistics.
    ///
    /// Platform-specific implementation that tracks memory allocations.
    /// Returns zero stats if allocation tracking is unavailable.
    ///
    /// - Returns: Current allocation statistics.
    public static func capture() -> Self {
        #if hasFeature(Embedded)
        return Self()
        #elseif os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        let stats = Darwin_Primitives.Darwin.Memory.Allocation.Statistics.capture()
        return Self(
            allocations: stats.allocations,
            deallocations: stats.deallocations,
            bytesAllocated: stats.bytesAllocated
        )
        #elseif os(Linux)
        let stats = Linux_Primitives.Linux.Memory.Allocation.Statistics.capture()
        return Self(
            allocations: stats.allocations,
            deallocations: stats.deallocations,
            bytesAllocated: stats.bytesAllocated
        )
        #elseif os(Windows)
        let stats = Windows_Primitives.Windows.Memory.Allocation.Statistics.capture()
        return Self(
            allocations: stats.allocations,
            deallocations: stats.deallocations,
            bytesAllocated: stats.bytesAllocated
        )
        #else
        return Self()
        #endif
    }
}

// MARK: - Delta

extension Memory.Allocation.Statistics {
    /// Calculate the delta between two allocation statistics.
    ///
    /// - Parameters:
    ///   - start: Starting statistics.
    ///   - end: Ending statistics.
    /// - Returns: The delta between the two statistics.
    public static func delta(
        from start: Self,
        to end: Self
    ) -> Self {
        Self(
            allocations: end.allocations - start.allocations,
            deallocations: end.deallocations - start.deallocations,
            bytesAllocated: end._bytesAllocated - start._bytesAllocated
        )
    }
}

// MARK: - Linux Tracking

#if !hasFeature(Embedded)
#if os(Linux)
extension Memory.Allocation.Statistics {
    /// Start tracking allocations on Linux.
    ///
    /// This enables the LD_PRELOAD malloc/free hooks.
    /// Must be called before measuring allocations.
    public static func startTracking() {
        Linux_Primitives.Linux.Memory.Allocation.Statistics.startTracking()
    }

    /// Stop tracking allocations and return final statistics.
    ///
    /// - Returns: Final allocation statistics since startTracking().
    public static func stopTracking() -> Statistics {
        let stats = Linux_Primitives.Linux.Memory.Allocation.Statistics.stopTracking()
        return Statistics(
            allocations: stats.allocations,
            deallocations: stats.deallocations,
            bytesAllocated: stats.bytesAllocated
        )
    }

    /// Reset tracking statistics to zero.
    ///
    /// Keeps tracking enabled but resets counters.
    public static func resetTracking() {
        Linux_Primitives.Linux.Memory.Allocation.Statistics.resetTracking()
    }
}
#endif
#endif

// MARK: - Tracking Setup

extension Memory.Allocation.Statistics {
    /// Ensure tracking is started on platforms that require it.
    ///
    /// Call this before capturing statistics. On Darwin, allocation tracking
    /// is always available via malloc_zone_statistics. On Linux, this starts
    /// the LD_PRELOAD-based tracking hooks. No-op in Embedded Swift.
    public static func ensureTracking() {
        #if !hasFeature(Embedded) && os(Linux)
        startTracking()
        #endif
    }
}
