import Foundation
@testable import PXM2NitroKit
import Testing

struct BlockOutcomeTests {
    private func statuses(_ package: String, _ preset: String) throws -> [PhotomatorBlock: BlockOutcome.Status] {
        let result = Converter.convert(try Fixtures.photomatorPreset(package, preset))
        return Dictionary(uniqueKeysWithValues: result.blocks.map { ($0.block, $0.status) })
    }

    @Test func classifiesEveryEnabledBlockInPhotomatorOrder() throws {
        let result = Converter.convert(try Fixtures.photomatorPreset("BW", "001"))
        #expect(result.blocks == [
            BlockOutcome(.light, .leftOut),
            BlockOutcome(.curves, .carriedOver),
            BlockOutcome(.selectiveColor, .approximated),
            BlockOutcome(.blackAndWhite, .leftOut),
            BlockOutcome(.grain, .leftOut),
        ])
    }

    @Test func approximatedLevelsAndExactChannelMixer() throws {
        #expect(try statuses("LS", "002")[.levels] == .approximated)
        #expect(try statuses("LS", "005")[.channelMixer] == .carriedOver)
    }

    @Test func neutralBlockIsNotListed() throws {
        // EK100+ has Levels enabled without any edited channel.
        let statuses = try statuses("filmic", "EK100+")
        #expect(statuses[.levels] == nil)
        #expect(statuses[.curves] == .carriedOver)
    }

    @Test func unreadableSupportedBlockIsLeftOut() {
        let adjustments = PhotomatorAdjustments(formatVersion: 2, root: [
            "ca": ["E": 1, "a": "not an array"],
        ])
        let preset = PhotomatorPreset(id: "x", name: "Broken", collectionName: nil,
                                      adjustments: adjustments, otherPropertyKeys: [])
        #expect(Converter.convert(preset).blocks == [BlockOutcome(.selectiveColor, .leftOut)])
    }

    @Test func presetWithoutAdjustmentsHasNoBlocks() {
        let preset = PhotomatorPreset(id: "x", name: "Empty", collectionName: nil,
                                      adjustments: nil, otherPropertyKeys: [])
        #expect(Converter.convert(preset).blocks.isEmpty)
    }
}
