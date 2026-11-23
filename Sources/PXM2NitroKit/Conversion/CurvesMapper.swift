/// Photomator Curves (`C`) → Nitro Curves. See `docs/mapping.md` §2.1.
///
/// The first and last Photomator points become Nitro's black and white handles; the points
/// in between become user points. Channel layout: see `NitroChannelLayout`.
enum CurvesMapper: BlockMapper {
    static let block = PhotomatorBlock.curves

    static func map(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) -> [NitroAdjustment.Content] {
        reportParametricSliders(adjustments, context: &context)
        // A channel without `p` only carries sliders; otherwise every stored point must parse.
        context.reportUnreadableChannels(adjustments.curves, in: adjustments, block: block) { raw, parsed in
            guard let points = raw["p"] else { return false }
            guard let stored = points.arrayValue else { return true }
            return stored.count != parsed?.count
        }
        guard let curves = adjustments.curves,
              let layout = NitroChannelLayout(curves, isIdentity: isIdentity, block: block, context: &context)
        else { return [] }
        let neutral = NitroLevelsCurves(isCurves: true, operateOnGray: layout.operateOnGray)
        var nitro = neutral
        for slot in layout.slots {
            guard slot.value.count >= 2 else {
                context.report(.skipped, block,
                               "the \(slot.name) curve has fewer than two points and was dropped")
                continue
            }
            // E.g. intensity 0 blends every curve back to the diagonal.
            if isIdentity(slot.value.map { CurvePoint(x: $0.x, y: context.blend($0.x, $0.y)) }) { continue }
            nitro[keyPath: slot.keyPath] = channel(slot.value, in: nitro, context: context)
        }
        return nitro == neutral ? [] : [.levelsCurves(nitro)]
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

    /// Photomator's parametric region sliders (`d`/`l`/`s`/`h`) have no Nitro target.
    static func reportParametricSliders(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) {
        guard let payload = adjustments.enabledBlock(block) else { return }
        let channels = [("rgb", "RGB"), ("r", "red"), ("g", "green"), ("b", "blue"), ("l", "luminance")]
        for (key, name) in channels {
            guard let channel = payload[key] else { continue }
            let moved = ["d", "l", "s", "h"].filter { slider in
                channel[slider]?.doubleValue.map { !isNearlyEqual($0, 0) } ?? false
            }
            if !moved.isEmpty {
                context.report(.skipped, block,
                               "the \(name) curve's parametric sliders (\(moved.joined(separator: ", "))) were dropped")
            }
        }
    }
}
