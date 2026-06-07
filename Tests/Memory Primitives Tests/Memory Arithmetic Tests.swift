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

import Affine_Primitives
import Index_Primitives
import Memory_Primitives_Test_Support
import Testing

@testable import Memory_Primitives

extension Memory {
    @Suite
    struct Arithmetic {
        @Suite
        struct Basics {}
        @Suite
        struct Offset {}
        @Suite
        struct Distance {}
        @Suite
        struct Count {}
        @Suite
        struct Ratio {}
        @Suite
        struct Composition {}
    }
}

// MARK: - Basics

extension Memory.Arithmetic.Basics {
    @Test
    func `Memory.Address from UnsafeRawPointer preserves identity`() {
        let value: UInt64 = 0xCAFE_BABE
        unsafe withUnsafePointer(to: value) { ptr in
            let raw = unsafe UnsafeRawPointer(ptr)
            let address = unsafe Memory.Address(raw)
            let back = unsafe UnsafeRawPointer(address)
            #expect(unsafe back == raw)
        }
    }

    @Test
    func `Memory.Address from UnsafeMutableRawPointer preserves identity`() {
        var value: UInt64 = 0xCAFE_BABE
        unsafe withUnsafeMutablePointer(to: &value) { ptr in
            let raw = UnsafeMutableRawPointer(ptr)
            let address = unsafe Memory.Address(raw)
            let back = unsafe UnsafeMutableRawPointer(address)
            #expect(unsafe back == raw)
        }
    }

    @Test
    func `Memory.Address.Offset.zero is the additive identity`() {
        let zero: Memory.Address.Offset = .zero
        #expect(zero == .zero)
    }

    @Test
    func `Memory.Address.Count.zero is the empty count`() {
        let zero: Memory.Address.Count = .zero
        #expect(zero == .zero)
    }

    @Test
    func `Memory.Address round-trips through raw pointer`() {
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
    @Test
    func `Advance address by positive offset`() throws {
        let values: [UInt8] = [10, 20, 30, 40, 50]
        try unsafe values.withUnsafeBytes { rawBuffer in
            let base = unsafe Memory.Address(rawBuffer.baseAddress!)
            let offset: Memory.Address.Offset = 3
            let advanced = try base + offset

            #expect(advanced.underlying.rawValue == base.underlying.rawValue &+ 3)
        }
    }

    @Test
    func `Advance address by negative offset`() throws {
        let values: [UInt8] = [10, 20, 30, 40, 50]
        try unsafe values.withUnsafeBytes { rawBuffer in
            let base = unsafe Memory.Address(rawBuffer.baseAddress!.advanced(by: 4))
            let offset: Memory.Address.Offset = -2
            let retreated = try base + offset

            #expect(retreated.underlying.rawValue == base.underlying.rawValue &- 2)
        }
    }

    @Test
    func `Commutative: offset + address == address + offset`() throws {
        let values: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        try unsafe values.withUnsafeBytes { rawBuffer in
            let base = unsafe Memory.Address(rawBuffer.baseAddress!)
            let offset: Memory.Address.Offset = 5

            let lhs = try base + offset
            let rhs = try offset + base

            #expect(lhs == rhs)
        }
    }

    @Test
    func `Subtract offset from address`() throws {
        let values: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        try unsafe values.withUnsafeBytes { rawBuffer in
            let base = unsafe Memory.Address(rawBuffer.baseAddress!.advanced(by: 4))
            let offset: Memory.Address.Offset = 3
            let result = try base - offset

            #expect(result.underlying.rawValue == base.underlying.rawValue &- 3)
        }
    }

    @Test
    func `Negate offset: -offset reverses direction`() {
        let offset: Memory.Address.Offset = 42
        let negated = -offset

        #expect(negated == -42)
    }

    @Test
    func `Offset + Offset yields combined displacement`() {
        let a: Memory.Address.Offset = 10
        let b: Memory.Address.Offset = 7
        let sum = a + b

        #expect(sum == 17)
    }

    @Test
    func `Offset - Offset yields differential displacement`() {
        let a: Memory.Address.Offset = 10
        let b: Memory.Address.Offset = 7
        let diff = a - b

        #expect(diff == 3)
    }

    @Test
    func `Mutable address advances by offset`() throws {
        var values: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
        try unsafe values.withUnsafeMutableBytes { rawBuffer in
            let base = unsafe Memory.Address(rawBuffer.baseAddress!)
            let offset: Memory.Address.Offset = 4
            let advanced = try base + offset

            #expect(advanced.underlying.rawValue == base.underlying.rawValue &+ 4)
        }
    }
}

// MARK: - Distance

extension Memory.Arithmetic.Distance {
    @Test
    func `Subtraction computes signed byte distance`() throws {
        let values: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
        try unsafe values.withUnsafeBytes { rawBuffer in
            let a = unsafe Memory.Address(rawBuffer.baseAddress!)
            let b = unsafe Memory.Address(rawBuffer.baseAddress!.advanced(by: 5))

            let distance: Memory.Address.Offset = try b - a
            #expect(distance == 5)
        }
    }

