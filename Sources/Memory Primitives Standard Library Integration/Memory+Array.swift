// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Span_Protocol_Primitives

// `@retroactive`: both `Swift.Array` (stdlib) and `Span.\`Protocol\``
// (swift-span-primitives) are foreign to this package — the conformance is
// genuinely cross-package per [API-IMPL-018]. (The former conformance target
// `Memory.Contiguous.\`Protocol\`` was a same-package typealias, hence needed
// no attribute.)
extension Swift.Array: @retroactive Span.`Protocol` {}
