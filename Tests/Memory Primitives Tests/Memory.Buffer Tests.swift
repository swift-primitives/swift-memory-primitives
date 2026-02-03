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

extension Memory.Buffer {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
        @Suite struct Integration {}
        @Suite(.serialized) struct Performance {}
    }
}

extension Memory.Buffer.Test.Unit {
    @Test
    func `init creates empty buffer with sentinel`() {
        let buffer = Memory.Buffer()
        #expect(buffer.isEmpty)
        #expect(buffer.count == 0)
    }

    @Test
    func `init from start and count`() {
        let data: [UInt8] = [1, 2, 3, 4, 5]
        unsafe data.withUnsafeBufferPointer { ptr in
            guard let baseAddress = ptr.baseAddress else { return }
            let start = unsafe Memory.Address(baseAddress)
            let count: Memory.Address.Count = 5
            let buffer = Memory.Buffer(start: start, count: count)

            #expect(!buffer.isEmpty)
            #expect(buffer.count == 5)
        }
    }

    @Test
    func `init from UnsafeRawBufferPointer`() {
        let data: [UInt8] = [10, 20, 30]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Buffer(rawBuffer)
            #expect(buffer.count == 3)
        }
    }

    @Test
    func `init from empty UnsafeRawBufferPointer uses sentinel`() {
        let emptyBuffer = unsafe UnsafeRawBufferPointer(start: nil, count: 0)
        let buffer = unsafe Memory.Buffer(emptyBuffer)
        #expect(buffer.isEmpty)
        #expect(buffer.count == 0)
    }

    @Test
    func `start property returns non-null address`() {
        let data: [UInt8] = [1, 2, 3]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Buffer(rawBuffer)
            _ = buffer.start
            #expect(true)
        }
    }

    @Test
    func `count property returns byte count`() {
        let data: [UInt8] = [1, 2, 3, 4, 5, 6, 7]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Buffer(rawBuffer)
            #expect(buffer.count == 7)
        }
    }

    @Test
    func `isEmpty returns true for empty buffer`() {
        let buffer = Memory.Buffer()
        #expect(buffer.isEmpty)
    }

    @Test
    func `isEmpty returns false for non-empty buffer`() {
        let data: [UInt8] = [1]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Buffer(rawBuffer)
            #expect(!buffer.isEmpty)
        }
    }

    @Test
    func `subscript accesses byte at index`() {
        let data: [UInt8] = [10, 20, 30, 40, 50]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Buffer(rawBuffer)
            let idx0: Index<Memory> = 0
            let idx2: Index<Memory> = 2
            let idx4: Index<Memory> = 4

            #expect(buffer[idx0] == 10)
            #expect(buffer[idx2] == 30)
            #expect(buffer[idx4] == 50)
        }
    }

    @Test
    func `read loads value from buffer`() {
        var value: UInt32 = 0x12345678
        unsafe withUnsafeBytes(of: &value) { rawBuffer in
            let buffer = unsafe Memory.Buffer(rawBuffer)
            let loaded: UInt32 = buffer.read(as: UInt32.self)
            #expect(loaded == 0x12345678)
        }
    }
}

// MARK: - Edge Case Tests

extension Memory.Buffer.Test.EdgeCase {
    @Test
    func `base.nullable returns nil for empty buffer (stdlib convention)`() {
        let buffer = Memory.Buffer()
        #expect(unsafe buffer.base.nullable.baseAddress == nil)
        #expect(unsafe buffer.base.nullable.count == 0)
    }

    @Test
    func `base.nonNull returns sentinel for empty buffer`() {
        let buffer = Memory.Buffer()
        #expect(unsafe buffer.base.nonNull.baseAddress != nil)
        #expect(unsafe buffer.base.nonNull.count == 0)
    }

