---
name: memory-arithmetic
description: |
  Typed arithmetic patterns for Memory.Address, Offset, Count, and Ratio.
  Apply when working with raw memory addresses and byte-level arithmetic.

layer: implementation

requires:
  - swift-institute
  - primitives-conversions

applies_to:
  - swift-memory-primitives
---

# Memory Arithmetic

Typed arithmetic patterns for raw memory operations. Memory-primitives provides an affine space model where addresses are positions and offsets are displacements.

**Core Types**:
- `Memory.Address` — byte-addressable position (non-null)
- `Memory.Address.Offset` — signed byte displacement
- `Memory.Address.Count` — unsigned byte count
- `Affine.Discrete.Ratio<Source, Memory>` — scaling factor from element domain to bytes

---

## Address Arithmetic

### [MEM-ARITH-001] Address + Offset

**Statement**: Use `Address + Offset` to advance a memory address by a signed byte displacement.

```swift
let base = unsafe Memory.Address(rawBuffer.baseAddress!)
let offset: Memory.Address.Offset = 3
let advanced = base + offset
```

**Arithmetic**:
- `Address + Offset → Address`
- `Address - Offset → Address`
- `Offset + Address → Address` (commutative)

---

### [MEM-ARITH-002] Address - Address

**Statement**: Use `Address - Address` to compute the signed byte displacement between two addresses.

```swift
let a = unsafe Memory.Address(rawBuffer.baseAddress!)
let b = unsafe Memory.Address(rawBuffer.baseAddress!.advanced(by: 7))

let distance: Memory.Address.Offset = b - a  // 7 bytes
```

**Arithmetic**:
- `Address - Address → Offset`
- Antisymmetric: `a.distance(to: b) == -(b.distance(to: a))`
- Round-trip: `a + a.distance(to: b) == b`

---

### [MEM-ARITH-003] Offset Arithmetic

**Statement**: Offsets form a group with addition, subtraction, and negation.

```swift
let a: Memory.Address.Offset = 10
let b: Memory.Address.Offset = 7

let sum = a + b      // 17
let diff = a - b     // 3
let negated = -a     // -10
```

**Properties**:
- Identity: `.zero`
- Negation: `-offset` reverses direction
- Associative: `(a + b) + c == a + (b + c)`

---

## Count Patterns

### [MEM-ARITH-004] Count as Allocation Size

**Statement**: Use `Memory.Address.Count` for allocation sizes and byte lengths.

```swift
let byteCount: Memory.Address.Count = 64
let alignment: Memory.Address.Count = 8
let buffer = Memory.Buffer.Mutable.allocate(count: byteCount, alignment: alignment)

#expect(buffer.count == byteCount)
```

**Literal construction** (via Test Support):
```swift
let count: Memory.Address.Count = 256
#expect(count == 256)
```

---

### [MEM-ARITH-005] Count from MemoryLayout

**Statement**: Construct Count from `MemoryLayout` for type-derived sizes.

```swift
let byteCount: Memory.Address.Count = .init(UInt(MemoryLayout<UInt64>.size))
let alignment: Memory.Address.Count = .init(UInt(MemoryLayout<UInt64>.alignment))
```

---

## Ratio Scaling

### [MEM-ARITH-006] Element to Byte Scaling

**Statement**: Use `Affine.Discrete.Ratio<Element, Memory>` to scale element offsets/counts to byte offsets/counts.

```swift
let stride: Affine.Discrete.Ratio<Int, Memory> = .init(MemoryLayout<Int>.stride)
let elementOffset: Index<Int>.Offset = 3
let byteOffset: Memory.Address.Offset = elementOffset * stride
```

**Scaling operations**:
- `Index<T>.Offset * Ratio<T, Memory> → Memory.Address.Offset`
- `Index<T>.Count * Ratio<T, Memory> → Memory.Address.Count`
- Commutative: `offset * ratio == ratio * offset`

---

### [MEM-ARITH-007] Ratio Composition

**Statement**: Ratios compose via multiplication for multi-level addressing.

```swift
// 1 CacheLine = 8 UInt64s, 1 UInt64 = 8 bytes
enum CacheLine {}

let lineToElement: Affine.Discrete.Ratio<CacheLine, UInt64> = .init(8)
let elementToByte: Affine.Discrete.Ratio<UInt64, Memory> = .init(MemoryLayout<UInt64>.stride)
let lineToByte: Affine.Discrete.Ratio<CacheLine, Memory> = lineToElement * elementToByte

let lineCount: Index<CacheLine>.Count = 2
let totalBytes: Memory.Address.Count = lineCount * lineToByte  // 128 bytes
```

---

### [MEM-ARITH-008] Identity Ratio

**Statement**: The identity ratio preserves values in the same domain.

```swift
let identity: Affine.Discrete.Ratio<Memory, Memory> = .identity
let offset: Memory.Address.Offset = 42
let scaled = offset * identity  // Still 42
```

---

## Strided Access Patterns

### [MEM-ARITH-009] Strided Element Access

**Statement**: Compute element addresses as `base + index * stride`.

```swift
let base: Memory.Mutable.Address = unsafe .init(rawBuffer.baseAddress!)
let stride: Affine.Discrete.Ratio<UInt64, Memory> = .init(MemoryLayout<UInt64>.stride)

for i in 0..<5 {
    let address = base + Index<UInt64>.Offset(i) * stride
    let value: UInt64 = address.read(as: UInt64.self)
    #expect(value == UInt64((i + 1) * 100))
}
```

**Pattern**: `base + Index<T>.Offset(i) * stride` computes address of element `i`.

---

### [MEM-ARITH-010] Field Offset Access

**Statement**: Use literal byte offsets for struct field access.

```swift
let field0Offset: Memory.Address.Offset = 0
let field1Offset: Memory.Address.Offset = 8

(base + field0Offset).store(0x12345678, as: UInt32.self)
(base + field1Offset).store(0xDEADBEEFCAFEBABE, as: UInt64.self)
```

---

### [MEM-ARITH-011] Multi-Level Addressing

**Statement**: Chain ratio scaling for hierarchical access.

```swift
// Write to element 3 of cache line 1
let lineOffset: Memory.Address.Offset = 1 * lineToByte
let elemOffset: Memory.Address.Offset = 3 * elementToByte
let target = base + lineOffset + elemOffset

target.store(0xBEEF, as: UInt64.self)
```

---

## Test Patterns

### [MEM-ARITH-012] External Counter for Test Values

**Statement**: Use external loop counter, not index conversion, for test value computation.

**Correct**:
```swift
for i in 0..<count {
    let address = base + Index<Int>.Offset(i) * stride
    address.store(i * 11, as: Int.self)
}
```

**Incorrect**:
```swift
for i in 0..<count {
    let address = base + Index<Int>.Offset(i) * stride
    // ❌ Don't convert index to compute value
    address.store(Int(bitPattern: Index<Int>(i).position.rawValue) * 11, as: Int.self)
}
```

---

### [MEM-ARITH-013] Literal Comparison

**Statement**: Use literals for offset/count comparisons in tests.

```swift
let offset: Memory.Address.Offset = 3
#expect(offset == 3)

let count: Memory.Address.Count = 64
#expect(count == 64)
```

---

## Cross-References

See also:
- **primitives-conversions** skill for [CONV-001] rawValue location
- **pointer-arithmetic** skill for typed pointer patterns
- Test file: `Tests/Memory Primitives Tests/Memory Arithmetic Tests.swift`
