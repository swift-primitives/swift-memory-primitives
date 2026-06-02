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

import Memory_Primitives_Test_Support
import Testing

@testable import Memory_Primitives

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

// MARK: - Release-mode regression guard (Finding #12 narrow-shape watchflag)
//
// Permanent positive-assertion regression guard for the V11 narrow-shape
// compiler bug documented at swift-institute/Audits/borrow-pointer-
// storage-release-miscompile.md finding #12, archived in the experiment
// at swift-institute/Experiments/borrow-pointer-storage-release-miscompile
// V10/V11 (commit cee7a7a).
//
// The experiment's V11 reproducer — a non-generic ~Copyable container
// with a plain stored ~Copyable field accessed via `@inlinable`
// `withUnsafePointer(to: _storage)` returning the pointer past the
// closure — fails cross-module in release mode (divergent per-call
// borrow-local addresses, garbage dereferences). Memory.Inline's
// production shape (`@_rawLayout`-backed `_storage`, generic over
// Element, stride-advance arithmetic, precondition) does NOT exhibit
// the bug. The structural difference — most likely the compile-time-
// known `@_rawLayout` offset — protects the production path.
//
// This test asserts the protection holds. It is a positive guard:
// assertions should pass unchanged. If a future refactor migrates
// Memory.Inline toward the V11 shape (e.g., drops `@_rawLayout` or
// changes generic structure), or a future optimizer regression breaks
// the @_rawLayout discriminator, this test flips to failing and
// catches the regression before it ships.

extension MemoryInlineTest.Unit {
    @Test
    func `pointer(at:) returns stable addresses across repeated cross-module calls (finding #12 regression guard)`() {
        var inline = Memory.Inline<Int, 4>()
        for i in 0..<4 {
            unsafe inline.pointer(at: i).initialize(to: (i + 1) * 11)
        }

        let addrA1 = unsafe inline.pointer(at: 0)
        let addrA2 = unsafe inline.pointer(at: 0)
        let addrB1 = unsafe inline.pointer(at: 3)
        let addrB2 = unsafe inline.pointer(at: 3)

        #expect(addrA1 == addrA2)
        #expect(addrB1 == addrB2)
        #expect(unsafe addrA1.pointee == 11)
        #expect(unsafe addrA2.pointee == 11)
        #expect(unsafe addrB1.pointee == 44)
        #expect(unsafe addrB2.pointee == 44)

        for i in 0..<4 {
            unsafe inline.pointer(at: i).deinitialize(count: 1)
        }
    }
}
