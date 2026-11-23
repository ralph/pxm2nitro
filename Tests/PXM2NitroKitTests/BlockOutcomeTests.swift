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
        let preset = Fixtures.preset("Broken", adjustments)
        #expect(Converter.convert(preset).blocks == [BlockOutcome(.selectiveColor, .leftOut)])
    }

    @Test func malformedChannelsAreLeftOut() {
        let adjustments = PhotomatorAdjustments(formatVersion: 2, root: [
            "L": ["E": 1, "rgb": "not an object"],
            "C": ["E": 1, "rgb": ["p": "not an array"]],
            "m": ["E": 1, "r": 3],
        ])
        let blocks = Converter.convert(Fixtures.preset("Broken", adjustments)).blocks
        #expect(Set(blocks.map(\.block)) == [.levels, .curves, .channelMixer])
        #expect(blocks.allSatisfy { $0.status == .leftOut })
    }

    @Test func nonObjectCurveChannelIsLeftOut() {
        let adjustments = PhotomatorAdjustments(formatVersion: 2, root: ["C": ["E": 1, "rgb": "broken"]])
        #expect(Converter.convert(Fixtures.preset("Broken", adjustments)).blocks == [BlockOutcome(.curves, .leftOut)])
    }

    @Test func nonNumericFieldsMakeAChannelUnreadable() throws {
        // The broken red row must not become an all-zero row; the readable blue row still converts.
        let adjustments = PhotomatorAdjustments(formatVersion: 2, root: [
            "m": ["E": 1, "r": ["red": "broken"], "b": ["red": 0, "green": 0, "blue": 0.5]],
            "L": ["E": 1, "rgb": ["black": "broken"]],
        ])
        let result = Converter.convert(Fixtures.preset("Broken", adjustments))
        #expect(result.blocks == [BlockOutcome(.levels, .leftOut), BlockOutcome(.channelMixer, .approximated)])
        let mixer = try #require(result.preset?.adjustments.compactMap(\.content.channelMixer).first)
        #expect(mixer.red == NitroChannelMixer().red)
    }

    @Test func presetWithoutAdjustmentsHasNoBlocks() {
        let preset = Fixtures.preset("Empty", nil)
        #expect(Converter.convert(preset).blocks.isEmpty)
    }
}
