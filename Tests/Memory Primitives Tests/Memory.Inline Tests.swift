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

// MARK: - Test Suite

// Note: Memory.Inline<Element, let capacity: Int> is generic, so @Suite
// cannot nest inside its extension (static stored properties not supported
// in generic types). Use a top-level test struct instead.

@Suite("Memory.Inline")
struct MemoryInlineTest {
    @Suite struct Unit {}
}

// MARK: - Size Verification

extension MemoryInlineTest.Unit {
    @Test
    func `size matches single element`() {
        let inlineSize = MemoryLayout<Memory.Inline<Int, 1>>.size
        let intSize = MemoryLayout<Int>.size
        #expect(inlineSize == intSize)
        #expect(inlineSize == 8)
    }

    @Test
    func `stride matches single element`() {
        let inlineStride = MemoryLayout<Memory.Inline<Int, 1>>.stride
        let intStride = MemoryLayout<Int>.stride
        #expect(inlineStride == intStride)
        #expect(inlineStride == 8)
    }

    @Test
    func `size matches element stride times capacity`() {
        let inlineSize = MemoryLayout<Memory.Inline<Int, 4>>.size
        let expected = MemoryLayout<Int>.stride * 4
        #expect(inlineSize == expected)
        #expect(inlineSize == 32)
    }
}

// MARK: - Pointer Initialize / Read / Deinitialize

extension MemoryInlineTest.Unit {
    @Test
    func `pointer initialize read deinitialize cycle`() {
        var inline = Memory.Inline<Int, 1>()
        unsafe inline.pointer(at: 0).initialize(to: 42)
        let value = unsafe inline.pointer(at: 0).pointee
        #expect(value == 42)
        unsafe inline.pointer(at: 0).deinitialize(count: 1)
    }

    @Test
    func `pointer overwrite existing value`() {
        var inline = Memory.Inline<Int, 1>()
        unsafe inline.pointer(at: 0).initialize(to: 10)
        unsafe inline.pointer(at: 0).deinitialize(count: 1)
        unsafe inline.pointer(at: 0).initialize(to: 20)
        #expect(unsafe inline.pointer(at: 0).pointee == 20)
        unsafe inline.pointer(at: 0).deinitialize(count: 1)
    }
}

// MARK: - Multi-Element Indexed Access

extension MemoryInlineTest.Unit {
    @Test
    func `multi element indexed access`() {
        var inline = Memory.Inline<Int, 4>()

        for i in 0..<4 {
            unsafe inline.pointer(at: i).initialize(to: (i + 1) * 10)
        }

        #expect(unsafe inline.pointer(at: 0).pointee == 10)
        #expect(unsafe inline.pointer(at: 1).pointee == 20)
        #expect(unsafe inline.pointer(at: 2).pointee == 30)
        #expect(unsafe inline.pointer(at: 3).pointee == 40)

        for i in 0..<4 {
            unsafe inline.pointer(at: i).deinitialize(count: 1)
        }
    }

    @Test
    func `immutable pointer reads initialized value`() {
        var inline = Memory.Inline<Int, 4>()
        unsafe inline.pointer(at: 2).initialize(to: 99)
        let ptr: UnsafePointer<Int> = unsafe inline.pointer(at: 2)
        #expect(unsafe ptr.pointee == 99)
        unsafe inline.pointer(at: 2).deinitialize(count: 1)
    }
}

// MARK: - Properties

extension MemoryInlineTest.Unit {
    @Test
    func `elementStride matches MemoryLayout`() {
        let inline = Memory.Inline<Int, 1>()
        #expect(inline.elementStride == MemoryLayout<Int>.stride)
        #expect(inline.elementStride == 8)
    }

    @Test
    func `elementStride for UInt8`() {
        let inline = Memory.Inline<UInt8, 16>()
        #expect(inline.elementStride == 1)
    }

    @Test
    func `size for UInt8 x 16`() {
        #expect(MemoryLayout<Memory.Inline<UInt8, 16>>.size == 16)
    }
}
