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

extension Memory.Buffer.Mutable {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
        @Suite struct Integration {}
        @Suite(.serialized) struct Performance {}
    }
}

// MARK: - Unit Tests

extension Memory.Buffer.Mutable.Test.Unit {
    @Test
    func `init creates empty buffer with sentinel`() {
        let buffer = Memory.Buffer.Mutable()
        #expect(buffer.isEmpty)
        #expect(buffer.count == 0)
    }

    @Test
    func `allocate creates buffer with specified size`() {
        let buffer = Memory.Buffer.Mutable.allocate(count: 100, alignment: .`8`)
        defer { buffer.deallocate() }

        #expect(!buffer.isEmpty)
        #expect(buffer.count == 100)
    }

    @Test
    func `subscript read-write access`() {
        let buffer = Memory.Buffer.Mutable.allocate(count: 10, alignment: .byte)
        defer { buffer.deallocate() }

        let idx: Index<Memory> = 5
        buffer[idx] = 42
        #expect(buffer[idx] == 42)
    }

    @Test
    func `read loads value from buffer`() {
        let buffer = Memory.Buffer.Mutable.allocate(count: 4, alignment: .word)
        defer { buffer.deallocate() }

        buffer.store(0x12345678, as: UInt32.self)
        let loaded: UInt32 = buffer.read(as: UInt32.self)
        #expect(loaded == 0x12345678)
    }

    @Test
    func `store writes value to buffer`() {
        let buffer = Memory.Buffer.Mutable.allocate(count: 8, alignment: .`8`)
        defer { buffer.deallocate() }

        buffer.store(0xDEADBEEFCAFEBABE, as: UInt64.self)
        let loaded: UInt64 = buffer.read(as: UInt64.self)
        #expect(loaded == 0xDEADBEEFCAFEBABE)
    }

    @Test
    func `immutable returns read-only view`() {
        let mutableBuffer = Memory.Buffer.Mutable.allocate(count: 10, alignment: .byte)
        defer { mutableBuffer.deallocate() }

        let idx: Index<Memory> = 0
        mutableBuffer[idx] = 99

        let immutableBuffer = mutableBuffer.immutable
        #expect(immutableBuffer[idx] == 99)
        #expect(immutableBuffer.count == mutableBuffer.count)
    }
}

// MARK: - Edge Case Tests

extension Memory.Buffer.Mutable.Test.EdgeCase {
    @Test
    func `base.nullable returns nil for empty buffer (stdlib convention)`() {
        let buffer = Memory.Buffer.Mutable()
        #expect(unsafe buffer.base.nullable.baseAddress == nil)
        #expect(unsafe buffer.base.nullable.count == 0)
    }

    @Test
    func `base.nonNull returns sentinel for empty buffer`() {
        let buffer = Memory.Buffer.Mutable()
        #expect(unsafe buffer.base.nonNull.baseAddress != nil)
        #expect(unsafe buffer.base.nonNull.count == 0)
    }

    @Test
    func `slice returns nil for out-of-bounds`() {
        let buffer = Memory.Buffer.Mutable.allocate(count: 10, alignment: .byte)
        defer { buffer.deallocate() }

        let result = buffer.slice(start: 5, count: 10)
        #expect(result == nil)
    }

    @Test
    func `slice succeeds for valid bounds`() {
        let count: Memory.Address.Count = 10
        let buffer = Memory.Buffer.Mutable.allocate(count: 10, alignment: .byte)
        defer { buffer.deallocate() }

        // Initialize buffer
        var i: UInt8 = 0
        (Index<Memory>.zero..<count).forEach { idx in
            buffer[idx] = i * 10
            i += 1
        }

        let slice = buffer.slice(start: 2, count: 5)
        #expect(slice != nil)
        if let slice = slice {
            #expect(slice[0] == 20)
        }
    }

    @Test
    func `copy from immutable buffer`() {
        let sourceData: [UInt8] = [1, 2, 3, 4, 5]
        unsafe sourceData.withUnsafeBytes { rawBuffer in
            let source = unsafe Memory.Buffer(rawBuffer)
            let count: Memory.Address.Count = 5
            let dest = Memory.Buffer.Mutable.allocate(count: count, alignment: .byte)
            defer { dest.deallocate() }

            dest.copy(from: source)

            var expected: UInt8 = 1
            (Index<Memory>.zero..<count).forEach { idx in
                #expect(dest[idx] == expected)
                expected += 1
            }
        }
    }
}

// MARK: - Integration Tests

extension Memory.Buffer.Mutable.Test.Integration {
    @Test
    func `Equatable compares start and count`() {
        let count: Memory.Address.Count = 10
        let alignment: Memory.Alignment = .byte
        let buffer1 = Memory.Buffer.Mutable.allocate(count: count, alignment: alignment)
        let buffer2 = Memory.Buffer.Mutable.allocate(count: count, alignment: alignment)
        defer {
            buffer1.deallocate()
            buffer2.deallocate()
        }

        #expect(buffer1 == buffer1)
        #expect(buffer1 != buffer2)
    }

    @Test
    func `Hashable produces consistent hash`() {
        let buffer = Memory.Buffer.Mutable.allocate(count: 10, alignment: .byte)
        defer { buffer.deallocate() }

        #expect(buffer.hashValue == buffer.hashValue)
    }

    @Test
    func `withRebound temporarily binds to different type`() {
        let buffer = Memory.Buffer.Mutable.allocate(count: 8, alignment: .word)
        defer { buffer.deallocate() }

        unsafe buffer.withRebound(to: UInt32.self) { typedBuffer in
            #expect(typedBuffer.count == 2)
        }
    }

    @Test
    func `initialize with repeating value`() {
        let count: Memory.Address.Count = 100
        let buffer = Memory.Buffer.Mutable.allocate(count: count, alignment: .byte)
        defer { buffer.deallocate() }

        _ = unsafe buffer.initialize(as: UInt8.self, repeating: 0xFF)

        (Index<Memory>.zero..<count).forEach { idx in
            #expect(buffer[idx] == 0xFF)
        }
    }
}

// MARK: - Performance Tests

extension Memory.Buffer.Mutable.Test.Performance {
    @Test
    func `sequential write`() {
        let count: Memory.Address.Count = 10000
        let buffer = Memory.Buffer.Mutable.allocate(count: count, alignment: .byte)
        defer { buffer.deallocate() }

        // Warmup
        for _ in 0..<10 {
            var value: UInt8 = 0
            (Index<Memory>.zero..<count).forEach { idx in
                buffer[idx] = value
                value &+= 1
            }
        }

        // Measured
        for _ in 0..<100 {
            var value: UInt8 = 0
            (Index<Memory>.zero..<count).forEach { idx in
                buffer[idx] = value
                value &+= 1
            }
        }
    }

    @Test
    func `bulk copy`() {
        let size = 10000
        let sourceData = [UInt8](repeating: 42, count: size)
        unsafe sourceData.withUnsafeBytes { rawBuffer in
            let source = unsafe Memory.Buffer(rawBuffer)
            let dest = Memory.Buffer.Mutable.allocate(count: 10000, alignment: .byte)
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
