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

import Testing
@testable import Memory_Primitives
import Memory_Primitives_Test_Support
import Affine_Primitives
import Index_Primitives

extension Memory {
    @Suite
    struct Arithmetic {
        @Suite struct Basics {}
        @Suite struct Offset {}
        @Suite struct Distance {}
        @Suite struct Count {}
        @Suite struct Ratio {}
        @Suite struct Composition {}
    }
}

// MARK: - Basics

extension Memory.Arithmetic.Basics {
    @Test("Memory.Address from UnsafeRawPointer preserves identity")
    func addressFromRawPointer() {
        let value: UInt64 = 0xCAFEBABE
        unsafe withUnsafePointer(to: value) { ptr in
            let raw = unsafe UnsafeRawPointer(ptr)
            let address = unsafe Memory.Address(raw)
            let back = unsafe UnsafeRawPointer(address)
            #expect(unsafe back == raw)
        }
    }

    @Test("Memory.Mutable.Address from UnsafeMutableRawPointer preserves identity")
    func mutableAddressFromRawPointer() {
        var value: UInt64 = 0xCAFEBABE
        unsafe withUnsafeMutablePointer(to: &value) { ptr in
            let raw = unsafe UnsafeMutableRawPointer(ptr)
            let address = unsafe Memory.Mutable.Address(raw)
            let back = unsafe UnsafeMutableRawPointer(address)
            #expect(unsafe back == raw)
        }
    }

    @Test("Memory.Address.Offset.zero is the additive identity")
    func offsetZero() {
        let zero: Memory.Address.Offset = .zero
        #expect(zero.rawValue.rawValue == 0)
    }

    @Test("Memory.Address.Count.zero is the empty count")
    func countZero() {
        let zero: Memory.Address.Count = .zero
        #expect(zero.rawValue.rawValue == 0)
    }

    @Test("Memory.Address round-trips through raw pointer")
    func addressRoundTrip() {
        let value: UInt64 = 42
        unsafe withUnsafePointer(to: value) { ptr in
            let raw = unsafe UnsafeRawPointer(ptr)
            let address = unsafe Memory.Address(raw)
            let back = unsafe UnsafeRawPointer(address)
            #expect(unsafe back == raw)
        }
    }
}

// MARK: - Offset

extension Memory.Arithmetic.Offset {
    @Test("Advance address by positive offset")
    func advancePositive() {
        let values: [UInt8] = [10, 20, 30, 40, 50]
        unsafe values.withUnsafeBytes { rawBuffer in
            let base = unsafe Memory.Address(rawBuffer.baseAddress!)
            let offset = Memory.Address.Offset(3)
            let advanced = base + offset

            #expect(advanced.rawValue.rawValue == base.rawValue.rawValue &+ 3)
        }
    }

    @Test("Advance address by negative offset")
    func advanceNegative() {
        let values: [UInt8] = [10, 20, 30, 40, 50]
        unsafe values.withUnsafeBytes { rawBuffer in
            let base = unsafe Memory.Address(rawBuffer.baseAddress!.advanced(by: 4))
            let offset = Memory.Address.Offset(-2)
            let retreated = base + offset

            #expect(retreated.rawValue.rawValue == base.rawValue.rawValue &- 2)
        }
    }

    @Test("Commutative: offset + address == address + offset")
    func commutative() {
        let values: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        unsafe values.withUnsafeBytes { rawBuffer in
            let base = unsafe Memory.Address(rawBuffer.baseAddress!)
            let offset = Memory.Address.Offset(5)

            let lhs = base + offset
            let rhs = offset + base

            #expect(lhs == rhs)
        }
    }

    @Test("Subtract offset from address")
    func subtractOffset() {
        let values: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        unsafe values.withUnsafeBytes { rawBuffer in
            let base = unsafe Memory.Address(rawBuffer.baseAddress!.advanced(by: 4))
            let offset = Memory.Address.Offset(3)
            let result = base - offset

            #expect(result.rawValue.rawValue == base.rawValue.rawValue &- 3)
        }
    }

