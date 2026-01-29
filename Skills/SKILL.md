---
name: memory-primitives
description: |
  Memory address, allocation, and arena primitives.
  ALWAYS apply when working in the swift-memory-primitives package.

layer: implementation

requires:
  - primitives
  - memory

applies_to:
  - swift
  - swift-primitives
  - swift-memory-primitives
---

# Memory Primitives

Type-safe memory addressing, allocation, and arena management for Swift Institute.

---

## Module Structure

| Module | Purpose |
|--------|---------|
| Memory Primitives Core | `Memory.Address`, `Memory.Contiguous`, base types |
| Memory Primitives | `Memory.Address.Mutable`, `Memory.Address.Buffer`, `Memory.Allocator`, `Memory.Arena` |
| Memory Primitives Standard Library Integration | Extensions on stdlib pointer types |

---

## Core Design Decisions

### [MEMP-001] Address as Position

**Statement**: `Memory.Address` represents a position in memory space, not a capability.

An address is an ordinal — a pure location. Mutability and access permissions live at the pointer level (`UnsafeMutableRawPointer`), not the address level.

```swift
// Address is positional
let addr: Memory.Address = .allocate(count: n, alignment: a)

// Capability lives in the pointer
addr.mutableRawPointer.store.bytes(of: value, as: T.self)
```

See Research: `Research/memory-address-mutability.md`

### [MEMP-002] Three-Module Split

**Statement**: Memory primitives MUST separate core types, mutable/allocator types, and stdlib integration into distinct modules.

- **Core**: Foundation-free address and contiguous memory abstractions
- **Primitives**: Mutable addresses, allocators, arenas (depends on Core)
- **Standard Library Integration**: Extensions bridging to `UnsafeRawPointer`, `UnsafeMutableRawPointer`, etc.

### [MEMP-003] Allocator Protocol

**Statement**: All allocation strategies MUST conform to `Memory.Allocator.Protocol`.

```swift
public protocol Protocol: ~Copyable {
    mutating func allocate(
        byteCount: Int,
        alignment: Int
    ) throws(Memory.Address.Error) -> Memory.Address

    mutating func deallocate(_ address: Memory.Address)
}
```

### [MEMP-004] Arena Scoped Allocation

**Statement**: `Memory.Arena` provides scoped bulk allocation with single deallocation.

Arenas allocate from a contiguous region and deallocate all allocations at once when the arena is destroyed. Individual deallocation is not supported.

---

## Type Hierarchy

```
Memory
├── .Address              // Position in memory (Core)
│   ├── .Mutable          // Position with mutable pointer access
│   ├── .Buffer           // Contiguous immutable region
│   │   └── .Mutable      // Contiguous mutable region
│   └── .Error            // Address operation errors (Core)
├── .Contiguous           // Contiguous memory abstraction (Core)
│   └── .Protocol         // Contiguous conformance (Core)
├── .Allocator            // Default allocator
│   └── .Protocol         // Allocator conformance
└── .Arena                // Scoped bulk allocator
    └── .Error            // Arena errors
```

---

## Stdlib Integration

| Extension Target | Operations |
|-----------------|------------|
| `UnsafeRawPointer` | Memory-safe read access |
| `UnsafeMutableRawPointer` | `.memory.*` (move semantics), `.store.*` (byte storage) |
| `UnsafeRawBufferPointer` | Buffer-level read access |
| `UnsafeMutableRawBufferPointer` | `.store.*` (buffer storage) |

---

## Cross-References

| Topic | Skill |
|-------|-------|
| Memory ownership rules | **memory** |
| Pointer wrappers | **pointer-primitives** |
| Naming conventions | **naming** |

Full design analysis: `Research/memory-address-mutability.md`
