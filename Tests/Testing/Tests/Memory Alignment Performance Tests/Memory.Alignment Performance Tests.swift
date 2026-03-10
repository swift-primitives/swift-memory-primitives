import Testing
import Memory_Primitives_Core
import Memory_Primitives_Test_Support

@Suite(.serialized)
struct `Memory.Alignment - Performance` {

    // MARK: - Alignment Check

    @Test(.timed(iterations: 20, warmup: 3))
    func `isAligned check 100_000 values`() {
        let alignment: Memory.Alignment = .`16`
        var count = 0
        for i: UInt in 0..<100_000 {
            if alignment.isAligned(i) {
                count &+= 1
            }
        }
        _ = count
    }

    // MARK: - Align Up

    @Test(.timed(iterations: 20, warmup: 3))
    func `align up 100_000 values to 16`() {
        let alignment: Memory.Alignment = .`16`
        var sum: UInt = 0
        for i: UInt in 0..<100_000 {
            sum &+= alignment.align.up(Cardinal(i)).rawValue
        }
        _ = sum
    }

    @Test(.timed(iterations: 20, warmup: 3))
    func `align up 100_000 values to 4096`() {
        let alignment: Memory.Alignment = .`4096`
        var sum: UInt = 0
        for i: UInt in 0..<100_000 {
            sum &+= alignment.align.up(Cardinal(i)).rawValue
        }
        _ = sum
    }

    // MARK: - Align Down

    @Test(.timed(iterations: 20, warmup: 3))
    func `align down 100_000 values to 16`() {
        let alignment: Memory.Alignment = .`16`
        var sum: UInt = 0
        for i: UInt in 1...100_000 {
            sum &+= alignment.align.down(Cardinal(i)).rawValue
        }
        _ = sum
    }

    // MARK: - Mask Computation

    @Test(.timed(iterations: 20, warmup: 3))
    func `mask computation 100_000 times`() {
        let alignments: [Memory.Alignment] = [.`1`, .`2`, .`4`, .`8`, .`16`, .`4096`]

        var sum: UInt = 0
        for i in 0..<100_000 {
            let alignment = alignments[i % alignments.count]
            sum &+= alignment.mask(as: UInt.self)
        }
        _ = sum
    }

    // MARK: - Magnitude

    @Test(.timed(iterations: 20, warmup: 3))
    func `magnitude computation 100_000 times`() {
        let alignments: [Memory.Alignment] = [.`1`, .`2`, .`4`, .`8`, .`16`, .`4096`]

        var sum: UInt = 0
        for i in 0..<100_000 {
            let alignment = alignments[i % alignments.count]
            sum &+= alignment.magnitude(as: UInt.self)
        }
        _ = sum
    }
}