    @Test("Negate offset: -offset reverses direction")
    func negateOffset() {
        let offset = Memory.Address.Offset(42)
        let negated = -offset

        #expect(negated.rawValue.rawValue == -42)
    }

    @Test("Offset + Offset yields combined displacement")
    func offsetAddition() {
        let a = Memory.Address.Offset(10)
        let b = Memory.Address.Offset(7)
        let sum = a + b

        #expect(sum.rawValue.rawValue == 17)
    }

    @Test("Offset - Offset yields differential displacement")
    func offsetSubtraction() {
        let a = Memory.Address.Offset(10)
        let b = Memory.Address.Offset(7)
        let diff = a - b

        #expect(diff.rawValue.rawValue == 3)
    }

    @Test("Mutable address advances by offset")
    func mutableAdvance() {
        var values: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
        unsafe values.withUnsafeMutableBytes { rawBuffer in
            let base = unsafe Memory.Mutable.Address(rawBuffer.baseAddress!)
            let offset = Memory.Address.Offset(4)
            let advanced = base + offset

            #expect(advanced.rawValue.rawValue == base.rawValue.rawValue &+ 4)
        }
    }

    @Test("advanced(by:) method matches + operator")
    func advancedByMethod() {
        let values: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        unsafe values.withUnsafeBytes { rawBuffer in
            let base = unsafe Memory.Address(rawBuffer.baseAddress!)
            let offset = Memory.Address.Offset(6)

            #expect(base.advanced(by: offset) == base + offset)
        }
    }
}

// MARK: - Distance

extension Memory.Arithmetic.Distance {
    @Test("distance(to:) computes signed byte distance")
    func distanceTo() {
        let values: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
        unsafe values.withUnsafeBytes { rawBuffer in
            let a = unsafe Memory.Address(rawBuffer.baseAddress!)
            let b = unsafe Memory.Address(rawBuffer.baseAddress!.advanced(by: 5))

            let distance = a.distance(to: b)
            #expect(distance.rawValue.rawValue == 5)
        }
    }

    @Test("address - address produces distance via operator")
    func distanceOperator() {
        let values: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
        unsafe values.withUnsafeBytes { rawBuffer in
            let a = unsafe Memory.Address(rawBuffer.baseAddress!)
            let b = unsafe Memory.Address(rawBuffer.baseAddress!.advanced(by: 7))

            let distance = b - a
            #expect(distance.rawValue.rawValue == 7)
        }
    }

    @Test("Distance is antisymmetric: a→b == -(b→a)")
    func distanceAntisymmetric() {
        let values: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
        unsafe values.withUnsafeBytes { rawBuffer in
            let a = unsafe Memory.Address(rawBuffer.baseAddress!)
            let b = unsafe Memory.Address(rawBuffer.baseAddress!.advanced(by: 4))

            let forward = a.distance(to: b)
            let backward = b.distance(to: a)

            #expect(forward == -backward)
        }
    }

    @Test("Round-trip: address + distance(to: other) == other")
    func roundTrip() {
        let values: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
        unsafe values.withUnsafeBytes { rawBuffer in
            let a = unsafe Memory.Address(rawBuffer.baseAddress!)
            let b = unsafe Memory.Address(rawBuffer.baseAddress!.advanced(by: 6))

            let distance = a.distance(to: b)
            let reconstructed = a + distance

            #expect(reconstructed == b)
        }
    }

    @Test("Mutable distance matches immutable distance for same locations")
    func mutableDistance() {
        var values: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
        unsafe values.withUnsafeMutableBytes { rawBuffer in
            let a = unsafe Memory.Mutable.Address(rawBuffer.baseAddress!)
            let b = unsafe Memory.Mutable.Address(rawBuffer.baseAddress!.advanced(by: 3))

            let distance = a.distance(to: b)
            #expect(distance.rawValue.rawValue == 3)
            #expect(a + distance == b)
        }
    }
}

// MARK: - Count

