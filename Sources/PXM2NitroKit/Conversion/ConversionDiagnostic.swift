/// Something the converter could not carry over exactly. See `docs/mapping.md`.
public struct ConversionDiagnostic: Sendable, Equatable, CustomStringConvertible {
    public enum Kind: String, Sendable {
        /// The Photomator adjustment (or part of it) was dropped.
        case skipped
        /// Converted, but not exactly.
        case approximated
        /// Converted with scale factors that have not been calibrated yet.
        case uncalibrated
    }

    public let kind: Kind
    /// The Photomator block concerned, if any.
    public let block: PhotomatorBlock?
    public let message: String

    public init(_ kind: Kind, _ block: PhotomatorBlock?, _ message: String) {
        self.kind = kind
        self.block = block
        self.message = message
    }

    public var description: String {
        [kind.rawValue, block?.displayName].compactMap { $0 }.joined(separator: " ")
            + ": \(message)"
    }
}
