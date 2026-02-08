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

extension Memory.Pool {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
        @Suite struct Integration {}
        @Suite(.serialized) struct Performance {}
    }
}

// MARK: - Unit Tests

extension Memory.Pool.Test.Unit {
    @Test
    func `init creates pool with specified capacity`() throws {
        let pool = try Memory.Pool(slotSize: 64, slotAlignment: .doubleWord, capacity: 16)
        #expect(pool.capacity == 16)
        #expect(pool.allocated == 0)
        #expect(pool.available == 16)
        #expect(pool.slotStride == 64)
        #expect(!pool.isExhausted == true)
    }

    @Test
    func `allocate returns valid pointer`() throws {
        var pool = try Memory.Pool(slotSize: 64, slotAlignment: .doubleWord, capacity: 16)
        let pointer = try unsafe pool.allocate()
        #expect(unsafe pointer != UnsafeMutableRawPointer(bitPattern: 0))
    }

    @Test
    func `allocate updates count`() throws {
        var pool = try Memory.Pool(slotSize: 64, slotAlignment: .doubleWord, capacity: 16)
        _ = try unsafe pool.allocate()
        #expect(pool.allocated == 1)
        #expect(pool.available == 15)
    }

    @Test
    func `deallocate returns slot to pool`() throws {
        var pool = try Memory.Pool(slotSize: 64, slotAlignment: .doubleWord, capacity: 16)
        let pointer = try unsafe pool.allocate()
        try unsafe pool.deallocate(pointer)
        #expect(pool.allocated == 0)
        #expect(pool.available == 16)
    }

    @Test
    func `capacity property returns total capacity`() throws {
        let pool = try Memory.Pool(slotSize: 32, slotAlignment: .doubleWord, capacity: 100)
        #expect(pool.capacity == 100)
    }

    @Test
    func `slotStride reflects alignment padding`() throws {
        // slotSize 10 with alignment 8 → stride 16
        let pool = try Memory.Pool(slotSize: 10, slotAlignment: .doubleWord, capacity: 4)
        #expect(pool.slotStride == 16)
    }

    @Test
    func `slotStride matches slot size when already aligned`() throws {
        let pool = try Memory.Pool(slotSize: 64, slotAlignment: .doubleWord, capacity: 4)
        #expect(pool.slotStride == 64)
    }

    @Test
    func `reset restores full availability`() throws {
        var pool = try Memory.Pool(slotSize: 64, slotAlignment: .doubleWord, capacity: 8)
        for _ in 0..<8 {
            _ = try unsafe pool.allocate()
        }
        #expect(pool.available == 0)

        pool.reset()
        #expect(pool.allocated == 0)
        #expect(pool.available == 8)
        #expect(!pool.isExhausted == true)
    }

    @Test
    func `pointer(at:) returns correct slot address`() throws {
        var pool = try Memory.Pool(slotSize: 64, slotAlignment: .doubleWord, capacity: 4)

        // Allocate first slot — should match pointer(at: 0)
        let first = try unsafe pool.allocate()
        let expected = unsafe pool.pointer(at: 0)
        #expect(unsafe first == expected)
    }

    @Test
    func `slotIndex(for:) returns correct index`() throws {
        var pool = try Memory.Pool(slotSize: 64, slotAlignment: .doubleWord, capacity: 4)
        let pointer = try unsafe pool.allocate()
        let index = unsafe pool.slotIndex(for: pointer)
        #expect(index == 0)
    }
}

// MARK: - Edge Case Tests

extension Memory.Pool.Test.EdgeCase {
    @Test
    func `init with capacity 1 succeeds`() throws {
        var pool = try Memory.Pool(slotSize: 8, slotAlignment: .doubleWord, capacity: 1)
        let pointer = try unsafe pool.allocate()
        #expect(pool.isExhausted == true)
        try unsafe pool.deallocate(pointer)
        #expect(!pool.isExhausted == true)
    }