extension Memory.Arithmetic.Count {
    @Test("Count from UInt preserves value")
    func countFromUInt() {
        let count = Memory.Address.Count(UInt(256))
        #expect(count.rawValue.rawValue == 256)
    }

    @Test("Count from Cardinal preserves value")
    func countFromCardinal() {
        let count = Memory.Address.Count(Cardinal(64))
        #expect(count.rawValue.rawValue == 64)
    }

    @Test("Count comparison operators")
    func countComparison() {
        let small = Memory.Address.Count(UInt(10))
        let large = Memory.Address.Count(UInt(100))

        #expect(small < large)
        #expect(large > small)
        #expect(small != large)
        #expect(small == Memory.Address.Count(UInt(10)))
    }

    @Test("Count as allocation size for Buffer.Mutable")
    func countAsAllocationSize() {
        let count = Memory.Address.Count(UInt(64))
        let alignment = Memory.Address.Count(UInt(8))
        let buffer = Memory.Buffer.Mutable.allocate(count: count, alignment: alignment)

        #expect(buffer.count == count)

        buffer.deallocate()
    }

    @Test("Count in store/read with correct byte size")
    func countInStoreRead() {
        let byteCount = Memory.Address.Count(UInt(MemoryLayout<UInt64>.size))
        let alignment = Memory.Address.Count(UInt(MemoryLayout<UInt64>.alignment))
        var arena = Memory.Arena(capacity: Memory.Address.Count(UInt(1024)))

        guard let address = arena.allocate(count: byteCount, alignment: alignment) else {
            Issue.record("Allocation failed")
            return
        }

        address.store(0xDEADBEEF as UInt64, as: UInt64.self)
        let loaded: UInt64 = address.read(as: UInt64.self)
        #expect(loaded == 0xDEADBEEF)
    }
}

// MARK: - Ratio

extension Memory.Arithmetic.Ratio {
    @Test("Ratio scales element offset to byte offset")
    func ratioScalesOffset() {
        let stride = Affine.Discrete.Ratio<Int, Memory>(MemoryLayout<Int>.stride)
        let elementOffset = Index<Int>.Offset(3)
        let byteOffset: Memory.Address.Offset = elementOffset * stride

        #expect(byteOffset.rawValue.rawValue == 3 * MemoryLayout<Int>.stride)
    }

    @Test("Ratio scales element count to byte count")
    func ratioScalesCount() {
        let stride = Affine.Discrete.Ratio<Int, Memory>(MemoryLayout<Int>.stride)
        let elementCount = Index<Int>.Count(UInt(5))
        let byteCount: Memory.Address.Count = elementCount * stride

        #expect(byteCount.rawValue.rawValue == UInt(5 * MemoryLayout<Int>.stride))
    }

    @Test("Ratio scaling is commutative: offset * ratio == ratio * offset")
    func ratioCommutative() {
        let stride = Affine.Discrete.Ratio<UInt32, Memory>(MemoryLayout<UInt32>.stride)
        let offset = Index<UInt32>.Offset(7)

        let lhs: Memory.Address.Offset = offset * stride
        let rhs: Memory.Address.Offset = stride * offset

        #expect(lhs == rhs)
    }

    @Test("Ratio composition: Ratio<A,B> * Ratio<B,C> → Ratio<A,C>")
    func ratioComposition() {
        // 1 UInt64 = 2 UInt32s, 1 UInt32 = 4 bytes
        let r1 = Affine.Discrete.Ratio<UInt64, UInt32>(Int(2))
        let r2 = Affine.Discrete.Ratio<UInt32, Memory>(MemoryLayout<UInt32>.stride)

        let composed: Affine.Discrete.Ratio<UInt64, Memory> = r1 * r2

        #expect(composed.factor == 2 * MemoryLayout<UInt32>.stride)
    }

    @Test("Identity ratio preserves values")
    func identityRatio() {
        let identity: Affine.Discrete.Ratio<Memory, Memory> = .identity
        let offset = Memory.Address.Offset(42)
        let scaled = offset * identity

        #expect(scaled == offset)
    }
}

