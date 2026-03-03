# Memory.Inline Package Placement

<!--
---
version: 1.0.0
last_updated: 2026-02-27
status: DECISION
---
-->

## Context

**Trigger**: Implementing `Memory.Inline<Element, capacity>` in memory-primitives. Vector-primitives' iterators need `Memory.Inline` for zero-allocation `nextSpan` span buffers. But memory-primitives depends on vector-primitives at the package level, so vector-primitives cannot import from memory-primitives without creating an SPM cycle.

**Constraint**: SPM rejects dependency cycles at the **package** level, not the target level. Even if vector-primitives only imports a zero-dependency target from memory-primitives, SPM still sees the bidirectional package reference and rejects it.

## Question

How should Memory.Inline be made available to vector-primitives without creating a package-level cycle or a new package?

## Analysis

### Why memory-primitives depends on vector-primitives (root cause)

| Location | Usage | Essential? |
|----------|-------|-----------|
| `Core/exports.swift:12` | `@_exported public import Vector_Primitives` | **No** — convenience re-export only |
| `Memory Primitives/Memory.Buffer.swift:167` | `extracting(_ bounds: Vector<Index<Memory>>)` | **No** — convenience overload |
| `Memory Primitives/Memory.Buffer.Mutable.swift:251` | `extracting(_ bounds: Vector<Index<Memory>>)` | **No** — convenience overload |
| `Tests/Support/exports.swift:16` | `@_exported public import Vector_Primitives_Test_Support` | **No** — convenience re-export |

No code in memory-primitives *requires* Vector. The dependency exists for 2 convenience overloads and re-export convenience.

### Option A: Invert the dependency direction

Remove vector-primitives from memory-primitives entirely. Move the 2 `extracting(_ bounds: Vector<...>)` overloads to vector-primitives as extensions on `Memory.Buffer` and `Memory.Buffer.Mutable`. Vector-primitives then depends on memory-primitives.

**Result**: Memory is below Vector in the tier graph (correct — raw memory is more fundamental than functional vectors). Vector can import `Memory.Inline` directly.

| Criterion | Assessment |
|-----------|------------|
| Domain correctness | **Correct** — memory is more fundamental than vector |
| Cycle | **None** — unidirectional: vector → memory |
| New packages | **None** |
| Breaking change | The 2 `extracting` overloads move. Consumers importing both packages are unaffected. |
| Duplication | **None** — single `Memory.Inline` definition reused everywhere |

### Option B: Create a new Tier 0 package

Extract `Memory.Inline` into `swift-memory-inline-primitives` with zero dependencies. Both memory-primitives and vector-primitives depend on it.

| Criterion | Assessment |
|-----------|------------|
| Domain correctness | Partial — fragments the Memory namespace |
| Cycle | None |
| New packages | **1 new package** |
| Breaking change | None |
| Duplication | None |

### Option C: Duplicate `@_rawLayout` in vector-primitives

Vector iterators implement their own local `@_rawLayout` buffer. No shared type.

| Criterion | Assessment |
|-----------|------------|
| Domain correctness | Poor — same abstraction in two places |
| Cycle | None |
| New packages | None |
| Breaking change | None |
| Duplication | **Yes** — violates DRY |

## Comparison

| | Domain correct | No cycle | No new packages | No duplication | No breaking change |
|---|---|---|---|---|---|
| **A: Invert** | Yes | Yes | Yes | Yes | Minor (2 methods move) |
| B: New package | Partial | Yes | No | Yes | Yes |
| C: Duplicate | No | Yes | Yes | No | Yes |

## Outcome

**Status**: DECISION

**Option A: Invert the dependency direction.**

Memory is more fundamental than Vector. The current dependency (memory → vector) is architecturally backwards. The fix:

1. Remove `swift-vector-primitives` from memory-primitives' package dependencies
2. Remove `Vector_Primitives` re-export from `Core/exports.swift`
3. Move `Memory.Buffer.extracting(_ bounds: Vector<...>)` and `Memory.Buffer.Mutable.extracting(_ bounds: Vector<...>)` to vector-primitives as extensions
4. Remove `Vector_Primitives_Test_Support` re-export from test support
5. Vector-primitives adds `swift-memory-primitives` as a package dependency
6. Vector iterators use `Memory.Inline<Bound, 1>` for span buffers

This corrects the tier ordering and enables all packages at or above Vector's tier to use `Memory.Inline`.

## References

- `swift-storage-primitives/Research/inline-storage-layering.md` — Recommends Option A (Memory.Inline in memory-primitives)
- `swift-sequence-primitives/Research/zero-allocation-nextspan-for-generating-iterators.md` — Context for iterator span buffer needs
