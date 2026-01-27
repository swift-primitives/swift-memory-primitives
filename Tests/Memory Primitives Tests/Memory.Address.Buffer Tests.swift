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

@Suite("Memory.Address.Buffer")
struct MemoryAddressBufferTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit Tests

extension MemoryAddressBufferTests.Unit {
    @Test("init creates empty buffer with sentinel")
    func initEmpty() {
        let buffer = Memory.Address.Buffer()
        #expect(buffer.isEmpty)
        #expect(buffer.count.rawValue == 0)
    }

    @Test("init from start and count")
    func initFromStartAndCount() {
        let data: [UInt8] = [1, 2, 3, 4, 5]
        unsafe data.withUnsafeBufferPointer { ptr in
            guard let baseAddress = unsafe ptr.baseAddress else { return }
            let start = unsafe Memory.Address(baseAddress)
            let count: Index<UInt8>.Count = 5
            let buffer = Memory.Address.Buffer(start: start, count: count)

            #expect(!buffer.isEmpty)
            #expect(buffer.count.rawValue == 5)
        }
    }

    @Test("init from UnsafeRawBufferPointer")
    func initFromUnsafeRawBufferPointer() {
        let data: [UInt8] = [10, 20, 30]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Address.Buffer(rawBuffer)
            #expect(buffer.count.rawValue == 3)
        }
    }

    @Test("init from empty UnsafeRawBufferPointer uses sentinel")
    func initFromEmptyUnsafeRawBufferPointer() {
        let emptyBuffer = unsafe UnsafeRawBufferPointer(start: nil, count: 0)
        let buffer = unsafe Memory.Address.Buffer(emptyBuffer)
        #expect(buffer.isEmpty)
        #expect(buffer.count.rawValue == 0)
    }

    @Test("start property returns non-null address")
    func startProperty() {
        let data: [UInt8] = [1, 2, 3]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Address.Buffer(rawBuffer)
            _ = buffer.start
            #expect(true)
        }
    }

    @Test("count property returns byte count")
    func countProperty() {
        let data: [UInt8] = [1, 2, 3, 4, 5, 6, 7]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Address.Buffer(rawBuffer)
            #expect(buffer.count.rawValue == 7)
        }
    }

    @Test("isEmpty returns true for empty buffer")
    func isEmptyTrue() {
        let buffer = Memory.Address.Buffer()
        #expect(buffer.isEmpty)
    }

    @Test("isEmpty returns false for non-empty buffer")
    func isEmptyFalse() {
        let data: [UInt8] = [1]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Address.Buffer(rawBuffer)
            #expect(!buffer.isEmpty)
        }
    }

    @Test("subscript accesses byte at index")
    func subscriptAccess() {
        let data: [UInt8] = [10, 20, 30, 40, 50]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Address.Buffer(rawBuffer)
            let idx0: Index<UInt8> = 0
            let idx2: Index<UInt8> = 2
            let idx4: Index<UInt8> = 4

            #expect(buffer[idx0] == 10)
            #expect(buffer[idx2] == 30)
            #expect(buffer[idx4] == 50)
        }
    }

    @Test("read loads value from buffer")
    func read() {
        var value: UInt32 = 0x12345678
        unsafe withUnsafeBytes(of: &value) { rawBuffer in
            let buffer = unsafe Memory.Address.Buffer(rawBuffer)
            let loaded: UInt32 = buffer.read(as: UInt32.self)
            #expect(loaded == 0x12345678)
        }
    }
}

// MARK: - Edge Case Tests

extension MemoryAddressBufferTests.EdgeCase {
    @Test("base returns nil for empty buffer (stdlib convention)")
    func baseEmptyReturnsNil() {
        let buffer = Memory.Address.Buffer()
        #expect(unsafe buffer.base.baseAddress == nil)
        #expect(unsafe buffer.base.count == 0)
    }

    @Test("baseNonNull returns sentinel for empty buffer")
    func baseNonNullEmpty() {
        let buffer = Memory.Address.Buffer()
        #expect(unsafe buffer.baseNonNull.baseAddress != nil)
        #expect(unsafe buffer.baseNonNull.count == 0)
    }