    @Test
    func `address - address produces distance via operator`() throws {
        let values: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
        try unsafe values.withUnsafeBytes { rawBuffer in
            let a = unsafe Memory.Address(rawBuffer.baseAddress!)
            let b = unsafe Memory.Address(rawBuffer.baseAddress!.advanced(by: 7))

            let distance = try b - a
            #expect(distance == 7)
        }
    }

    @Test
    func `Distance is antisymmetric: a→b == -(b→a)`() throws {
        let values: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
        try unsafe values.withUnsafeBytes { rawBuffer in
            let a = unsafe Memory.Address(rawBuffer.baseAddress!)
            let b = unsafe Memory.Address(rawBuffer.baseAddress!.advanced(by: 4))

            let forward: Memory.Address.Offset = try b - a
            let backward: Memory.Address.Offset = try a - b

            #expect(forward == -backward)
        }
    }

    @Test
    func `Round-trip: address + (other - address) == other`() throws {
        let values: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
        try unsafe values.withUnsafeBytes { rawBuffer in
            let a = unsafe Memory.Address(rawBuffer.baseAddress!)
            let b = unsafe Memory.Address(rawBuffer.baseAddress!.advanced(by: 6))

            let distance: Memory.Address.Offset = try b - a
            let reconstructed = try a + distance

            #expect(reconstructed == b)
        }
    }

    @Test
    func `Distance between two addresses in same buffer`() throws {
        var values: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
        try unsafe values.withUnsafeMutableBytes { rawBuffer in
            let a = unsafe Memory.Address(rawBuffer.baseAddress!)
            let b = unsafe Memory.Address(rawBuffer.baseAddress!.advanced(by: 3))

            // Use subtraction to get distance (b - a = offset from a to b)
            let distance: Memory.Address.Offset = try b - a
            #expect(distance == 3)
            #expect(try a + distance == b)
        }
    }
}

// MARK: - Count

extension Memory.Arithmetic.Count {
    @Test
    func `Count from UInt preserves value`() {
        let count: Memory.Address.Count = 256
        #expect(count == 256)
    }

    @Test
    func `Count from Cardinal preserves value`() {
        let count: Memory.Address.Count = .init(Cardinal(64))
        #expect(count == 64)
    }

    @Test
    func `Count comparison operators`() {
        let small: Memory.Address.Count = 10
        let large: Memory.Address.Count = 100

        #expect(small < large)
        #expect(large > small)
        #expect(small != large)
        #expect(small == 10)
    }

