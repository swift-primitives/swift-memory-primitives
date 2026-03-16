# Type-Safe Indexing in Low-Level Swift Collections: An Architectural Audit and Path Forward
<!--
---
version: 1.0.0
last_updated: 2026-01-22
status: RECOMMENDATION
---
-->

**A Technical Report on Index Type Integration in the Swift Institute Primitives Ecosystem**

---

## Abstract

This paper presents a comprehensive audit of index type safety across the Swift Institute's primitives layer, examining how the `swift-index-primitives` package's type-safe indexing abstractions integrate with collection and array primitives. We identify a fundamental architectural inconsistency: while `swift-index-primitives` provides a sophisticated phantom-typed index system with affine space semantics, `swift-collection-primitives` declares this dependency yet never uses it, defaulting to raw `Int` indexing throughout. In contrast, `swift-array-primitives` demonstrates partial successful integration but retains legacy `Int`-based APIs for protocol compliance. We propose a migration path to achieve complete type-safe indexing while maintaining Swift Collection protocol compatibility.

---

## 1. Introduction

### 1.1 The Problem of Integer Indexing

Raw integer indexing in collections presents several well-documented hazards:

1. **Cross-collection confusion**: Nothing prevents comparing indices from different collections
2. **Semantic ambiguity**: An `Int` parameter could represent a position, offset, count, or unrelated value
3. **Missing validation**: Negative positions are representable but invalid
4. **No affine semantics**: Point-vector distinctions collapse when both are `Int`

### 1.2 The Swift Institute's Solution

The `swift-index-primitives` package introduces a phantom-typed index system that addresses these concerns:

```swift
Index<Element>           // Unbounded position, phantom-typed by element
Index<Element>.Bounded<N> // Compile-time bounded [0, N)
Index<Element>.Count     // Non-negative count, distinct from position
Index<Element>.Offset    // Signed displacement (vector, not point)
```

This type system enforces affine space semantics where positions (points) and displacements (vectors) have distinct types, preventing nonsensical operations like adding two positions.

### 1.3 Scope of This Audit

We examine four packages:
- `swift-index-primitives` — The index type provider
- `swift-collection-primitives` — Generic collection protocols
- `swift-array-primitives` — Concrete array implementations
- `swift-sequence-primitives` — Linear iteration (control comparison)

---

## 2. The Index Primitives Type System

### 2.1 Core Types

The `swift-index-primitives` package provides four primary abstractions built on `Affine_Primitives`:

| Type | Purpose | Construction | Safety Mechanism |
|------|---------|--------------|------------------|
| `Index<T>` | Unbounded position | `Index(n)` throws if n < 0 | Phantom typing, validation |
| `Index<T>.Bounded<N>` | Fixed-range [0,N) | Throws if outside bounds | Compile-time capacity |
| `Index<T>.Count` | Non-negative count | Throws if negative | Distinct from position |
| `Index<T>.Offset` | Signed displacement | Unrestricted | Vector vs point distinction |

### 2.2 Affine Space Semantics

The package implements category-theoretic affine space operations:

```swift
// Point - Point → Vector
let offset: Index<T>.Offset = indexB - indexA

// Point + Vector → Point
let newPosition: Index<T>? = index + offset  // nil if negative

// Vector + Vector → Vector
let combined: Index<T>.Offset = offset1 + offset2
```

Critically, `Index + Index` is **unrepresentable**—the type system prevents this meaningless operation.

### 2.3 Safe Wrapper

For optional subscript access, `Safe<Collection>` provides:

```swift
collection.safe[index]      // Returns Element?
collection.safe[range]      // Returns SubSequence?
```

---

## 3. Audit Findings: swift-collection-primitives

### 3.1 Critical Finding: Declared but Unused Dependency

**Location**: `/Users/coen/Developer/swift-primitives/swift-collection-primitives/`

The package declares `swift-index-primitives` as a dependency and re-exports it:

```swift
// Package.swift
.package(path: "../swift-index-primitives"),

// exports.swift
@_exported import Index_Primitives
```

However, **no source file actually uses any Index type**. The entire Index_Primitives module is imported then ignored.

### 3.2 Raw Int Throughout

Every protocol and implementation defaults to raw `Int`:

**Collection.Protocol (line 16)**:
```swift
// Documentation example
typealias Index = Int
subscript(position: Int) -> Element { storage[position] }
```

