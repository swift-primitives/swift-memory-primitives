import Testing

@testable import Memory_Primitives

extension Memory.Shift {
    @Suite
    struct Tests {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

extension Memory.Shift.Tests.Unit {
    @Test
    func `magnitude computes the power of two within carrier width`() throws {
        #expect(Memory.Shift.zero.magnitude(as: UInt8.self) == 1)
        #expect(Memory.Shift.three.magnitude(as: UInt8.self) == 8)
        #expect(Memory.Shift.twelve.magnitude(as: UInt64.self) == 4096)
    }

    @Test
    func `mask computes the low-bit mask within carrier width`() throws {
        #expect(Memory.Shift.zero.mask(as: UInt8.self) == 0)
        #expect(Memory.Shift.three.mask(as: UInt8.self) == 7)
        #expect(Memory.Shift.twelve.mask(as: UInt64.self) == 4095)
    }

    @Test
    func `validated accepts a shift below the carrier width`() throws {
        let shift = try Memory.Shift(7)
        _ = try shift.validated(for: UInt8.self)
        _ = try shift.validated(for: UInt64.self)
    }

    @Test
    func `validated rejects a shift at or above the carrier width`() throws {
        let atWidth = try Memory.Shift(8)
        #expect(throws: Memory.Shift.Error.self) {
            _ = try atWidth.validated(for: UInt8.self)
        }

        let wide = try Memory.Shift(63)
        #expect(throws: Memory.Shift.Error.self) {
            _ = try wide.validated(for: UInt32.self)
        }
        _ = try wide.validated(for: UInt64.self)
    }
}

extension Memory.Shift.Tests.`Edge Case` {
    @Test
    func `magnitude at the carrier-width boundary succeeds`() throws {
        let boundary = try Memory.Shift(7)
        #expect(boundary.magnitude(as: UInt8.self) == 128)
        #expect(boundary.mask(as: UInt8.self) == 127)

        let top = try Memory.Shift(63)
        #expect(top.magnitude(as: UInt64.self) == (1 << 63))
        #expect(top.mask(as: UInt64.self) == UInt64.max >> 1)
    }

    @Test
    func `over-width magnitude traps instead of silently producing zero`() async throws {
        await #expect(processExitsWith: .failure) {
            let shift = try Memory.Shift(8)
            _ = shift.magnitude(as: UInt8.self)
        }
    }

    @Test
    func `over-width mask traps instead of silently producing all ones`() async throws {
        await #expect(processExitsWith: .failure) {
            let shift = try Memory.Shift(32)
            _ = shift.mask(as: UInt32.self)
        }
    }
}