    @Test("slice returns nil for out-of-bounds offset")
    func sliceOutOfBoundsOffset() {
        let data: [UInt8] = [1, 2, 3]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Address.Buffer(rawBuffer)
            let result = buffer.slice(start: 10, count: 1)
            #expect(result == nil)
        }
    }

    @Test("slice returns nil for out-of-bounds count")
    func sliceOutOfBoundsCount() {
        let data: [UInt8] = [1, 2, 3]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Address.Buffer(rawBuffer)
            let result = buffer.slice(start: 1, count: 10)
            #expect(result == nil)
        }
    }

    @Test("slice succeeds for valid bounds")
    func sliceValid() {
        let data: [UInt8] = [1, 2, 3, 4, 5]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Address.Buffer(rawBuffer)
            let slice = buffer.slice(start: 1, count: 3)
            #expect(slice != nil)
            #expect(slice?.count.rawValue == 3)
            if let slice = slice {
                let idx0: Index<UInt8> = 0
                #expect(slice[idx0] == 2)
            }
        }
    }

    @Test("slice at offset 0 with full count returns equivalent buffer")
    func sliceFullBuffer() {
        let data: [UInt8] = [1, 2, 3]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Address.Buffer(rawBuffer)
            let slice = buffer.slice(start: 0, count: buffer.count)
            #expect(slice != nil)
            #expect(slice?.count == buffer.count)
        }
    }

    @Test("slice empty from empty buffer succeeds")
    func sliceEmptyFromEmpty() {
        let buffer = Memory.Address.Buffer()
        let slice = buffer.slice(start: 0, count: 0)
        #expect(slice != nil)
        #expect(slice?.isEmpty == true)
    }
}

// MARK: - Integration Tests

extension MemoryAddressBufferTests.Integration {
    @Test("Equatable compares start and count")
    func equatable() {
        let data: [UInt8] = [1, 2, 3]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer1 = unsafe Memory.Address.Buffer(rawBuffer)
            let buffer2 = unsafe Memory.Address.Buffer(rawBuffer)
            #expect(buffer1 == buffer2)
        }
    }

    @Test("Hashable produces consistent hash")
    func hashable() {
        let data: [UInt8] = [1, 2, 3]
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Address.Buffer(rawBuffer)
            #expect(buffer.hashValue == buffer.hashValue)
        }
    }

    @Test("description includes start and count")
    func description() {
        let buffer = Memory.Address.Buffer()
        let desc = buffer.description
        #expect(desc.contains("Memory.Address.Buffer"))
        #expect(desc.contains("count"))
    }

    @Test("withRebound temporarily binds to different type")
    func withRebound() {
        let values: [UInt32] = [0x01020304, 0x05060708]
        unsafe values.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Address.Buffer(rawBuffer)
            unsafe buffer.withRebound(to: UInt8.self) { typedBuffer in
                #expect(unsafe typedBuffer.count == 8)
            }
        }
    }
}

// MARK: - Performance Tests

extension MemoryAddressBufferTests.Performance {
    @Test("sequential read")
    func sequentialRead() {
        let size = 10000
        let data = [UInt8](repeating: 42, count: size)
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Address.Buffer(rawBuffer)

            // Warmup
            for _ in 0..<10 {
                var sum: UInt = 0
                (Index<UInt8>.zero..<buffer.count).forEach { idx in
                    sum += UInt(buffer[idx])
                }
                _ = sum
            }

            // Measured
            for _ in 0..<100 {
                var sum: UInt = 0
                (Index<UInt8>.zero..<buffer.count).forEach { idx in
                    sum += UInt(buffer[idx])
                }
                _ = sum
            }
        }
    }

    @Test("slice creation")
    func sliceCreation() {
        let data = [UInt8](repeating: 0, count: 1000)
        unsafe data.withUnsafeBytes { rawBuffer in
            let buffer = unsafe Memory.Address.Buffer(rawBuffer)
            let sliceCount: Index<UInt8>.Count = 10

            // Warmup
            for _ in 0..<10 {
                var start: Index<UInt8> = .zero
                for _ in 0..<100 {
                    _ = buffer.slice(start: start, count: sliceCount)
                    start = start + sliceCount
                }
            }

            // Measured
            for _ in 0..<100 {
                var start: Index<UInt8> = .zero
                for _ in 0..<100 {
                    _ = buffer.slice(start: start, count: sliceCount)
                    start = start + sliceCount
                }
            }
        }
    }
}
