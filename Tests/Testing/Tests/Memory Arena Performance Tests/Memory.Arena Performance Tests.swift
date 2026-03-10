import Testing
import Memory_Arena_Primitives
import Memory_Primitives_Test_Support

@Suite(.serialized)
struct `Memory.Arena - Performance` {

    private static let block: Memory.Address.Count = 64
    private static let page: Memory.Address.Count = 4096
    private static let align8: Memory.Alignment = .`8`
    private static let alignPage: Memory.Alignment = .`4096`

    // MARK: - Allocation Throughput

    @Test(.timed(iterations: 20, warmup: 3))
    func `allocate 10_000 64-byte blocks`() {
        var arena = Memory.Arena(capacity: 640_000)
        for _ in 0..<10_000 {
            _ = arena.allocate(count: Self.block, alignment: Self.align8)
        }
    }

    @Test(.timed(iterations: 20, warmup: 3))
    func `allocate 10_000 blocks with varying alignment`() {
        let alignments: [Memory.Alignment] = [.`1`, .`2`, .`4`, .`8`, .`16`]
        var arena = Memory.Arena(capacity: 1_280_000)
        for i in 0..<10_000 {
            _ = arena.allocate(count: Self.block, alignment: alignments[i % alignments.count])
        }
    }

    // MARK: - Reset

    @Test(.timed(iterations: 20, warmup: 3))
    func `fill and reset 10_000 blocks`() {
        var arena = Memory.Arena(capacity: 640_000)
        for _ in 0..<10_000 {
            _ = arena.allocate(count: Self.block, alignment: Self.align8)
        }
        arena.reset()
    }

    // MARK: - Arena Reuse

    @Test(.timed(iterations: 20, warmup: 3))
    func `reset reuse vs fresh allocation`() {
        var arena = Memory.Arena(capacity: 640_000)
        for _ in 0..<20 {
            for _ in 0..<10_000 {
                _ = arena.allocate(count: Self.block, alignment: Self.align8)
            }
            arena.reset()
        }
    }

    // MARK: - Large Allocations

    @Test(.timed(iterations: 20, warmup: 3))
    func `allocate 100 4KB page-sized blocks`() {
        var arena = Memory.Arena(capacity: 409_600)
        for _ in 0..<100 {
            _ = arena.allocate(count: Self.page, alignment: Self.alignPage)
        }
    }
}
