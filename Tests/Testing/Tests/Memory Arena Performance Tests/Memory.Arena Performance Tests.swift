import Testing
import Memory_Arena_Primitives
import Memory_Primitives_Test_Support

@Suite(.serialized)
struct `Memory.Arena - Performance` {

    // MARK: - Allocation Throughput

    @Test(.timed(iterations: 20, warmup: 3))
    func `allocate 10_000 64-byte blocks`() {
        let n: Memory.Address.Count = 10_000
        var arena = Memory.Arena(capacity: n * 64)
        for _ in 0..<10_000 {
            _ = arena.allocate(count: 64, alignment: .`8`)
        }
    }

    @Test(.timed(iterations: 20, warmup: 3))
    func `allocate 10_000 blocks with varying alignment`() {
        let n: Memory.Address.Count = 10_000
        let alignments: [Memory.Alignment] = [.`1`, .`2`, .`4`, .`8`, .`16`]
        var arena = Memory.Arena(capacity: n * 128)
        for i in 0..<10_000 {
            _ = arena.allocate(count: 64, alignment: alignments[i % alignments.count])
        }
    }

    // MARK: - Reset

    @Test(.timed(iterations: 20, warmup: 3))
    func `fill and reset 10_000 blocks`() {
        let n: Memory.Address.Count = 10_000
        var arena = Memory.Arena(capacity: n * 64)
        for _ in 0..<10_000 {
            _ = arena.allocate(count: 64, alignment: .`8`)
        }
        arena.reset()
    }

    // MARK: - Arena Reuse

    @Test(.timed(iterations: 20, warmup: 3))
    func `reset reuse vs fresh allocation`() {
        let n: Memory.Address.Count = 10_000
        var arena = Memory.Arena(capacity: n * 64)
        for _ in 0..<20 {
            for _ in 0..<10_000 {
                _ = arena.allocate(count: 64, alignment: .`8`)
            }
            arena.reset()
        }
    }

    // MARK: - Large Allocations

    @Test(.timed(iterations: 20, warmup: 3))
    func `allocate 100 4KB page-sized blocks`() {
        let n: Memory.Address.Count = 100
        var arena = Memory.Arena(capacity: n * 4096)
        for _ in 0..<100 {
            _ = arena.allocate(count: 4096, alignment: .`4096`)
        }
    }
}
