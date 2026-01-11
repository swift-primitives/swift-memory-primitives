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

extension Memory.Allocation.Histogram {
    /// A histogram bucket.
    public struct Bucket: Sendable {
        /// Lower bound of the bucket (inclusive).
        internal let _lower: Int

        /// Upper bound of the bucket (exclusive).
        internal let _upper: Int

        /// Number of values in this bucket.
        public let count: Int

        /// Frequency as a percentage (0-100).
        public let frequency: Double

        public init(lower: Int, upper: Int, count: Int, frequency: Double) {
            self._lower = lower
            self._upper = upper
            self.count = count
            self.frequency = frequency
        }
    }
}

// MARK: - Bounds Accessor

extension Memory.Allocation.Histogram.Bucket {
    /// Accessor for bucket bounds.
    public var bounds: Bounds { Bounds(self) }
}

extension Memory.Allocation.Histogram.Bucket {
    /// Bucket bounds accessor.
    public struct Bounds: Sendable {
        private let bucket: Memory.Allocation.Histogram.Bucket

        internal init(_ bucket: Memory.Allocation.Histogram.Bucket) {
            self.bucket = bucket
        }

        /// Lower bound of the bucket (inclusive).
        public var lower: Int {
            bucket._lower
        }

        /// Upper bound of the bucket (exclusive).
        public var upper: Int {
            bucket._upper
        }
    }
}
