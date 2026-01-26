# Memory Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Non-null memory address wrappers with typed index integration for Swift.

## Key Features

- **Non-null guarantees** - All address types enforce non-null invariants at construction
- **Typed index integration** - Uses `Index<UInt8>` for byte-level operations throughout
- **Mutable and immutable variants** - `Memory.Address` and `Memory.Address.Mutable` mirror Swift's pointer duality
- **Buffer types** - `Memory.Address.Buffer` and `Memory.Address.Buffer.Mutable` for contiguous byte regions
- **Swift Embedded compatible** - No Foundation dependencies
- **Swift 6 strict concurrency** - Full `Sendable` compliance with `@unchecked Sendable`

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(path: "../swift-memory-primitives")
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

// Allocate raw memory with typed counts
let byteCount: Index<UInt8>.Count = 100
let alignment: Index<UInt8>.Count = 8
let buffer = Memory.Address.Buffer.Mutable.allocate(byteCount: byteCount, alignment: alignment)
defer { buffer.deallocate() }

// Access bytes via typed index
let idx: Index<UInt8> = 0
buffer[idx] = 42

// Load/store typed values (offset defaults to 0)
buffer.storeBytes(of: UInt32(0xDEADBEEF), as: UInt32.self)
let value = buffer.load(as: UInt32.self)
```

## Architecture

| Type | Description |
|------|-------------|
| `Memory.Address` | Non-null immutable raw memory address |
| `Memory.Address.Mutable` | Non-null mutable raw memory address |
| `Memory.Address.Buffer` | Non-null immutable raw buffer pointer |
| `Memory.Address.Buffer.Mutable` | Non-null mutable raw buffer pointer |
| `Memory.Contiguous.Protocol` | Protocol for types providing contiguous memory access |

All types wrap Swift's `Unsafe*Pointer` family with non-null guarantees and typed index integration.

## Platform Support

| Platform         | CI  | Status       |
|------------------|-----|--------------|
| macOS            | -   | Full support |
| Linux            | -   | Full support |
| Windows          | -   | Full support |
| iOS/tvOS/watchOS | -   | Supported    |
| Swift Embedded   | -   | Supported    |

## License

Apache License v2.0. See [LICENSE](LICENSE) for details.
