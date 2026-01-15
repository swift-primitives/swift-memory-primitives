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
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

#if os(Linux)
import CAllocationTracking
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
        return captureDarwin()
        #elseif os(Linux)
        return captureLinux()
        #else
        return Self()
        #endif
    }

    #if !hasFeature(Embedded)
    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
    private static func captureDarwin() -> Self {
        var stats = malloc_statistics_t()
        unsafe malloc_zone_statistics(nil, &stats)

        return Self(
            allocations: Int(stats.blocks_in_use),
            deallocations: 0,
            bytesAllocated: Int(stats.size_in_use)
        )
    }
    #endif

    #if os(Linux)
    private static func captureLinux() -> Self {
        let stats = tracking_current()
        return Self(
            allocations: Int(stats.allocations),
            deallocations: Int(stats.deallocations),
            bytesAllocated: Int(stats.bytes_allocated)
        )
    }
    #endif
    #endif
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
        tracking_start()
    }

    /// Stop tracking allocations and return final statistics.
    ///
    /// - Returns: Final allocation statistics since startTracking().
    public static func stopTracking() -> Statistics {
        let stats = tracking_stop()
        return Statistics(
            allocations: Int(stats.allocations),
            deallocations: Int(stats.deallocations),
            bytesAllocated: Int(stats.bytes_allocated)
        )
    }

    /// Reset tracking statistics to zero.
    ///
    /// Keeps tracking enabled but resets counters.
    public static func resetTracking() {
        tracking_reset()
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