// MARK: - Composition

extension Memory.Arithmetic.Composition {
    @Test("Strided element access: base + index * stride → element address")
    func stridedAccess() {
        var values: [UInt64] = [100, 200, 300, 400, 500]
        unsafe values.withUnsafeMutableBytes { rawBuffer in
            let base = unsafe Memory.Mutable.Address(rawBuffer.baseAddress!)
            let stride = Affine.Discrete.Ratio<UInt64, Memory>(MemoryLayout<UInt64>.stride)

            for i in 0..<5 {
                let address = base + Index<UInt64>.Offset(i) * stride
                let value: UInt64 = address.read(as: UInt64.self)
                #expect(value == UInt64((i + 1) * 100))
            }
        }
    }

    @Test("Arena allocation → typed store → read back")
    func arenaTypedStoreRead() {
        let intStride = MemoryLayout<Int>.stride
        let count = 4
        var arena = Memory.Arena(
            capacity: Memory.Address.Count(UInt(intStride * count + MemoryLayout<Int>.alignment))
        )

        let alignment = Memory.Address.Count(UInt(MemoryLayout<Int>.alignment))
        let byteCount = Memory.Address.Count(UInt(intStride * count))
        guard let base = arena.allocate(count: byteCount, alignment: alignment) else {
            Issue.record("Allocation failed")
            return
        }

        let stride = Affine.Discrete.Ratio<Int, Memory>(intStride)

        for i in 0..<count {
            let address = base + Index<Int>.Offset(i) * stride
            address.store(i * 11, as: Int.self)
        }

        for i in 0..<count {
            let address = base + Index<Int>.Offset(i) * stride
            let value: Int = address.read(as: Int.self)
            #expect(value == i * 11)
        }
    }

    @Test("Struct field layout: compute addresses at known byte offsets")
    func structFieldLayout() {
        // Simulate a struct with two fields: UInt32 at offset 0, UInt64 at offset 8
        let size = Memory.Address.Count(UInt(16))
        let alignment = Memory.Address.Count(UInt(8))
        var arena = Memory.Arena(capacity: Memory.Address.Count(UInt(1024)))

        guard let base = arena.allocate(count: size, alignment: alignment) else {
            Issue.record("Allocation failed")
            return
        }

        let field0Offset = Memory.Address.Offset(0)
        let field1Offset = Memory.Address.Offset(8)

        (base + field0Offset).store(0x12345678 as UInt32, as: UInt32.self)
        (base + field1Offset).store(0xDEADBEEFCAFEBABE as UInt64, as: UInt64.self)

        let f0: UInt32 = (base + field0Offset).read(as: UInt32.self)
        let f1: UInt64 = (base + field1Offset).read(as: UInt64.self)

        #expect(f0 == 0x12345678)
        #expect(f1 == 0xDEADBEEFCAFEBABE)
    }

    @Test("Copy between addresses with computed byte counts")
    func copyWithComputedCounts() {
        let stride = Affine.Discrete.Ratio<UInt64, Memory>(MemoryLayout<UInt64>.stride)
        let elementCount = Index<UInt64>.Count(UInt(4))
        let byteCount: Memory.Address.Count = elementCount * stride

        let alignment = Memory.Address.Count(UInt(MemoryLayout<UInt64>.alignment))
        var arena = Memory.Arena(capacity: Memory.Address.Count(UInt(4096)))

        guard let src = arena.allocate(count: byteCount, alignment: alignment),
              let dst = arena.allocate(count: byteCount, alignment: alignment) else {
            Issue.record("Allocation failed")
            return
        }

        for i in 0..<4 {
            let address = src + Index<UInt64>.Offset(i) * stride
            address.store(UInt64(i * 100 + 1), as: UInt64.self)
        }

        dst.copy(from: Memory.Address(src), count: byteCount)

        for i in 0..<4 {
            let address = dst + Index<UInt64>.Offset(i) * stride
            let value: UInt64 = address.read(as: UInt64.self)
            #expect(value == UInt64(i * 100 + 1))
        }
    }

