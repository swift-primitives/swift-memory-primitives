extension Tagged where Tag == Memory, Underlying == Ordinal {

    public enum Error: Swift.Error, Equatable, Hashable, Sendable {

        case null

        case fault
    }
}