**Collection.Rotated (lines 49-70)** — the only concrete type:
```swift
public var startIndex: Int { 0 }
public var endIndex: Int { base.count }

public subscript(position: Int) -> Base.Element {
    let actualIndex = (startOffset + position) % base.count  // Raw arithmetic
    return base[base.index(base.startIndex, offsetBy: actualIndex)]
}

public func index(after i: Int) -> Int { i + 1 }      // Unchecked
public func index(before i: Int) -> Int { i - 1 }     // Can go negative
public func index(_ i: Int, offsetBy distance: Int) -> Int {
    i + distance  // No bounds validation whatsoever
}
```

### 3.3 Missing Bounds Checking

`Collection.Rotated` performs no bounds validation:

| Method | Issue |
|--------|-------|
| `index(after:)` | No check that result < endIndex |
| `index(before:)` | No check that result >= 0 |
| `index(_:offsetBy:)` | Can produce any `Int`, positive or negative |
| `subscript` | Relies on modulo to "fix" out-of-bounds access |

### 3.4 Violations Summary

| Violation | Severity | Impact |
|-----------|----------|--------|
| Index_Primitives imported but unused | Critical | Type safety not enforced |
| Protocol examples use `Int` | High | Encourages unsafe patterns |
| Collection.Rotated hardcodes `Int` | Critical | No phantom typing |
| No bounds checking | Critical | Runtime crashes or silent wrapping |
| Unchecked arithmetic | High | Integer overflow possible |

---

## 4. Audit Findings: swift-array-primitives

### 4.1 Partial Success: Dual API Surface

**Location**: `/Users/coen/Developer/swift-primitives/swift-array-primitives/`

The array primitives package demonstrates a bifurcated approach:

**A. Collection Protocol Compliance (Raw Int)**:
```swift
// Array.Bounded+Collection.Indexed.swift
typealias Index = Int
public var startIndex: Int { 0 }
public subscript(index: Int) -> Element { ... }
```

**B. Type-Safe API (Index<Element>)**:
```swift
// Array.Index.swift
public typealias Index = Index_Primitives.Index<Element>
public typealias Offset = Index_Primitives.Index<Element>.Offset

public subscript(index: Array<Element>.Index) -> Element {
    precondition(index.position.rawValue >= 0 &&
                 index.position.rawValue < count)
    return _storage[index.position.rawValue]
}
```

### 4.2 Indexed Wrappers

Phantom-typed wrappers provide domain-specific index safety:

```swift
// Array.Bounded.Indexed<Tag>
public subscript(index: Index_Primitives.Index<Tag>) -> Element {
    get { _storage[index.position.rawValue] }
}

public var count: Index_Primitives.Index<Tag>.Count {
    Index_Primitives.Index<Tag>.Count(__unchecked: _storage.count)
}
```

This allows:
```swift
let userIndices: Array<User>.Bounded<100>.Indexed<UserList>
let productIndices: Array<Product>.Bounded<100>.Indexed<ProductCatalog>
// userIndices[productIndex] → Compile error: Type mismatch
```

### 4.3 Bounded Index Support

```swift
public typealias BoundedIndex = Index_Primitives.Index<Element>.Bounded<capacity>

public subscript(index: BoundedIndex) -> Element {
    // Only needs to check index.rawValue < _count
    // Capacity bound already proven at compile time
}
```

### 4.4 Remaining Int Usage

| Category | Count | Can Be Eliminated? |
|----------|-------|-------------------|
| Collection protocol subscripts | 8 | No (protocol requirement) |
| Internal loops (`for i in 0..<count`) | 12 | Yes, with performance consideration |
| Bit array arithmetic | 8 | Yes, via Index.Offset |
| `element(at: Int)` methods | 7 | Yes, deprecated in favor of typed |

### 4.5 Assessment

Array primitives achieves **~70% type-safe indexing** with clear separation between:
- Protocol-required `Int` APIs (immutable, required for stdlib compatibility)
- Type-safe `Index<Element>` APIs (preferred for new code)
- Phantom-typed `Indexed<Tag>` wrappers (maximum safety)

---

## 5. Audit Findings: swift-sequence-primitives

### 5.1 Correctly Out of Scope

**Location**: `/Users/coen/Developer/swift-primitives/swift-sequence-primitives/`

Sequences support only linear iteration, not random access. The package correctly uses iterator-based patterns exclusively:

