/// Photomator Curves (`C`) → Nitro Curves. See `docs/mapping.md` §2.1.
///
/// The first and last Photomator points become Nitro's black and white handles; the points
/// in between become user points. Channel layout: see `NitroChannelLayout`.
enum CurvesMapper: BlockMapper {
    static let block = PhotomatorBlock.curves

    static func map(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) -> [NitroAdjustment.Content] {
        guard let curves = adjustments.curves,
              let layout = NitroChannelLayout(curves, isIdentity: isIdentity, block: block, context: &context)
        else { return [] }
        var nitro = NitroLevelsCurves(isCurves: true, operateOnGray: layout.operateOnGray)
        for slot in layout.slots {
            nitro[keyPath: slot.keyPath] = channel(slot.value, in: nitro, context: context)
        }
        return [.levelsCurves(nitro)]
    }

    /// A curve whose points all lie on the diagonal does nothing.
    static func isIdentity(_ points: [CurvePoint]) -> Bool {
        points.allSatisfy { isNearlyEqual($0.x, $0.y) }
    }

    /// Converts one channel; intensity blends every point toward the diagonal.
    static func channel(_ points: [CurvePoint], in nitro: NitroLevelsCurves, context: MappingContext) -> [NitroCurvePoint] {
        let blended = points.map { CurvePoint(x: $0.x, y: context.blend($0.x, $0.y)) }
        guard blended.count >= 2 else { return nitro.channel() }
        return nitro.channel(black: blended[0], white: blended[blended.count - 1],
                             inner: Array(blended.dropFirst().dropLast()))
    }
}
