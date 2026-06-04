# Memory Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Non-null memory address wrappers with typed index integration for Swift.

## Scope

`swift-memory-primitives` provides the substrate for **addressable, aligned, allocatable storage with typed layout and mutation operations**. Memory is the *location* domain — orthogonal to the byte/bit *representation* domains; the byte couplings (`Byte` as the stored unit, byte-counted addressing) are bridges to `swift-byte-primitives`, not memory's identity.

### Core targets (in scope)

- **Memory Address** — where things live
- **Memory Alignment** — how they're laid out
- **Memory Allocation** — creating regions
- **Memory Contiguous** — typed layout interface
- **Memory Inline** — in-line representation
- **Memory Shift** — alignment exponent (`alignment = 2^shift`; a typed bit-shift count, not a mutation operation)

### Out of scope

The following capabilities compose memory primitives but live as sibling packages, not in this one:

| Capability | Sibling package |
|---|---|
| Allocation strategies — fixed-pool, bump-arena | `swift-memory-pool-primitives`, `swift-memory-arena-primitives` |
| Typed memory-bounded views with iteration semantics | `swift-memory-buffer-primitives` |
| Synchronization primitives | `swift-memory-lock-primitives` |
| Cross-process shared memory (IPC) | `swift-memory-shared-primitives` |
| OS memory mapping (mmap) | `swift-memory-map-primitives` (eventual L2 relocation candidate) |

### Evaluation rule

Sub-target additions are evaluated against this scope. If a proposed addition is OUT of scope, it extracts to a sibling package, not into this one.

## Key Features

- **Typed address arithmetic** — `Memory.Address` is a non-null typed position with `Memory.Address.Offset` (signed byte displacement) and `Memory.Address.Count`; `base + offset`, `b - a` (distance), and `index * stride` stay in typed-byte territory instead of bare `Int`.
- **Stride-typed addressing** — `Affine.Discrete.Ratio<Element, Memory>` scales an `Index<Element>.Offset` into a byte offset, so `base + index * stride` computes element addresses without open-coded `* MemoryLayout<T>.stride`.
- **Aligned allocation** — `Memory.Allocator` allocates and frees aligned regions (`allocate(count:alignment:)` / `deallocate`); `Memory.Alignment` is a checked alignment type.
- **Contiguous & inline storage** — `Memory.Contiguous<Element>` is a typed contiguous region; `Memory.Inline<Element, capacity>` is fixed-capacity in-line storage (both `~Copyable`-aware).
- **Swift Embedded compatible** — no Foundation dependencies.
- **Swift 6 strict memory safety** — the raw-pointer crossings are `unsafe`-marked with disclosed invariants.

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-memory-primitives.git", branch: "main")
]
```

Add to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Memory Primitives", package: "swift-memory-primitives")
    ]
)
```

## Quick Start

```swift
import Memory_Primitives
import Affine_Primitives   // Affine.Discrete.Ratio — not re-exported by the umbrella
import Index_Primitives    // Index<Element>.Offset — not re-exported by the umbrella

// Typed byte count and a checked alignment — no bare Ints:
let byteCount: Memory.Address.Count = .init(UInt(MemoryLayout<UInt64>.stride * 4))
let alignment: Memory.Alignment = .`8`

// Allocate an aligned region, freed on scope exit:
let allocator = Memory.Allocator()
let base = allocator.allocate(count: byteCount, alignment: alignment)
defer { allocator.deallocate(base, count: byteCount, alignment: alignment) }

// Strided, typed addressing — base + index * stride, in byte-typed arithmetic:
let stride: Affine.Discrete.Ratio<UInt64, Memory> = .init(MemoryLayout<UInt64>.stride)
let elementTwo = try base + Index<UInt64>.Offset(2) * stride

// Cross to a raw pointer only at the store / load boundary:
let ptr = unsafe UnsafeMutableRawPointer(elementTwo)
unsafe ptr.storeBytes(of: UInt64(0xCAFE), as: UInt64.self)
let value = unsafe ptr.load(as: UInt64.self)   // 0xCAFE
```

## Architecture

| Type | Description |
|------|-------------|
| `Memory.Address` | A non-null typed memory position (`Tagged<Memory, Ordinal>`) with byte-offset arithmetic |
| `Memory.Address.Offset` / `.Count` | Signed byte displacement and unsigned byte count |
| `Memory.Allocator` / `Memory.Alignment` | Aligned allocation/deallocation and the checked alignment type |
| `Memory.Contiguous<Element>` | A typed contiguous memory region over a `BitwiseCopyable` element |
| `Memory.Inline<Element, capacity>` | Fixed-capacity inline storage (`~Copyable`-aware) |
| `Memory.Contiguous.Protocol` | Protocol for types providing contiguous memory access |

`Memory.Address` bridges to Swift's `Unsafe[Mutable]RawPointer` at the store/load boundary; the typed arithmetic and allocation surface stays above that boundary.

## Platform Support

| Platform         | CI  | Status       |
|------------------|-----|--------------|
| macOS            | -   | Full support |
| Linux            | -   | Full support |
| Windows          | -   | Full support |
| iOS/tvOS/watchOS | -   | Supported    |
| Swift Embedded   | -   | Supported    |

## Related Packages

- [`swift-index-primitives`](https://github.com/swift-primitives/swift-index-primitives) — `Index<Memory>`, the typed byte-offset index used throughout.
- [`swift-byte-primitives`](https://github.com/swift-primitives/swift-byte-primitives) — `Byte`, the unit stored at and loaded from addresses.
- [`swift-bit-primitives`](https://github.com/swift-primitives/swift-bit-primitives) — `Bit`, backing the `Memory.Shift` bit-level operations.
- [`swift-affine-primitives`](https://github.com/swift-primitives/swift-affine-primitives) — `Affine`, the typed address / offset arithmetic.
- [`swift-cardinal-primitives`](https://github.com/swift-primitives/swift-cardinal-primitives) — `Cardinal`, the `Memory.Address.Count` type.
- [`swift-tagged-primitives`](https://github.com/swift-primitives/swift-tagged-primitives) — `Tagged`, the zero-overhead wrapper behind the typed address types.

---

## Community

<!-- BEGIN: discussion -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
