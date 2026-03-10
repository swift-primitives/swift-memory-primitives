import Testing
import Memory_Pool_Primitives
import Memory_Primitives_Test_Support

@Suite(.serialized)
struct `Memory.Pool - Performance` {

    // MARK: - Allocation Throughput

    @Test(.timed(iterations: 20, warmup: 3))
    func `allocate 10_000 slots`() throws {
        var pool = try Memory.Pool(
            slotSize: 64,
            slotAlignment: .`8`,
            capacity: 10_000
        )
        for _ in 0..<10_000 {
            _ = try pool.allocateSlot()
        }
    }

    @Test(.timed(iterations: 20, warmup: 3))
    func `allocate and deallocate 10_000 slots`() throws {
        var pool = try Memory.Pool(
            slotSize: 64,
            slotAlignment: .`8`,
            capacity: 10_000
        )

        // Fill
        var slots: [Index<Memory.Pool.Slot>] = []
        slots.reserveCapacity(10_000)
        for _ in 0..<10_000 {
            slots.append(try pool.allocateSlot())
        }

        // Drain
        for slot in slots {
            try pool.deallocate(at: slot)
        }
    }

    // MARK: - Free List Reuse

    @Test(.timed(iterations: 20, warmup: 3))
    func `alternating allocate-deallocate 10_000 cycles`() throws {
        var pool = try Memory.Pool(
            slotSize: 64,
            slotAlignment: .`8`,
            capacity: 100
        )

        // Stress the free list with rapid alloc/dealloc cycling
        for _ in 0..<10_000 {
            let slot = try pool.allocateSlot()
            try pool.deallocate(at: slot)
        }
    }

    // MARK: - Pointer-Based Allocation

    @Test(.timed(iterations: 20, warmup: 3))
    func `pointer allocate 10_000 slots`() throws {
        var pool = try Memory.Pool(
            slotSize: 128,
            slotAlignment: .`16`,
            capacity: 10_000
        )
        for _ in 0..<10_000 {
            _ = try pool.allocate()
        }
    }

    // MARK: - Reset

    @Test(.timed(iterations: 20, warmup: 3))
    func `reset pool of 10_000 slots`() throws {
        var pool = try Memory.Pool(
            slotSize: 64,
            slotAlignment: .`8`,
            capacity: 10_000
        )

        // Fill completely
        for _ in 0..<10_000 {
            _ = try pool.allocateSlot()
        }

        // Measure reset
        pool.reset()
    }

    // MARK: - Index Lookup

    @Test(.timed(iterations: 20, warmup: 3))
    func `index lookup for 10_000 pointers`() throws {
        var pool = try Memory.Pool(
            slotSize: 64,
            slotAlignment: .`8`,
            capacity: 10_000
        )

        var pointers: [UnsafeMutableRawPointer] = []
        pointers.reserveCapacity(10_000)
        for _ in 0..<10_000 {
            pointers.append(try pool.allocate())
        }

        // Measure index resolution
        for ptr in pointers {
            _ = pool.index(for: ptr)
        }
    }
}