    @Test
    func `init with zero capacity throws`() {
        #expect(throws: Memory.Pool.Error.invalidCapacity) {
            _ = try Memory.Pool(slotSize: 8, slotAlignment: .doubleWord, capacity: 0)
        }
    }

    @Test
    func `init with too-small slot size throws`() {
        #expect(throws: Memory.Pool.Error.self) {
            _ = try Memory.Pool(slotSize: 2, slotAlignment: .halfWord, capacity: 4)
        }
    }

    @Test
    func `allocate throws when exhausted`() throws {
        var pool = try Memory.Pool(slotSize: 8, slotAlignment: .doubleWord, capacity: 2)
        _ = try unsafe pool.allocate()
        _ = try unsafe pool.allocate()
        #expect(throws: Memory.Pool.Error.exhausted(capacity: 2)) {
            _ = try pool.allocate()
        }
    }

    @Test
    func `deallocate detects double free`() throws {
        var pool = try Memory.Pool(slotSize: 8, slotAlignment: .doubleWord, capacity: 4)
        let pointer = try unsafe pool.allocate()
        try unsafe pool.deallocate(pointer)
        #expect(throws: Memory.Pool.Error.doubleFree) {
            try pool.deallocate(pointer)
        }
    }

    @Test
    func `deallocate detects foreign pointer`() throws {
        var pool = try Memory.Pool(slotSize: 8, slotAlignment: .doubleWord, capacity: 4)
        let foreign = UnsafeMutableRawPointer.allocate(byteCount: 8, alignment: 8)
        defer { unsafe foreign.deallocate() }
        #expect(throws: Memory.Pool.Error.foreignPointer) {
            try pool.deallocate(foreign)
        }
    }

    @Test
    func `deallocate detects misaligned pointer within pool range`() throws {
        var pool = try Memory.Pool(slotSize: 16, slotAlignment: .doubleWord, capacity: 4)
        let valid = try unsafe pool.allocate()
        // Offset by 1 byte — still in range but not slot-aligned
        let misaligned = unsafe valid.advanced(by: 1)
        #expect(throws: Memory.Pool.Error.foreignPointer) {
            try pool.deallocate(misaligned)
        }
    }

    @Test
    func `slotIndex returns nil for foreign pointer`() throws {
        let pool = try Memory.Pool(slotSize: 8, slotAlignment: .doubleWord, capacity: 4)
        let foreign = UnsafeMutableRawPointer.allocate(byteCount: 8, alignment: 8)
        defer { unsafe foreign.deallocate() }
        unsafe #expect(pool.slotIndex(for: foreign) == nil)
    }

    @Test
    func `allocate all then deallocate all succeeds`() throws {
        var pool = try Memory.Pool(slotSize: 8, slotAlignment: .doubleWord, capacity: 4)
        var pointers: [UnsafeMutableRawPointer] = unsafe []
        for _ in 0..<4 {
            try unsafe pointers.append(pool.allocate())
        }
        #expect(pool.isExhausted == true)

        for unsafe p in unsafe pointers {
            try unsafe pool.deallocate(p)
        }
        #expect(pool.allocated == 0)
        #expect(pool.available == 4)
    }
}

// MARK: - Integration Tests

extension Memory.Pool.Test.Integration {
    @Test
    func `allocated memory is usable for typed storage`() throws {
        var pool = try Memory.Pool(
            slotSize: Memory.Address.Count(Cardinal(UInt(MemoryLayout<Int>.stride))),
            slotAlignment: .doubleWord,
            capacity: 8
        )
        let pointer = try unsafe pool.allocate()
        let typed = unsafe pointer.assumingMemoryBound(to: Int.self)
        unsafe typed.initialize(to: 42)
        #expect(unsafe typed.pointee == 42)
        _ = unsafe typed.move()
        try unsafe pool.deallocate(pointer)
    }

    @Test
    func `multiple typed allocations with different values`() throws {
        var pool = try Memory.Pool(
            slotSize: Memory.Address.Count(Cardinal(UInt(MemoryLayout<Int>.stride))),
            slotAlignment: .doubleWord,
            capacity: 4
        )

        let p0 = try unsafe pool.allocate()
        let p1 = try unsafe pool.allocate()
        let p2 = try unsafe pool.allocate()

        let t0 = unsafe p0.assumingMemoryBound(to: Int.self)
        let t1 = unsafe p1.assumingMemoryBound(to: Int.self)
        let t2 = unsafe p2.assumingMemoryBound(to: Int.self)

        unsafe t0.initialize(to: 100)
        unsafe t1.initialize(to: 200)
        unsafe t2.initialize(to: 300)

        #expect(unsafe t0.pointee == 100)
        #expect(unsafe t1.pointee == 200)
        #expect(unsafe t2.pointee == 300)

        _ = unsafe t0.move()
        _ = unsafe t1.move()
        _ = unsafe t2.move()

        try unsafe pool.deallocate(p0)
        try unsafe pool.deallocate(p1)
        try unsafe pool.deallocate(p2)
    }

