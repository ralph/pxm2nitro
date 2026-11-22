# pxm2nitro: format documentation

Goal: convert Photomator / Pixelmator Pro adjustment presets (`.adjustments` packages) into
Nitro presets (`.nitropreset`). The implementation will be a Swift package with a library
plus a CLI (a SwiftUI GUI comes later).

| document | content |
|---|---|
| [photomator-format.md](photomator-format.md) | package layout, plist structure, the `ColorAdjustmentData` JSON, short-key dictionary |
| [nitro-format.md](nitro-format.md) | `.nitropreset` JSON, `editModel`, adjustment IDs and keys |
| [mapping.md](mapping.md) | block-by-block mapping, lossy cases, calibration plan |
| [sample-requests.md](sample-requests.md) | step-by-step instructions for the samples still needed |
| [sample-log.md](sample-log.md) | template for recording UI values of the requested samples |
| [tools/decode_photomator.py](tools/decode_photomator.py) | reference decoder: `python3 -I docs/tools/decode_photomator.py <pkg.adjustments>` |

## Decisions (2026-11-22)

1. **Unsupported adjustments:** first verify that Nitro really lacks them (feature check
   N-6 in [sample-requests.md](sample-requests.md)). If an adjustment is missing, the converter
   **skips it and warns**. Approximations (e.g. baking Fade or Color Balance into curves) may
   come later as an **opt-in option**. They are never the default.
2. **Output:** the CLI writes `.nitropreset` files into a **folder chosen by the user**
   (`--output <dir>`). It never writes into Nitro's group container itself. The user copies
   the files into `…/group.com.gentlemencoders.nitro/…/My Preset/` and restarts Nitro, which
   reads presets only at launch.
3. **Inputs:** Photomator **and Pixelmator Pro** adjustment presets are officially supported
   (same `.adjustments` format, same framework). Preset properties other than
   `ColorAdjustmentData` are skipped with a warning.

## Sources

- Sample presets in this repository (30 Photomator presets, 3 Nitro presets).
- The 53 built-in Photomator presets in
  `/Applications/Photomator.app/Contents/Resources/Adjustments.library` (same format).
- Swift reflection metadata (`__swift5_reflstr`) of `PTFoundation.framework` (Photomator 3.4.15 /
  Pixelmator Pro 3.8), which gives the long field names behind Photomator's one-letter keys.
- Strings, nib names and localisations in `Nitro.app` 2026.09.01.
- Web research (RAW Power / Nitro manuals, Pixelmator docs), cited inline where used.

## Key findings

1. **Photomator** presets are plists whose single property `ColorAdjustmentData` is UTF-8
   JSON with versioned containers (`[ver, {…}]`) and one/two-letter keys. Each preset stores
   **all 20 colour adjustments**, each with an enabled flag `E`. The RAW develop settings
   (`PTRawParameters`) have not appeared in any preset so far.
2. **Nitro** presets are JSON. `editModel.versions[0].adjDataArr` is a list of
   `{id, json}`, where `json` is a **JSON string** (double-encoded). Most adjustments use a flat
   `numeric` dict. Curves/Levels use a structured `levelsCurvesData`.
3. The mapping is **not** 1:1 even though both apps sit on Apple's RAW engine. That shared engine
   only covers the RAW decode stage (boost, noise, gamut map, decoder version). All creative
   adjustments are each app's own pipeline. Curves, Channel Mixer and Selective Color → HSL map
   well. Light/Tone and Color Balance need calibration or baking into curves.
