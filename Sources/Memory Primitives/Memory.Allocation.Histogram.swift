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
    /// Allocation histogram.
    public struct Histogram: Sendable {
        /// Histogram buckets.
        public let buckets: [Bucket]
    }
}

// MARK: - Initialization

extension Memory.Allocation.Histogram {
    public init(values: [Int], buckets bucketCount: Int) {
        guard !values.isEmpty, bucketCount > 0 else {
            self.buckets = []
            return
        }

        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        let range = maxValue - minValue
        let bucketSize = Swift.max(1, range / bucketCount)

        var buckets: [Bucket] = []
        let total = Double(values.count)

        for i in 0..<bucketCount {
            let lower = minValue + (i * bucketSize)
            let upper = (i == bucketCount - 1) ? maxValue + 1 : minValue + ((i + 1) * bucketSize)

            let count = values.filter { $0 >= lower && $0 < upper }.count
            let frequency = (Double(count) / total) * 100.0

            buckets.append(
                Bucket(
                    lower: lower,
                    upper: upper,
                    count: count,
                    frequency: frequency
                )
            )
        }

        self.buckets = buckets
    }
}
