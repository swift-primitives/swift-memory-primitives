# Memory Primitives Insights

<!--
---
title: Memory Primitives Insights
version: 1.0.0
last_updated: 2026-01-28
applies_to: [swift-memory-primitives]
normative: false
---
-->

@Metadata {
    @TitleHeading("Memory Primitives")
}

Design decisions, implementation patterns, and lessons learned specific to this package.

## Overview

This document captures insights that emerged during development of swift-memory-primitives. These are not API requirements—they are recorded decisions and patterns that inform future work on this package.

**Document type**: Non-normative (recorded decisions, not requirements).

**Consolidation source**: Reflection entries tagged with `[Package: swift-memory-primitives]`.

---

## The Provenance-Correct Sentinel

**Date**: 2026-01-27

**Context**: Reviewing the empty buffer sentinel implementation in Memory.Address.Buffer.

The original implementation used `UnsafeRawPointer(bitPattern: 0x1000)!` to create a sentinel for empty buffers. This is a manufactured pointer—an address conjured from an integer literal with no memory provenance. While 0x1000 is "probably unmapped" on most systems, this relies on platform-specific assumptions rather than language guarantees.

Under Swift 6.2+ strict memory safety trajectory, provenance matters. A pointer created from `bitPattern:` has no valid provenance chain for lifetime/escape analysis. The fix: allocate a real sentinel once at startup, page-aligned (4096 bytes) to preserve the prior invariant, and never deallocate it. This creates both a mutable and immutable sentinel from the same allocation, giving both legitimate provenance.

Sentinels that "will never be dereferenced" still need valid provenance if the type system might analyze them. The cost of a single 1-byte allocation at startup is negligible; the correctness guarantee is permanent. When faced with "this unsafe thing probably works," prefer the version that definitely works.

**Applies to**: `Memory.Address.Buffer` sentinel values, any future sentinel patterns.

---

## The Arena Semantic Fix

**Date**: 2026-01-27

**Context**: Fixing Memory.Arena to use Count instead of Offset for allocated bytes.

Arena stored `_offset: Index<UInt8>.Offset` to track bytes allocated. But "bytes allocated" is a count (how many), not an offset (displacement). This type mismatch forced raw value extraction everywhere the field was used.

The fix: change to `_allocated: Index<UInt8>.Count`. This is semantically correct—we're tracking a quantity, not a displacement. The property `remaining` becomes `capacity - allocated`, both Count types, using the policy-aware subtraction from Cardinal Primitives.

Once the field has the correct semantic type, the methods that use it no longer need raw value extraction. The typed operations handle the arithmetic. Correct semantic types at the storage level eliminate extraction cascades throughout the API.

**Applies to**: `Memory.Arena._allocated`, `Memory.Arena.remaining`, bump allocator patterns.

---

## Topics

### Related Documents

- <doc:Memory-Address>
- <doc:Memory-Arena>
