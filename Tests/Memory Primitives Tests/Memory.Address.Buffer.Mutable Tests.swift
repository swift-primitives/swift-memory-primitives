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

@Suite("Memory.Address.Buffer.Mutable")
struct MemoryAddressBufferMutableTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit Tests

extension MemoryAddressBufferMutableTests.Unit {
    @Test("init creates empty buffer with sentinel")
    func initEmpty() {
        let buffer = Memory.Address.Buffer.Mutable()
        #expect(buffer.isEmpty)
        #expect(buffer.count == 0)
    }

    @Test("allocate creates buffer with specified size")
    func allocate() {
        let count: Index<UInt8>.Count = 100
        let alignment: Index<UInt8>.Count = 8
        let buffer = Memory.Address.Buffer.Mutable.allocate(count: count, alignment: alignment)
        defer { buffer.deallocate() }

        #expect(!buffer.isEmpty)
        #expect(buffer.count == 100)
    }

    @Test("subscript read-write access")
    func subscriptReadWrite() {
        let count: Index<UInt8>.Count = 10
        let alignment: Index<UInt8>.Count = 1
        let buffer = Memory.Address.Buffer.Mutable.allocate(count: count, alignment: alignment)
        defer { buffer.deallocate() }

        let idx: Index<UInt8> = 5
        buffer[idx] = 42
        #expect(buffer[idx] == 42)
    }

    @Test("read loads value from buffer")
    func read() {
        let count: Index<UInt8>.Count = 4
        let alignment: Index<UInt8>.Count = 4
        let buffer = Memory.Address.Buffer.Mutable.allocate(count: count, alignment: alignment)
        defer { buffer.deallocate() }

        buffer.store(UInt32(0x12345678), as: UInt32.self)
        let loaded: UInt32 = buffer.read(as: UInt32.self)
        #expect(loaded == 0x12345678)
    }

    @Test("store writes value to buffer")
    func store() {
        let count: Index<UInt8>.Count = 8
        let alignment: Index<UInt8>.Count = 8
        let buffer = Memory.Address.Buffer.Mutable.allocate(count: count, alignment: alignment)
        defer { buffer.deallocate() }

        buffer.store(UInt64(0xDEADBEEFCAFEBABE), as: UInt64.self)
        let loaded: UInt64 = buffer.read(as: UInt64.self)
        #expect(loaded == 0xDEADBEEFCAFEBABE)
    }

    @Test("immutable returns read-only view")
    func immutableProperty() {
        let count: Index<UInt8>.Count = 10
        let alignment: Index<UInt8>.Count = 1
        let mutableBuffer = Memory.Address.Buffer.Mutable.allocate(count: count, alignment: alignment)
        defer { mutableBuffer.deallocate() }

        let idx: Index<UInt8> = 0
        mutableBuffer[idx] = 99

        let immutableBuffer = mutableBuffer.immutable
        #expect(immutableBuffer[idx] == 99)
        #expect(immutableBuffer.count == mutableBuffer.count)
    }
}

// MARK: - Edge Case Tests

extension MemoryAddressBufferMutableTests.EdgeCase {
    @Test("base returns nil for empty buffer (stdlib convention)")
    func baseEmptyReturnsNil() {
        let buffer = Memory.Address.Buffer.Mutable()
        #expect(unsafe buffer.base.baseAddress == nil)
        #expect(unsafe buffer.base.count == 0)
    }

    @Test("baseNonNull returns sentinel for empty buffer")
    func baseNonNullEmpty() {
        let buffer = Memory.Address.Buffer.Mutable()
        #expect(unsafe buffer.baseNonNull.baseAddress != nil)
        #expect(unsafe buffer.baseNonNull.count == 0)
    }

    @Test("slice returns nil for out-of-bounds")
    func sliceOutOfBounds() {
        let count: Index<UInt8>.Count = 10
        let alignment: Index<UInt8>.Count = 1
        let buffer = Memory.Address.Buffer.Mutable.allocate(count: count, alignment: alignment)
        defer { buffer.deallocate() }

        let sliceCount: Index<UInt8>.Count = 10
        let result = buffer.slice(start: 5, count: sliceCount)
        #expect(result == nil)
    }

    @Test("slice succeeds for valid bounds")
    func sliceValid() {
        let count: Index<UInt8>.Count = 10
        let alignment: Index<UInt8>.Count = 1
        let buffer = Memory.Address.Buffer.Mutable.allocate(count: count, alignment: alignment)
        defer { buffer.deallocate() }

        // Initialize buffer
        var i: UInt8 = 0
        (Index<UInt8>.zero..<count).forEach { idx in
            buffer[idx] = i * 10
            i += 1
        }

        let sliceCount: Index<UInt8>.Count = 5
        let slice = buffer.slice(start: 2, count: sliceCount)
        #expect(slice != nil)
        if let slice = slice {
            let idx0: Index<UInt8> = 0
            #expect(slice[idx0] == 20)
        }
    }