```swift
public func forEach(_ body: (borrowing Element) -> Void) {
    var iterator = unsafe base.pointee.makeIterator()
    while let element = iterator.next() {
        body(element)
    }
}
```

No position tracking required; no Index types needed.

### 5.2 Unused Dependency

The package declares `swift-index-primitives` as a dependency but never imports it. This should be removed as unnecessary technical debt.

---

## 6. Architectural Analysis

### 6.1 The Integration Gap

```
┌─────────────────────────────────────────────────────────────────┐
│                    swift-index-primitives                       │
│  Index<T>, Index<T>.Bounded<N>, Index<T>.Offset, Index<T>.Count │
└─────────────────────────────────────────────────────────────────┘
                              │
                    @_exported import
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                 swift-collection-primitives                     │
│                                                                 │
│    ❌ NEVER USED — All protocols and types use raw Int          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                         depends on
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   swift-array-primitives                        │
│                                                                 │
│    ✅ PARTIALLY INTEGRATED:                                     │
│    - Array<T>.Index subscripts                                  │
│    - Indexed<Tag> phantom wrappers                              │
│    - Bounded<N> compile-time indices                            │
│                                                                 │
│    ❌ LEGACY INT APIS:                                          │
│    - Collection protocol conformance                            │
│    - Internal loops                                             │
│    - Bit array arithmetic                                       │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 Root Cause Analysis

The disconnect stems from **protocol design at the collection layer**:

```swift
// Collection.Protocol requires only Comparable
associatedtype Index: Comparable

// Documentation then shows Int
typealias Index = Int  // This sets the expectation
```

By making `Index` a generic associated type constrained only to `Comparable`, the protocol permits any type—but all examples demonstrate `Int`, normalizing unsafe patterns.

### 6.3 The stdlib Compatibility Constraint

Swift's standard library `Collection` protocol uses `Int` for `startIndex` and `endIndex` on `Array`. The `Collection.Indexed` and `Collection.Protocol` abstractions must maintain compatibility for bridging to stdlib, creating an inherent tension.

---

## 7. Proposed Migration Strategy

### 7.1 Phase 1: Collection Primitives Refactoring

**Objective**: Make `Collection.Rotated` use typed indices while maintaining protocol compatibility.

```swift
// Current (unsafe)
public var startIndex: Int { 0 }

// Proposed
public typealias Index = Index_Primitives.Index<Base.Element>

public var startIndex: Index {
    try! Index(0)  // Safe: 0 is never negative
}

public func index(after i: Index) -> Index {
    guard let next = i + Index.Offset(1) else {
        preconditionFailure("Index after endIndex")
    }
    return next
}
```

**For protocol compliance**, add a `rawIndex` view:

```swift
extension Collection.Rotated {
    public var rawStartIndex: Int { startIndex.position.rawValue }

    public subscript(rawPosition position: Int) -> Base.Element {
        self[try! Index(position)]
    }
}
```

### 7.2 Phase 2: Protocol Documentation Update

Change all protocol examples from:
```swift
typealias Index = Int
```

To:
```swift
typealias Index = Index_Primitives.Index<Element>
```

Add explicit guidance:
> Raw `Int` indices SHOULD only be used for stdlib `Collection` protocol conformance. New APIs MUST use phantom-typed `Index<Element>` for domain safety.

### 7.3 Phase 3: Array Primitives Cleanup

**7.3.1 Deprecate Raw Int APIs**:
```swift
@available(*, deprecated, message: "Use subscript(index: Array<Element>.Index) instead")
public subscript(index: Int) -> Element { ... }
```

**7.3.2 Convert Internal Loops**:
```swift
// Current
for i in 0..<count {
    destroy(&_storage[i])
}

// Proposed
var index = try! Array<Element>.Index(0)
let end = try! Array<Element>.Index(count)
while index < end {
    destroy(&_storage[index.position.rawValue])
    index = (index + Index.Offset(1))!
}
```

**Note**: Performance impact must be measured. For tight loops, the optimizer may or may not eliminate the indirection.

**7.3.3 Bit Array Offset Migration**:
```swift
// Current
Bit.Index(__unchecked: (), position: i.position.rawValue + 1)

