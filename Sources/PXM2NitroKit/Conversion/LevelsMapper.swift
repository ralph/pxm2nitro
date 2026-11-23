/// Photomator Levels (`L`) → Nitro Levels. See `docs/mapping.md` §2.5.
///
/// Nitro's Levels store only the black and white input per channel; the mid handle is
/// always halfway between them. Photomator's gray and quarter handles are therefore only
/// carried over when they sit at those positions, otherwise a diagnostic is emitted.
enum LevelsMapper: BlockMapper {
    static let block = PhotomatorBlock.levels

    static func map(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) -> [NitroAdjustment.Content] {
        context.reportUnreadableChannels(adjustments.levels, in: adjustments, block: block) { raw, _ in
            raw.objectValue == nil
        }
        guard let levels = adjustments.levels,
              let layout = NitroChannelLayout(levels, isIdentity: isIdentity, block: block, context: &context)
        else { return [] }
        let neutral = NitroLevelsCurves(isCurves: false, operateOnGray: layout.operateOnGray)
        var nitro = neutral
        for slot in layout.slots {
            let handles = slot.value
            if !midHandlesAreCentred(handles) {
                context.report(.approximated, block,
                               "the \(slot.name) gray/midtone handles were dropped; Nitro only stores black and white")
            }
            nitro[keyPath: slot.keyPath] = nitro.channel(
                black: CurvePoint(x: context.blend(0, handles.black), y: 0),
                white: CurvePoint(x: context.blend(1, handles.white), y: 1))
        }
        // Channels that only moved midtone handles leave Nitro's Levels unchanged.
        return nitro == neutral ? [] : [.levelsCurves(nitro)]
    }

    static func isIdentity(_ handles: LevelsHandles) -> Bool {
        isNearlyEqual(handles.black, 0) && isNearlyEqual(handles.white, 1) && midHandlesAreCentred(handles)
    }

    /// Whether gray sits halfway between black and white, and the quarter handles halfway
    /// between their neighbours, which is the only arrangement Nitro can represent.
    static func midHandlesAreCentred(_ handles: LevelsHandles) -> Bool {
        let gray = (handles.black + handles.white) / 2
        return isNearlyEqual(handles.gray, gray)
            && isNearlyEqual(handles.midOfBlackAndGray, (handles.black + gray) / 2)
            && isNearlyEqual(handles.midOfGrayAndWhite, (gray + handles.white) / 2)
    }
}