    @Test
    func `Count in store/read with correct byte size`() {
        let byteCount: Memory.Address.Count = .init(UInt(MemoryLayout<UInt64>.size))
        let alignment: Memory.Alignment = .`8`
        let address = unsafe Memory.Address(
            UnsafeMutableRawPointer.allocate(count: byteCount, alignment: alignment)
        )
        defer { unsafe UnsafeMutableRawPointer(address).deallocate() }

        let ptr = unsafe UnsafeMutableRawPointer(address)
        unsafe ptr.storeBytes(of: UInt64(0xDEAD_BEEF), as: UInt64.self)
        let loaded: UInt64 = unsafe ptr.load(as: UInt64.self)
        #expect(loaded == 0xDEAD_BEEF)
    }
}

// MARK: - Ratio

extension Memory.Arithmetic.Ratio {
    @Test
    func `Ratio scales element offset to byte offset`() {
        let stride: Affine.Discrete.Ratio<Int, Memory> = .init(MemoryLayout<Int>.stride)
        let elementOffset: Index<Int>.Offset = 3
        let byteOffset: Memory.Address.Offset = elementOffset * stride

        #expect(byteOffset.underlying.rawValue == 3 * MemoryLayout<Int>.stride)
    }

    @Test
    func `Ratio scales element count to byte count`() {
        let stride: Affine.Discrete.Ratio<Int, Memory> = .init(MemoryLayout<Int>.stride)
        let elementCount: Index<Int>.Count = 5
        let byteCount: Memory.Address.Count = elementCount * stride

        #expect(byteCount.underlying.rawValue == UInt(5 * MemoryLayout<Int>.stride))
    }

    @Test
    func `Ratio scaling is commutative: offset * ratio == ratio * offset`() {
        let stride: Affine.Discrete.Ratio<UInt32, Memory> = .init(MemoryLayout<UInt32>.stride)
        let offset: Index<UInt32>.Offset = 7

        let lhs: Memory.Address.Offset = offset * stride
        let rhs: Memory.Address.Offset = stride * offset

        #expect(lhs == rhs)
    }

    @Test
    func `Ratio composition: Ratio<A,B> * Ratio<B,C> → Ratio<A,C>`() {
        // 1 UInt64 = 2 UInt32s, 1 UInt32 = 4 bytes
        let r1: Affine.Discrete.Ratio<UInt64, UInt32> = .init(Int(2))
        let r2: Affine.Discrete.Ratio<UInt32, Memory> = .init(MemoryLayout<UInt32>.stride)

        let composed: Affine.Discrete.Ratio<UInt64, Memory> = r1 * r2

        #expect(composed.factor == 2 * MemoryLayout<UInt32>.stride)
    }

    @Test
    func `Identity ratio preserves values`() {
        let identity: Affine.Discrete.Ratio<Memory, Memory> = .identity
        let offset: Memory.Address.Offset = 42
        let scaled = offset * identity

        #expect(scaled == offset)
    }
}

// MARK: - Composition

extension Memory.Arithmetic.Composition {
    @Test
    func `Strided element access: base + index * stride → element address`() throws {
        var values: [UInt64] = [100, 200, 300, 400, 500]
        try unsafe values.withUnsafeMutableBytes { rawBuffer in
            let base: Memory.Address = unsafe .init(rawBuffer.baseAddress!)
            let stride: Affine.Discrete.Ratio<UInt64, Memory> = .init(MemoryLayout<UInt64>.stride)

            for i in 0..<5 {
                let address = try base + Index<UInt64>.Offset(i) * stride
                let ptr = unsafe UnsafeRawPointer(address)
                let value: UInt64 = unsafe ptr.load(as: UInt64.self)
                #expect(value == UInt64((i + 1) * 100))
            }
        }
    }

