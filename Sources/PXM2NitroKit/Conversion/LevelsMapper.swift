/// Photomator Levels (`L`) → Nitro Levels. See `docs/mapping.md` §2.5.
///
/// Nitro's Levels store only the black and white input per channel; the mid handle is
/// always halfway between them. Photomator's gray and quarter handles are therefore only
/// carried over when they sit at those positions, otherwise a diagnostic is emitted.
enum LevelsMapper {
    static let tolerance = 1e-3

    static func map(_ levels: PhotomatorLevels, intensity: Double,
                    diagnostics: inout [ConversionDiagnostic]) -> NitroAdjustment.Content? {
        func edited(_ handles: LevelsHandles?) -> LevelsHandles? {
            guard let handles, !isIdentity(handles) else { return nil }
            return handles
        }
        let rgb = edited(levels.rgb), luminance = edited(levels.luminance)
        let red = edited(levels.red), green = edited(levels.green), blue = edited(levels.blue)
        guard rgb != nil || luminance != nil || red != nil || green != nil || blue != nil else { return nil }

        var nitro = NitroLevelsCurves(isCurves: false, operateOnGray: rgb == nil && luminance != nil)
        if rgb != nil, luminance != nil {
            diagnostics.append(ConversionDiagnostic(
                .skipped, .levels, "the luminance levels were dropped; Nitro has one master channel and the RGB levels were used"))
        }
        let channels: [(String, LevelsHandles?, WritableKeyPath<NitroLevelsCurves, [NitroCurvePoint]>)] = [
            ("master", rgb ?? luminance, \.master), ("red", red, \.red), ("green", green, \.green), ("blue", blue, \.blue),
        ]
        var changed = false
        for (name, handles, keyPath) in channels {
            guard let handles else { continue }
            if !midHandlesAreCentred(handles) {
                diagnostics.append(ConversionDiagnostic(
                    .approximated, .levels, "the \(name) gray/midtone handles were dropped; Nitro only stores black and white"))
            }
            let black = blend(0, handles.black, intensity), white = blend(1, handles.white, intensity)
            guard abs(black) >= tolerance || abs(white - 1) >= tolerance else { continue }
            nitro[keyPath: keyPath] = nitro.channel(black: CurvePoint(x: black, y: 0), white: CurvePoint(x: white, y: 1))
            changed = true
        }
        return changed ? .levelsCurves(nitro) : nil
    }

    static func isIdentity(_ handles: LevelsHandles) -> Bool {
        abs(handles.black) < tolerance && abs(handles.white - 1) < tolerance && midHandlesAreCentred(handles)
    }

    /// Whether gray sits halfway between black and white, and the quarter handles halfway
    /// between their neighbours, which is the only arrangement Nitro can represent.
    static func midHandlesAreCentred(_ handles: LevelsHandles) -> Bool {
        let gray = (handles.black + handles.white) / 2
        return abs(handles.gray - gray) < tolerance
            && abs(handles.midOfBlackAndGray - (handles.black + gray) / 2) < tolerance
            && abs(handles.midOfGrayAndWhite - (gray + handles.white) / 2) < tolerance
    }
}
