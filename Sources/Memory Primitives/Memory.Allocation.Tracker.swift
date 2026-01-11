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

extension Memory.Allocation {
    /// Allocation tracker for measuring memory allocations.
    ///
    /// Provides convenient methods for tracking allocations around code blocks.
    ///
    /// Example:
    /// ```swift
    /// let (result, stats) = Memory.Allocation.Tracker.measure {
    ///     let array = Array(repeating: 0, count: 1000)
    ///     return array.count
    /// }
    /// print("Allocated \(stats.bytes.allocated) bytes")
    /// ```
    public enum Tracker {}
}

// MARK: - Measure

extension Memory.Allocation.Tracker {
    /// Measure allocations for a synchronous closure.
    ///
    /// - Parameter operation: The operation to measure.
    /// - Returns: Tuple of operation result and allocation statistics.
    /// - Throws: Rethrows any error from the operation.
    public static func measure<T>(
        _ operation: () throws -> T
    ) rethrows -> (result: T, stats: Memory.Allocation.Statistics) {
        Memory.Allocation.Statistics.ensureTracking()

        let start = Memory.Allocation.Statistics.capture()
        let result = try operation()
        let end = Memory.Allocation.Statistics.capture()

        let stats = Memory.Allocation.Statistics.delta(from: start, to: end)
        return (result, stats)
    }

    /// Measure allocations for an async closure.
    ///
    /// - Parameter operation: The async operation to measure.
    /// - Returns: Tuple of operation result and allocation statistics.
    /// - Throws: Rethrows any error from the operation.
    public static func measure<T>(
        _ operation: () async throws -> T
    ) async rethrows -> (result: T, stats: Memory.Allocation.Statistics) {
        Memory.Allocation.Statistics.ensureTracking()

        let start = Memory.Allocation.Statistics.capture()
        let result = try await operation()
        let end = Memory.Allocation.Statistics.capture()

        let stats = Memory.Allocation.Statistics.delta(from: start, to: end)
        return (result, stats)
    }
}

// MARK: - Measure (Void)

extension Memory.Allocation.Tracker {
    /// Measure allocations for a throwing closure, discarding the result.
    ///
    /// - Parameter operation: The operation to measure.
    /// - Returns: Allocation statistics for the operation.
    /// - Throws: Rethrows any error from the operation.
    public static func measure(
        _ operation: () throws -> Void
    ) rethrows -> Memory.Allocation.Statistics {
        Memory.Allocation.Statistics.ensureTracking()

        let start = Memory.Allocation.Statistics.capture()
        try operation()
        let end = Memory.Allocation.Statistics.capture()

        return Memory.Allocation.Statistics.delta(from: start, to: end)
    }

    /// Measure allocations for an async throwing closure, discarding the result.
    ///
    /// - Parameter operation: The async operation to measure.
    /// - Returns: Allocation statistics for the operation.
    /// - Throws: Rethrows any error from the operation.
    public static func measure(
        _ operation: () async throws -> Void
    ) async rethrows -> Memory.Allocation.Statistics {
        Memory.Allocation.Statistics.ensureTracking()

        let start = Memory.Allocation.Statistics.capture()
        try await operation()
        let end = Memory.Allocation.Statistics.capture()

        return Memory.Allocation.Statistics.delta(from: start, to: end)
    }
}