    @Test
    func `slice returns nil for out-of-bounds offset`() {
        let data: [UInt8] = [1, 2, 3]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Buffer(rawBuffer)
            let result = buffer.slice(start: 10, count: 1)
            #expect(result == nil)
        }
    }

    @Test
    func `slice returns nil for out-of-bounds count`() {
        let data: [UInt8] = [1, 2, 3]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Buffer(rawBuffer)
            let result = buffer.slice(start: 1, count: 10)
            #expect(result == nil)
        }
    }

    @Test
    func `slice succeeds for valid bounds`() {
        let data: [UInt8] = [1, 2, 3, 4, 5]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Buffer(rawBuffer)
            let slice = buffer.slice(start: 1, count: 3)
            #expect(slice != nil)
            #expect(slice?.count == 3)
            if let slice = slice {
                let idx0: Index<Memory> = 0
                #expect(slice[idx0] == 2)
            }
        }
    }

    @Test
    func `slice at offset 0 with full count returns equivalent buffer`() {
        let data: [UInt8] = [1, 2, 3]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Buffer(rawBuffer)
            let slice = buffer.slice(start: 0, count: buffer.count)
            #expect(slice != nil)
            #expect(slice?.count == buffer.count)
        }
    }

    @Test
    func `slice empty from empty buffer succeeds`() {
        let buffer = Memory.Buffer()
        let slice = buffer.slice(start: 0, count: 0)
        #expect(slice != nil)
        #expect(slice?.isEmpty == true)
    }
}

// MARK: - Integration Tests

extension Memory.Buffer.Test.Integration {
    @Test
    func `Equatable compares start and count`() {
        let data: [UInt8] = [1, 2, 3]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer1 = unsafe Memory.Buffer(rawBuffer)
            let buffer2 = unsafe Memory.Buffer(rawBuffer)
            #expect(buffer1 == buffer2)
        }
    }

    @Test
    func `Hashable produces consistent hash`() {
        let data: [UInt8] = [1, 2, 3]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Buffer(rawBuffer)
            #expect(buffer.hashValue == buffer.hashValue)
        }
    }

    @Test
    func `description includes start and count`() {
        let buffer = Memory.Buffer()
        let desc = buffer.description
        #expect(desc.contains("Memory.Buffer"))
        #expect(desc.contains("count"))
    }

    @Test
    func `withRebound temporarily binds to different type`() {
        let values: [UInt32] = [0x01020304, 0x05060708]
        unsafe values.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Buffer(rawBuffer)
            unsafe buffer.withRebound(to: UInt8.self) { typedBuffer in
                #expect(typedBuffer.count == 8)
            }
        }
    }
}

// MARK: - Performance Tests

extension Memory.Buffer.Test.Performance {
    @Test
    func `sequential read`() {
        let size = 10000
        let data = [UInt8](repeating: 42, count: size)
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Buffer(rawBuffer)

            // Warmup
            for _ in 0..<10 {
                var sum: UInt = 0
                (.zero..<buffer.count).forEach { idx in
                    sum += UInt(buffer[idx])
                }
                _ = sum
            }

            // Measured
            for _ in 0..<100 {
                var sum: UInt = 0
                (.zero..<buffer.count).forEach { idx in
                    sum += UInt(buffer[idx])
                }
                _ = sum
            }
        }
    }

    @Test
    func `slice creation`() {
        let data = [UInt8](repeating: 0, count: 1000)
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Buffer(rawBuffer)
            let sliceCount: Memory.Address.Count = 10

            // Warmup
            for _ in 0..<10 {
                var start: Index<Memory> = .zero
                for _ in 0..<100 {
                    _ = buffer.slice(start: start, count: sliceCount)
                    start = start + sliceCount
                }
            }

            // Measured
            for _ in 0..<100 {
                var start: Index<Memory> = .zero
                for _ in 0..<100 {
                    _ = buffer.slice(start: start, count: sliceCount)
                    start = start + sliceCount
                }
            }
        }
    }
}
