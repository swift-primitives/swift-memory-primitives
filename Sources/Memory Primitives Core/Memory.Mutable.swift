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
    /// Marker type for mutable memory addresses.
    ///
    /// Used as a phantom tag to distinguish `Memory.Mutable.Address` from
    /// `Memory.Address`. Both are ordinal positions in memory, but the type
    /// system tracks whether operations are permitted to mutate.
    public enum Mutable {}
}
