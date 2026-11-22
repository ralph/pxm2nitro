/// Photomator Curves (`C`) → Nitro Curves. See `docs/mapping.md` §2.1.
///
/// - `rgb` becomes the master curve in RGB mode (`operateOnGray: false`); `l` (luminance)
///   becomes the master curve in luminance mode, used only when `rgb` is unchanged.
/// - `r`, `g`, `b` go to Nitro's red, green and blue slots.
/// - The first and last Photomator points become Nitro's black and white handles; the
///   points in between become user points.
enum CurvesMapper {
    static let tolerance = 1e-6

    static func map(_ curves: PhotomatorCurves, intensity: Double,
                    diagnostics: inout [ConversionDiagnostic]) -> NitroAdjustment.Content? {
        func edited(_ points: [CurvePoint]?) -> [CurvePoint]? {
            guard let points, !isIdentity(points) else { return nil }
            return points
        }
        let rgb = edited(curves.rgb), luminance = edited(curves.luminance)
        let red = edited(curves.red), green = edited(curves.green), blue = edited(curves.blue)
        guard rgb != nil || luminance != nil || red != nil || green != nil || blue != nil else { return nil }

        var nitro = NitroLevelsCurves(isCurves: true, operateOnGray: rgb == nil && luminance != nil)
        if let master = rgb ?? luminance {
            nitro.master = channel(master, intensity: intensity, in: nitro)
        }
        if rgb != nil, luminance != nil {
            diagnostics.append(ConversionDiagnostic(
                .skipped, .curves, "the luminance curve was dropped; Nitro has one master curve and the RGB curve was used"))
        }
        if let red { nitro.red = channel(red, intensity: intensity, in: nitro) }
        if let green { nitro.green = channel(green, intensity: intensity, in: nitro) }
        if let blue { nitro.blue = channel(blue, intensity: intensity, in: nitro) }
        return .levelsCurves(nitro)
    }

    static func isIdentity(_ points: [CurvePoint]) -> Bool {
        points.allSatisfy { abs($0.x - $0.y) < tolerance }
    }

    /// Converts one channel; intensity blends every point toward the diagonal.
    static func channel(_ points: [CurvePoint], intensity: Double, in nitro: NitroLevelsCurves) -> [NitroCurvePoint] {
        let blended = points
            .map { CurvePoint(x: $0.x, y: blend($0.x, $0.y, intensity)) }
            .sorted { $0.x < $1.x }
        guard let black = blended.first, let white = blended.last, blended.count >= 2 else {
            return nitro.channel()
        }
        return nitro.channel(black: black, white: white, inner: Array(blended.dropFirst().dropLast()))
    }
}
