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

extension Memory.Arena {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
        @Suite struct Integration {}
        @Suite(.serialized) struct Performance {}
    }
}

// MARK: - Unit Tests

extension Memory.Arena.Test.Unit {
    @Test("init creates arena with specified capacity")
    func initWithCapacity() {
        let capacity: Memory.Address.Count = 1024
        let arena = Memory.Arena(capacity: capacity)
        #expect(arena.capacity.rawValue == 1024)
        #expect(arena.allocated.rawValue == 0)
        #expect(arena.remaining.rawValue == 1024)
    }

    @Test("allocate returns address for valid request")
    func allocateValid() {
        let capacity: Memory.Address.Count = 1024
        var arena = Memory.Arena(capacity: capacity)
        let count: Memory.Address.Count = 100
        let alignment: Memory.Address.Count = 8
        let address = arena.allocate(count: count, alignment: alignment)
        #expect(address != nil)
    }

    @Test("allocate updates offset")
    func allocateUpdatesOffset() {
        let capacity: Memory.Address.Count = 1024
        var arena = Memory.Arena(capacity: capacity)
        let count: Memory.Address.Count = 100
        let alignment: Memory.Address.Count = 8
        _ = arena.allocate(count: count, alignment: alignment)
        #expect(arena.allocated.rawValue >= 100)
    }

    @Test("capacity property returns total capacity")
    func capacityProperty() {
        let capacity: Memory.Address.Count = 2048
        let arena = Memory.Arena(capacity: capacity)
        #expect(arena.capacity.rawValue == 2048)
    }

    @Test("remaining decreases after allocation")
    func remainingDecreases() {
        let capacity: Memory.Address.Count = 1024
        var arena = Memory.Arena(capacity: capacity)
        let initialRemaining = arena.remaining.rawValue

        let count: Memory.Address.Count = 256
        let alignment: Memory.Address.Count = 8
        _ = arena.allocate(count: count, alignment: alignment)

        #expect(arena.remaining.rawValue < initialRemaining)
    }

    @Test("reset restores full capacity")
    func reset() {
        let capacity: Memory.Address.Count = 1024
        var arena = Memory.Arena(capacity: capacity)

        let count: Memory.Address.Count = 500
        let alignment: Memory.Address.Count = 8
        _ = arena.allocate(count: count, alignment: alignment)
        #expect(arena.remaining.rawValue < 1024)

        arena.reset()
        #expect(arena.allocated.rawValue == 0)
        #expect(arena.remaining.rawValue == 1024)
    }
}

// MARK: - Edge Case Tests

extension Memory.Arena.Test.EdgeCase {
    @Test("allocate returns nil when insufficient space")
    func allocateInsufficientSpace() {
        let capacity: Memory.Address.Count = 100
        var arena = Memory.Arena(capacity: capacity)
        let count: Memory.Address.Count = 200
        let alignment: Memory.Address.Count = 8
        let address = arena.allocate(count: count, alignment: alignment)
        #expect(address == nil)
    }

    @Test("allocate respects alignment")
    func allocateAlignment() {
        let capacity: Memory.Address.Count = 1024
        var arena = Memory.Arena(capacity: capacity)

        // First allocation of 1 byte
        let count1: Memory.Address.Count = 1
        let alignment1: Memory.Address.Count = 1
        _ = arena.allocate(count: count1, alignment: alignment1)

        // Second allocation with 16-byte alignment
        let count2: Memory.Address.Count = 32
        let alignment2: Memory.Address.Count = 16
        let address = arena.allocate(count: count2, alignment: alignment2)

        #expect(address != nil)
    }

    @Test("multiple allocations succeed until exhausted")
    func multipleAllocations() {
        let capacity: Memory.Address.Count = 256
        var arena = Memory.Arena(capacity: capacity)
        var allocations: [Memory.Address] = []

        let count: Memory.Address.Count = 32
        let alignment: Memory.Address.Count = 8
        while let address = arena.allocate(count: count, alignment: alignment) {
            allocations.append(address)
        }

        #expect(allocations.count >= 4)
    }

    @Test("allocate zero bytes succeeds")
    func allocateZeroBytes() {
        let capacity: Memory.Address.Count = 100
        var arena = Memory.Arena(capacity: capacity)
        let count: Memory.Address.Count = 0
        let alignment: Memory.Address.Count = 8
        let address = arena.allocate(count: count, alignment: alignment)
        #expect(address != nil)
    }

