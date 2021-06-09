import Foundation

public final class LotusCore {
    private let arguments: [String]

    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }

    public func run() throws {
        Lotus.main()
    }
}