    @Test
    func `deallocated slot is reused on next allocate`() throws {
        var pool = try Memory.Pool(slotSize: 64, slotAlignment: .doubleWord, capacity: 2)

        let first = try unsafe pool.allocate()
        _ = try unsafe pool.allocate()
        #expect(pool.isExhausted == true)

        // Free the first slot
        try unsafe pool.deallocate(first)
        #expect(pool.available == 1)

        // Next allocation should reuse that slot
        let reused = try unsafe pool.allocate()
        #expect(unsafe reused == first)
    }

    @Test
    func `LIFO reuse: last freed is first allocated`() throws {
        var pool = try Memory.Pool(slotSize: 64, slotAlignment: .doubleWord, capacity: 4)

        let a = try unsafe pool.allocate()
        let b = try unsafe pool.allocate()

        // Free b then a — next allocate should return a (LIFO)
        try unsafe pool.deallocate(b)
        try unsafe pool.deallocate(a)

        let first = try unsafe pool.allocate()
        #expect(unsafe first == a)

        let next = try unsafe pool.allocate()
        #expect(unsafe next == b)
    }

    @Test
    func `reset allows full reuse cycle`() throws {
        var pool = try Memory.Pool(
            slotSize: Memory.Address.Count(Cardinal(UInt(MemoryLayout<Int>.stride))),
            slotAlignment: .doubleWord,
            capacity: 4
        )

        // Exhaust the pool
        for _ in 0..<4 {
            let p = try unsafe pool.allocate()
            let t = unsafe p.assumingMemoryBound(to: Int.self)
            unsafe t.initialize(to: 99)
            // Note: caller must deinitialize before reset
            _ = unsafe t.move()
        }
        #expect(pool.isExhausted == true)

        pool.reset()

        // Pool is fully available again
        #expect(pool.available == 4)
        let pointer = try unsafe pool.allocate()
        #expect(unsafe pointer != UnsafeMutableRawPointer(bitPattern: 0))
    }

    @Test
    func `struct storage roundtrip`() throws {
        struct Point {
            var x: Double
            var y: Double
        }

        var pool = try Memory.Pool(
            slotSize: Memory.Address.Count(Cardinal(UInt(MemoryLayout<Point>.stride))),
            slotAlignment: .doubleWord,
            capacity: 8
        )

        let pointer = try unsafe pool.allocate()
        let typed = unsafe pointer.assumingMemoryBound(to: Point.self)
        unsafe typed.initialize(to: Point(x: 1.5, y: 2.5))
        #expect(unsafe typed.pointee.x == 1.5)
        #expect(unsafe typed.pointee.y == 2.5)
        _ = unsafe typed.move()
        try unsafe pool.deallocate(pointer)
    }
}

// MARK: - Performance Tests

extension Memory.Pool.Test.Performance {
    @Test
    func `many allocate-deallocate cycles`() throws {
        var pool = try Memory.Pool(slotSize: 64, slotAlignment: .doubleWord, capacity: 1024)

        // Warmup
        for _ in 0..<10 {
            for _ in 0..<1024 {
                let p = try unsafe pool.allocate()
                try unsafe pool.deallocate(p)
            }
        }

        // Measured
        for _ in 0..<100 {
            for _ in 0..<1024 {
                let p = try unsafe pool.allocate()
                try unsafe pool.deallocate(p)
            }
        }
    }

    @Test
    func `fill then drain`() throws {
        var pool = try Memory.Pool(slotSize: 64, slotAlignment: .doubleWord, capacity: 4096)
        var pointers: [UnsafeMutableRawPointer] = unsafe []
        unsafe pointers.reserveCapacity(4096)

        // Warmup
        for _ in 0..<10 {
            for _ in 0..<4096 {
                try unsafe pointers.append(pool.allocate())
            }
            for unsafe p in unsafe pointers {
                try unsafe pool.deallocate(p)
            }
            unsafe pointers.removeAll(keepingCapacity: true)
        }

        // Measured
        for _ in 0..<100 {
            for _ in 0..<4096 {
                try unsafe pointers.append(pool.allocate())
            }
            for unsafe p in unsafe pointers {
                try unsafe pool.deallocate(p)
            }
            unsafe pointers.removeAll(keepingCapacity: true)
        }
    }

    @Test
    func `allocate and reset cycle`() throws {
        var pool = try Memory.Pool(slotSize: 64, slotAlignment: .doubleWord, capacity: 1024)

        // Warmup
        for _ in 0..<10 {
            for _ in 0..<1024 {
                _ = try unsafe pool.allocate()
            }
            pool.reset()
        }

        // Measured
        for _ in 0..<100 {
            for _ in 0..<1024 {
                _ = try unsafe pool.allocate()
            }
            pool.reset()
        }
    }
}