// Proposed (if Index provides arithmetic)
(i + Bit.Index.Offset(1))!
```

### 7.4 Phase 4: Sequence Primitives Cleanup

Remove the unused `swift-index-primitives` dependency from `Package.swift`:

```swift
dependencies: [
    .package(path: "../swift-property-primitives"),
    // .package(path: "../swift-index-primitives"),  // Removed
],
```

---

## 8. Bounded Index Opportunities

### 8.1 Compile-Time Capacity Elimination

`Index<T>.Bounded<N>` enables compile-time bounds checking:

```swift
public struct Array<Element>.Bounded<let capacity: Int> {
    public typealias BoundedIndex = Index_Primitives.Index<Element>.Bounded<capacity>

    public subscript(index: BoundedIndex) -> Element {
        // Capacity check eliminated at compile time
        // Only runtime check: index.rawValue < currentCount
        precondition(index.rawValue < _count)
        return _storage[index.rawValue]
    }
}
```

### 8.2 Iterator Optimization

For random access iteration over bounded arrays:

```swift
public struct Iterator: IteratorProtocol {
    var index: Index_Primitives.Index<Element>.Bounded<capacity>?

    mutating func next() -> Element? {
        guard let i = index else { return nil }
        let element = array[i]
        index = i.successor()  // Returns nil at capacity
        return element
    }
}
```

The `successor()` method handles bounds automatically, eliminating manual comparison.

---

## 9. Affine Arithmetic Integration

### 9.1 Current State

Bit array arithmetic manually extracts raw values:

```swift
// Array.Bit.Packed.swift:501
func index(after i: Index) -> Index {
    Bit.Index(__unchecked: (), position: i.position.rawValue + 1)
}
```

### 9.2 Proposed Improvement

If `Index_Primitives` exposes offset operators (which it does via `+` and `-`):

```swift
func index(after i: Index) -> Index {
    (i + Bit.Index.Offset(1))!  // Uses affine arithmetic
}

func distance(from start: Index, to end: Index) -> Bit.Index.Offset {
    end - start  // Proper vector result
}
```

### 9.3 Benefits

1. **Type safety**: Cannot accidentally add two indices
2. **Documentation**: Code expresses intent (point + vector, not int + int)
3. **Validation**: Arithmetic can return `nil` for invalid results

---

## 10. Count Type Integration

### 10.1 Current Implementation

`Indexed` wrappers properly use phantom-typed counts:

```swift
// Array.Bounded.Indexed.swift:65
public var count: Index_Primitives.Index<Tag>.Count {
    Index_Primitives.Index<Tag>.Count(__unchecked: _storage.count)
}
```

### 10.2 Bounds Checking Pattern

```swift
// Index can be compared to Count for bounds checking
if index < count {
    // Safe to access
}
```

This prevents comparing indices to unrelated integers.

### 10.3 Missing: Collection Primitives Integration

`Collection.Rotated` should return typed counts:

```swift
// Current
public var endIndex: Int { base.count }

// Proposed
public var count: Index<Base.Element>.Count {
    Index<Base.Element>.Count(__unchecked: base.count)
}
```

---

## 11. Safe Wrapper Adoption

### 11.1 Available in Index Primitives

```swift
extension Collection {
    public var safe: Safe<Self> { Safe(self) }
}