    @Test("Index iteration with ratio-scaled addressing")
    func indexIterationRatioScaled() {
        var data: [UInt32] = [10, 20, 30, 40, 50, 60, 70, 80]
        let stride = Affine.Discrete.Ratio<UInt32, Memory>(MemoryLayout<UInt32>.stride)

        unsafe data.withUnsafeMutableBytes { rawBuffer in
            let base = unsafe Memory.Mutable.Address(rawBuffer.baseAddress!)
            var sum: UInt32 = 0

            for i in 0..<8 {
                sum += (base + Index<UInt32>.Offset(i) * stride).read(as: UInt32.self)
            }

            #expect(sum == 360)
        }
    }

    @Test("Bidirectional traversal from midpoint")
    func bidirectionalTraversal() {
        var data: [Int32] = [1, 2, 3, 4, 5, 6, 7, 8]
        let stride = Affine.Discrete.Ratio<Int32, Memory>(MemoryLayout<Int32>.stride)

        unsafe data.withUnsafeMutableBytes { rawBuffer in
            let base = unsafe Memory.Mutable.Address(rawBuffer.baseAddress!)
            let mid = base + Index<Int32>.Offset(4) * stride

            let forward: Int32 = (mid + Index<Int32>.Offset(2) * stride).read(as: Int32.self)
            let backward: Int32 = (mid + Index<Int32>.Offset(-3) * stride).read(as: Int32.self)

            #expect(forward == 7)
            #expect(backward == 2)
        }
    }

    @Test("Chained ratio composition for multi-level addressing")
    func chainedRatioComposition() {
        // Model: 1 CacheLine = 8 UInt64s, 1 UInt64 = 8 bytes
        // So 1 CacheLine = 64 bytes

        enum CacheLine {}

        let lineToElement = Affine.Discrete.Ratio<CacheLine, UInt64>(Int(8))
        let elementToByte = Affine.Discrete.Ratio<UInt64, Memory>(MemoryLayout<UInt64>.stride)
        let lineToByte: Affine.Discrete.Ratio<CacheLine, Memory> = lineToElement * elementToByte

        let lineCount = Index<CacheLine>.Count(UInt(2))
        let totalBytes: Memory.Address.Count = lineCount * lineToByte

        #expect(totalBytes.rawValue.rawValue == UInt(128))

        var arena = Memory.Arena(capacity: Memory.Address.Count(UInt(4096)))
        let alignment = Memory.Address.Count(UInt(64))

        guard let base = arena.allocate(count: totalBytes, alignment: alignment) else {
            Issue.record("Allocation failed")
            return
        }

        // Write to element 3 of cache line 1 (absolute element index = 8 + 3 = 11)
        let lineOffset = Index<CacheLine>.Offset(1) * lineToByte
        let elemOffset = Index<UInt64>.Offset(3) * elementToByte
        let target = base + lineOffset + elemOffset

        target.store(0xBEEF as UInt64, as: UInt64.self)
        #expect(target.read(as: UInt64.self) == 0xBEEF as UInt64)
    }

    @Test("Interleaved access pattern: stride-2 read across elements")
    func interleavedAccess() {
        var data: [UInt32] = [10, 20, 30, 40, 50, 60, 70, 80]
        let stride = Affine.Discrete.Ratio<UInt32, Memory>(MemoryLayout<UInt32>.stride)

        unsafe data.withUnsafeMutableBytes { rawBuffer in
            let base = unsafe Memory.Mutable.Address(rawBuffer.baseAddress!)

            // Read every other element: indices 0, 2, 4, 6
            var evens: [UInt32] = []
            for i in Swift.stride(from: 0, to: 8, by: 2) {
                let value: UInt32 = (base + Index<UInt32>.Offset(i) * stride).read(as: UInt32.self)
                evens.append(value)
            }

            #expect(evens == [10, 30, 50, 70])
        }
    }
}