    @Test("allocate exactly capacity succeeds")
    func allocateExactCapacity() {
        let capacity: Memory.Address.Count = 64
        var arena = Memory.Arena(capacity: capacity)
        let count: Memory.Address.Count = 64
        let alignment: Memory.Address.Count = 1
        let address = arena.allocate(count: count, alignment: alignment)
        #expect(address != nil)
    }

    @Test("allocate after exact capacity returns nil")
    func allocateAfterExact() {
        let capacity: Memory.Address.Count = 64
        var arena = Memory.Arena(capacity: capacity)
        let count: Memory.Address.Count = 64
        let alignment: Memory.Address.Count = 1
        _ = arena.allocate(count: count, alignment: alignment)

        let oneMore: Memory.Address.Count = 1
        let second = arena.allocate(count: oneMore, alignment: alignment)
        #expect(second == nil)
    }
}

// MARK: - Integration Tests

extension Memory.Arena.Test.Integration {
    @Test("allocated memory is usable")
    func allocatedMemoryUsable() {
        let capacity: Memory.Address.Count = 1024
        var arena = Memory.Arena(capacity: capacity)
        let count: Memory.Address.Count = 8
        let alignment: Memory.Address.Count = 8
        guard let address = arena.allocate(count: count, alignment: alignment) else {
            Issue.record("Allocation failed")
            return
        }

        // Use raw pointer for memory operations (addresses are positions, not capabilities)
        let ptr = unsafe UnsafeMutableRawPointer(address)
        unsafe ptr.storeBytes(of: 42, as: Int.self)
        let value: Int = unsafe ptr.load(as: Int.self)
        #expect(value == 42)
    }

    @Test("multiple typed allocations")
    func multipleTypedAllocations() {
        let capacity: Memory.Address.Count = 1024
        var arena = Memory.Arena(capacity: capacity)

        let intCount: Memory.Address.Count = 8
        let intAlign: Memory.Address.Count = 8
        guard let intAddr: Memory.Address = arena.allocate(count: intCount, alignment: intAlign) else {
            Issue.record("Int allocation failed")
            return
        }

        let doubleCount: Memory.Address.Count = 8
        let doubleAlign: Memory.Address.Count = 8
        guard let doubleAddr = arena.allocate(count: doubleCount, alignment: doubleAlign) else {
            Issue.record("Double allocation failed")
            return
        }

        // Use raw pointers for memory operations (addresses are positions, not capabilities)
        let intPtr = unsafe UnsafeMutableRawPointer(intAddr)
        let doublePtr = unsafe UnsafeMutableRawPointer(doubleAddr)

        unsafe intPtr.storeBytes(of: 123, as: Int.self)
        unsafe doublePtr.storeBytes(of: 3.14159, as: Double.self)

        #expect(unsafe intPtr.load(as: Int.self) == 123)
        #expect(unsafe doublePtr.load(as: Double.self) == 3.14159)
    }

    @Test("reset allows reuse")
    func resetAllowsReuse() {
        let capacity: Memory.Address.Count = 100
        var arena = Memory.Arena(capacity: capacity)

        let count: Memory.Address.Count = 32
        let alignment: Memory.Address.Count = 8
        while arena.allocate(count: count, alignment: alignment) != nil {}

        arena.reset()

        let address = arena.allocate(count: count, alignment: alignment)
        #expect(address != nil)
    }
}

// MARK: - Performance Tests

extension Memory.Arena.Test.Performance {
    @Test("many small allocations")
    func manySmallAllocations() {
        let capacity: Memory.Address.Count = 1048576
        let count: Memory.Address.Count = 64
        let alignment: Memory.Address.Count = 8

        // Warmup
        for _ in 0..<10 {
            var arena = Memory.Arena(capacity: capacity)
            for _ in 0..<10000 {
                _ = arena.allocate(count: count, alignment: alignment)
            }
        }

        // Measured
        for _ in 0..<100 {
            var arena = Memory.Arena(capacity: capacity)
            for _ in 0..<10000 {
                _ = arena.allocate(count: count, alignment: alignment)
            }
        }
    }

    @Test("allocate and reset cycle")
    func allocateResetCycle() {
        let capacity: Memory.Address.Count = 1024
        var arena = Memory.Arena(capacity: capacity)
        let count: Memory.Address.Count = 8
        let alignment: Memory.Address.Count = 8

        // Warmup
        for _ in 0..<10 {
            for _ in 0..<100 {
                _ = arena.allocate(count: count, alignment: alignment)
            }
            arena.reset()
        }

        // Measured
        for _ in 0..<100 {
            for _ in 0..<100 {
                _ = arena.allocate(count: count, alignment: alignment)
            }
            arena.reset()
        }
    }
}