// Usage
array.safe[index]  // Returns Element?
```

### 11.2 Integration Opportunity

Array primitives could leverage this for optional access:

```swift
extension Array.Bounded {
    public func element(at index: Index) -> Element? {
        _storage.safe[index.position.rawValue]
    }
}
```

Currently, `element(at:)` uses guard + throw. The `Safe` wrapper provides a more ergonomic alternative for optional-returning APIs.

---

## 12. Conclusions

### 12.1 Summary of Findings

| Package | Index Integration | Status |
|---------|-------------------|--------|
| swift-index-primitives | N/A (provider) | Complete, well-designed |
| swift-collection-primitives | 0% | Critical architectural failure |
| swift-array-primitives | ~70% | Good, with legacy Int for protocols |
| swift-sequence-primitives | N/A (not applicable) | Correct by design |

### 12.2 Critical Actions

1. **Immediate**: Refactor `Collection.Rotated` to use `Index<Element>` internally
2. **Short-term**: Update all protocol documentation examples
3. **Medium-term**: Deprecate raw `Int` subscripts in array primitives
4. **Long-term**: Measure and optimize Index arithmetic in tight loops

### 12.3 Design Principle

> **All position-based access in primitives MUST use `Index<Element>` or its bounded/tagged variants. Raw `Int` is permitted ONLY for Swift stdlib protocol conformance surfaces.**

### 12.4 Final Assessment

The `swift-index-primitives` package provides a sophisticated, well-designed type system for safe indexing. Its integration with `swift-array-primitives` demonstrates the pattern's viability. However, `swift-collection-primitives`—the foundational layer—completely ignores this system, creating a fundamental architectural inconsistency that undermines the entire type safety story.

Resolving this requires treating `swift-collection-primitives` as the critical path: its protocols set expectations for all downstream code. Until these protocols demonstrate and encourage `Index<Element>` usage, the ecosystem cannot achieve the "timeless infrastructure" quality standard the Swift Institute requires.

---

## Appendix A: File Inventory

### swift-index-primitives
```
Sources/Index Primitives/
├── Index.swift                    # Core Index<T> type, Error, Offset, Count
├── Index+Arithmetic.swift         # Affine operations
├── Index.Bounded.swift            # Bounded<N> type
├── Index.Bounded+Arithmetic.swift # Bounded arithmetic (commented out)
├── Index.Count.swift              # Count type, Index/Count comparisons
├── Index.Safe.swift               # Safe<Collection> wrapper
├── Index.Safe+subscript.swift     # Safe subscript implementations
├── Index.Safe+Collection.swift    # .safe property extension
└── exports.swift                  # Re-exports Affine, Identity primitives
```

### swift-collection-primitives (violations)
```
Sources/Collection Primitives/
├── Collection.Protocol.swift      # Uses Int examples
├── Collection.Indexed.swift       # Uses Int examples
├── Collection.Bidirectional.swift # Uses Int examples
├── Collection.Rotated.swift       # HARDCODES Int throughout
├── Collection.Count+Property.View.swift  # Returns raw Int
└── exports.swift                  # Exports Index_Primitives but never uses
```

### swift-array-primitives (partial integration)
```
Sources/Array Primitives Core/
├── Array.Index.swift              # ✅ Index<Element> subscripts
├── Array.Bounded.Indexed.swift    # ✅ Phantom-typed wrapper
├── Array.Inline.Indexed.swift     # ✅ Phantom-typed wrapper
├── Array.Small.Indexed.swift      # ✅ Phantom-typed wrapper
├── Array.Unbounded.Indexed.swift  # ✅ Phantom-typed wrapper
├── Array.Bounded.swift            # ❌ Has Int subscript (Collection)
├── Array.Unbounded.swift          # ❌ Has Int subscript (Collection)
├── Array.Inline.swift             # ❌ Has Int subscript (Collection)
├── Array.Small.swift              # ❌ Has Int subscript (Collection)
└── Array.Bit.Packed.swift         # ⚠️ Manual rawValue arithmetic
```

---

## Appendix B: Recommended Code Changes

### B.1 Collection.Rotated Migration

```swift
// BEFORE
public struct Rotated<Base: Collection.Bidirectional> {
    public var startIndex: Int { 0 }
    public var endIndex: Int { base.count }

    public subscript(position: Int) -> Base.Element {
        let actualIndex = (startOffset + position) % base.count
        return base[base.index(base.startIndex, offsetBy: actualIndex)]
    }
}

// AFTER
public struct Rotated<Base: Collection.Bidirectional> {
    public typealias Index = Index_Primitives.Index<Base.Element>

    public var startIndex: Index {
        try! Index(0)
    }

    public var endIndex: Index {
        try! Index(base.count)
    }

    public subscript(position: Index) -> Base.Element {
        let offset = position.position.rawValue
        let actualOffset = (startOffset + offset) % base.count
        return base[base.index(base.startIndex, offsetBy: actualOffset)]
    }

    public func index(after i: Index) -> Index {
        guard let next = i + Index.Offset(1),
              next <= endIndex else {
            preconditionFailure("Cannot advance past endIndex")
        }
        return next
    }
}
```

### B.2 Protocol Example Update

```swift
// BEFORE (Collection.Protocol.swift documentation)
/// struct MyCollection: Collection.Protocol {
///     typealias Index = Int
///     var startIndex: Int { 0 }

// AFTER
/// struct MyCollection<Element>: Collection.Protocol {
///     typealias Index = Index_Primitives.Index<Element>
///     var startIndex: Index { try! Index(0) }
```

---

*Document Version: 1.0*
*Audit Date: 2026-01-22*
*Packages Audited: swift-index-primitives, swift-collection-primitives, swift-array-primitives, swift-sequence-primitives*
*Location: /Users/coen/Developer/swift-primitives/*