    @Test
    func `Allocator allocation → typed store → read back`() throws {
        let intStride = MemoryLayout<Int>.stride
        let count = 4
        let alignment: Memory.Alignment = .`8`
        let byteCount: Memory.Address.Count = .init(UInt(intStride * count))
        let base = unsafe Memory.Address(
            UnsafeMutableRawPointer.allocate(count: byteCount, alignment: alignment)
        )
        defer { unsafe UnsafeMutableRawPointer(base).deallocate() }

        let stride: Affine.Discrete.Ratio<Int, Memory> = .init(intStride)

        for i in 0..<count {
            let address = try base + Index<Int>.Offset(i) * stride
            let ptr = unsafe UnsafeMutableRawPointer(address)
            unsafe ptr.storeBytes(of: i * 11, as: Int.self)
        }

        for i in 0..<count {
            let address = try base + Index<Int>.Offset(i) * stride
            let ptr = unsafe UnsafeRawPointer(address)
            let value: Int = unsafe ptr.load(as: Int.self)
            #expect(value == i * 11)
        }
    }

    @Test
    func `Struct field layout: compute addresses at known byte offsets`() throws {
        // Simulate a struct with two fields: UInt32 at offset 0, UInt64 at offset 8
        let size: Memory.Address.Count = 16
        let alignment: Memory.Alignment = .`8`
        let base = unsafe Memory.Address(
            UnsafeMutableRawPointer.allocate(count: size, alignment: alignment)
        )
        defer { unsafe UnsafeMutableRawPointer(base).deallocate() }

        let field0Offset: Memory.Address.Offset = 0
        let field1Offset: Memory.Address.Offset = 8

        let ptr0 = unsafe UnsafeMutableRawPointer(try base + field0Offset)
        let ptr1 = unsafe UnsafeMutableRawPointer(try base + field1Offset)

        unsafe ptr0.storeBytes(of: UInt32(0x1234_5678), as: UInt32.self)
        unsafe ptr1.storeBytes(of: UInt64(0xDEAD_BEEF_CAFE_BABE), as: UInt64.self)

        let f0: UInt32 = unsafe UnsafeRawPointer(ptr0).load(as: UInt32.self)
        let f1: UInt64 = unsafe UnsafeRawPointer(ptr1).load(as: UInt64.self)

        #expect(f0 == 0x1234_5678)
        #expect(f1 == 0xDEAD_BEEF_CAFE_BABE)
    }

    @Test
    func `Copy between addresses with computed byte counts`() throws {
        let stride: Affine.Discrete.Ratio<UInt64, Memory> = .init(MemoryLayout<UInt64>.stride)
        let elementCount: Index<UInt64>.Count = 4
        let byteCount: Memory.Address.Count = elementCount * stride

        let alignment: Memory.Alignment = .`8`
        let src = unsafe Memory.Address(
            UnsafeMutableRawPointer.allocate(count: byteCount, alignment: alignment)
        )
        let dst = unsafe Memory.Address(
            UnsafeMutableRawPointer.allocate(count: byteCount, alignment: alignment)
        )
        defer {
            unsafe UnsafeMutableRawPointer(src).deallocate()
            unsafe UnsafeMutableRawPointer(dst).deallocate()
        }

        // Use raw pointers for memory operations
        let srcPtr = unsafe UnsafeMutableRawPointer(src)
        let dstPtr = unsafe UnsafeMutableRawPointer(dst)

        for i in 0..<4 {
            let address = try src + Index<UInt64>.Offset(i) * stride
            let ptr = unsafe UnsafeMutableRawPointer(address)
            unsafe ptr.storeBytes(of: UInt64(i * 100 + 1), as: UInt64.self)
        }

        unsafe dstPtr.copyMemory(from: UnsafeRawPointer(srcPtr), byteCount: Int(bitPattern: byteCount))

        for i in 0..<4 {
            let address = try dst + Index<UInt64>.Offset(i) * stride
            let ptr = unsafe UnsafeRawPointer(address)
            let value: UInt64 = unsafe ptr.load(as: UInt64.self)
            #expect(value == UInt64(i * 100 + 1))
        }
    }