    @Test("copy from immutable buffer")
    func copyFromImmutable() {
        let sourceData: [UInt8] = [1, 2, 3, 4, 5]
        unsafe sourceData.withUnsafeBytes { rawBuffer in
            let source = unsafe Memory.Address.Buffer(rawBuffer)
            let count: Index<UInt8>.Count = 5
            let alignment: Index<UInt8>.Count = 1
            let dest = Memory.Address.Buffer.Mutable.allocate(count: count, alignment: alignment)
            defer { dest.deallocate() }

            dest.copy(from: source)

            var expected: UInt8 = 1
            (Index<UInt8>.zero..<count).forEach { idx in
                #expect(dest[idx] == expected)
                expected += 1
            }
        }
    }
}

// MARK: - Integration Tests

extension MemoryAddressBufferMutableTests.Integration {
    @Test("Equatable compares start and count")
    func equatable() {
        let count: Index<UInt8>.Count = 10
        let alignment: Index<UInt8>.Count = 1
        let buffer1 = Memory.Address.Buffer.Mutable.allocate(count: count, alignment: alignment)
        let buffer2 = Memory.Address.Buffer.Mutable.allocate(count: count, alignment: alignment)
        defer {
            buffer1.deallocate()
            buffer2.deallocate()
        }

        #expect(buffer1 == buffer1)
        #expect(buffer1 != buffer2)
    }

    @Test("Hashable produces consistent hash")
    func hashable() {
        let count: Index<UInt8>.Count = 10
        let alignment: Index<UInt8>.Count = 1
        let buffer = Memory.Address.Buffer.Mutable.allocate(count: count, alignment: alignment)
        defer { buffer.deallocate() }

        #expect(buffer.hashValue == buffer.hashValue)
    }

    @Test("withRebound temporarily binds to different type")
    func withRebound() {
        let count: Index<UInt8>.Count = 8
        let alignment: Index<UInt8>.Count = 4
        let buffer = Memory.Address.Buffer.Mutable.allocate(count: count, alignment: alignment)
        defer { buffer.deallocate() }

        unsafe buffer.withRebound(to: UInt32.self) { typedBuffer in
            #expect(unsafe typedBuffer.count == 2)
        }
    }

    @Test("initialize with repeating value")
    func initializeRepeating() {
        let count: Index<UInt8>.Count = 100
        let alignment: Index<UInt8>.Count = 1
        let buffer = Memory.Address.Buffer.Mutable.allocate(count: count, alignment: alignment)
        defer { buffer.deallocate() }

        _ = unsafe buffer.initialize(as: UInt8.self, repeating: 0xFF)

        (Index<UInt8>.zero..<count).forEach { idx in
            #expect(buffer[idx] == 0xFF)
        }
    }
}

// MARK: - Performance Tests

extension MemoryAddressBufferMutableTests.Performance {
    @Test("sequential write")
    func sequentialWrite() {
        let count: Index<UInt8>.Count = 10000
        let alignment: Index<UInt8>.Count = 1
        let buffer = Memory.Address.Buffer.Mutable.allocate(count: count, alignment: alignment)
        defer { buffer.deallocate() }

        // Warmup
        for _ in 0..<10 {
            var value: UInt8 = 0
            (Index<UInt8>.zero..<count).forEach { idx in
                buffer[idx] = value
                value &+= 1
            }
        }

        // Measured
        for _ in 0..<100 {
            var value: UInt8 = 0
            (Index<UInt8>.zero..<count).forEach { idx in
                buffer[idx] = value
                value &+= 1
            }
        }
    }

    @Test("bulk copy")
    func bulkCopy() {
        let size = 10000
        let sourceData = [UInt8](repeating: 42, count: size)
        unsafe sourceData.withUnsafeBytes { rawBuffer in
            let source = unsafe Memory.Address.Buffer(rawBuffer)
            let count: Index<UInt8>.Count = 10000
            let alignment: Index<UInt8>.Count = 1
            let dest = Memory.Address.Buffer.Mutable.allocate(count: count, alignment: alignment)
            defer { dest.deallocate() }

            // Warmup
            for _ in 0..<10 {
                dest.copy(from: source)
            }

            // Measured
            for _ in 0..<100 {
                dest.copy(from: source)
            }
        }
    }
}