    @Test
    func `Index iteration with ratio-scaled addressing`() throws {
        var data: [UInt32] = [10, 20, 30, 40, 50, 60, 70, 80]
        let stride: Affine.Discrete.Ratio<UInt32, Memory> = .init(MemoryLayout<UInt32>.stride)

        try unsafe data.withUnsafeMutableBytes { rawBuffer in
            let base: Memory.Address = unsafe .init(rawBuffer.baseAddress!)
            var sum: UInt32 = 0

            for i in 0..<8 {
                let addr = try base + Index<UInt32>.Offset(i) * stride
                let ptr = unsafe UnsafeRawPointer(addr)
                sum += unsafe ptr.load(as: UInt32.self)
            }

            #expect(sum == 360)
        }
    }

    @Test
    func `Bidirectional traversal from midpoint`() throws {
        var data: [Int32] = [1, 2, 3, 4, 5, 6, 7, 8]
        let stride: Affine.Discrete.Ratio<Int32, Memory> = .init(MemoryLayout<Int32>.stride)

        try unsafe data.withUnsafeMutableBytes { rawBuffer in
            let base: Memory.Address = unsafe .init(rawBuffer.baseAddress!)
            let mid: Memory.Address = base + 4 * stride

            let forwardAddr = mid + 2 * stride
            let backwardAddr = try mid - 3 * stride  // Use subtraction to go backward
            let forward: Int32 = unsafe UnsafeRawPointer(forwardAddr).load(as: Int32.self)
            let backward: Int32 = unsafe UnsafeRawPointer(backwardAddr).load(as: Int32.self)

            #expect(forward == 7)
            #expect(backward == 2)
        }
    }

    @Test
    func `Chained ratio composition for multi-level addressing`() throws {
        // Model: 1 CacheLine = 8 UInt64s, 1 UInt64 = 8 bytes
        // So 1 CacheLine = 64 bytes

        enum CacheLine {}

        let lineToElement: Affine.Discrete.Ratio<CacheLine, UInt64> = .init(Int(8))
        let elementToByte: Affine.Discrete.Ratio<UInt64, Memory> = .init(MemoryLayout<UInt64>.stride)
        let lineToByte: Affine.Discrete.Ratio<CacheLine, Memory> = lineToElement * elementToByte

        let lineCount: Index<CacheLine>.Count = 2
        let totalBytes: Memory.Address.Count = lineCount * lineToByte

        #expect(totalBytes == 128)

        let alignment = try Memory.Alignment(64)
        let base = unsafe Memory.Address(
            UnsafeMutableRawPointer.allocate(count: totalBytes, alignment: alignment)
        )
        defer { unsafe UnsafeMutableRawPointer(base).deallocate() }

        // Write to element 3 of cache line 1 (absolute element index = 8 + 3 = 11)
        let lineOffset: Memory.Address.Offset = 1 * lineToByte
        let elemOffset: Memory.Address.Offset = 3 * elementToByte
        let target: Memory.Address = try base + lineOffset + elemOffset

        // Use raw pointer for memory operations (addresses are positions, not capabilities)
        let ptr = unsafe UnsafeMutableRawPointer(target)
        unsafe ptr.storeBytes(of: UInt64(0xBEEF), as: UInt64.self)
        #expect(unsafe ptr.load(as: UInt64.self) == 0xBEEF)
    }

    @Test
    func `Interleaved access pattern: stride-2 read across elements`() throws {
        var data: [UInt32] = [10, 20, 30, 40, 50, 60, 70, 80]
        let stride: Affine.Discrete.Ratio<UInt32, Memory> = .init(MemoryLayout<UInt32>.stride)

        try unsafe data.withUnsafeMutableBytes { rawBuffer in
            let base: Memory.Address = unsafe .init(rawBuffer.baseAddress!)

            // Read every other element: indices 0, 2, 4, 6
            var evens: [UInt32] = []
            for i in Swift.stride(from: 0, to: 8, by: 2) {
                let addr: Memory.Address = try base + Index.Offset(i) * stride
                let ptr = unsafe UnsafeRawPointer(addr)
                let value: UInt32 = unsafe ptr.load(as: UInt32.self)
                evens.append(value)
            }

            #expect(evens == [10, 30, 50, 70])
        }
    }
}
