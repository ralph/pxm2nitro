# Nitro preset format (`.nitropreset`)

Status: reverse-engineered from 3 sample presets (`nitro_sample_presets/`), from the
string and Swift-reflection data in `Nitro.app` (2026.09.01, build 247), and from UI
screenshots. Nitro is made by Gentlemen Coders (the RAW Power team). Its edit model comes
from RAW Power.

Confidence markers: ✅ confirmed · 🟡 inferred · ❓ unknown (see [sample-requests.md](sample-requests.md)).

User presets live in:

```
~/Library/Group Containers/group.com.gentlemencoders.nitro/Library/Application Support/My Preset/
```

(This folder is protected by macOS privacy controls (TCC). By decision, the converter writes to a
user-chosen folder, and the user copies the files here and restarts Nitro.)

Official docs (no file-format documentation exists; behaviour only):
Nitro manual <https://www.gentlemencoders.com/nitro/user-manual/index.html>, RAW Power 3 help
<https://www.gentlemencoders.com/manuals/RAW-Power-3.0-for-Mac-Help.pdf>, CIRAWFilter
<https://developer.apple.com/documentation/coreimage/cirawfilter>.

Documented behaviour that matters for the converter:

- **Presets merge per adjustment:** applying a preset replaces each adjustment block it contains
  completely, and leaves blocks it does not contain untouched (no per-slider merge).
- **Processing order is fixed.** The panel order in the UI does not change the order in which
  adjustments are processed, so the order of `adjDataArr` is irrelevant.
- Nitro reads the "My Presets" folder only **at launch**.
- Per-image edits are stored in XMP sidecars (namespace `http://com.gentlemencoders/xmp/nitro/1.0/`).

---

## 1. File structure

One preset = one file, `<Preset Name>.nitropreset`, UTF-8 JSON on a single line. The file name
uses the preset name verbatim (umlauts kept, NFD/NFC ❓).

```jsonc
{
  "name": "Lebendig",                 // display name ✅
  "version": 1,                       // preset file version ✅
  "editModel": {
    "formatVersion": 1,               // ✅
    "currentVersionIndex": 0,         // index into versions ✅
    "defaultOrientation": 1,          // EXIF/TIFF orientation 🟡
    "lowResMask": false,              // 🟡
    "editingJPEGHalf": false,         // 🟡
    "versions": [                     // "EditVersion" objects (edit history snapshots / alt versions)
      {
        "decoderVersionString": "9.dng",   // CIRAWFilter decoder version 🟡 (UI shows decoder "8"/"9")
        "masks": [],                        // local adjustments (not used by the converter)
        "adjDataArr": [                     // ordered adjustment list ✅
          { "id": "Tone",    "json": "<JSON string>" },
          { "id": "Enhance", "json": "<JSON string>" }
        ]
      }
    ]
  }
}
```

### 1.1 Double encoding ✅

`adjDataArr[].json` is a **string containing JSON**, so every adjustment is JSON-encoded twice.
The converter must build the inner object, serialise it, and store that string.

### 1.2 Adjustments may be omitted 🟡

`Lebendig` has no `RAW` entry, while `Entsättigen` has `RAW` with `enabled:false`. Missing
adjustments probably mean "leave as is / default" when the preset is applied. ❓ Does a
preset overwrite adjustments it does not contain? (See sample request N-0.)

### 1.3 Common inner keys

| key | meaning |
|---|---|
| `enabled` | bool: adjustment checkbox ✅ |
| `disclosed` | bool: panel expanded in the UI (cosmetic) ✅ |
| `preserve` | bool ❓ (probably "keep when pasting/applying presets") |
| `defaultsUpdated` | bool ❓ (set to `true` in all samples; copy it) |
| `numeric` | dict `String → Double`: the slider values ✅ |
| `defaultParameters` | (in the Swift model; not serialised in the samples) |

Adjustment-specific extra keys are listed below.

---

## 2. Adjustment IDs

The adjustment set comes from the UI panels (`*AdjustmentTableViewCell.nib`) and from the ID
strings in the binary. The binary only keeps Swift strings of 16 or more characters in
readable form, so some IDs are only partly confirmed.

| id (exact string) | UI (de) | status |
|---|---|---|
| `RAW` | RAW | ✅ sample |
| `Tone` | Ton | ✅ sample |
| `Enhance` | Verbessern | ✅ sample |
| `Detail` | Details | ✅ sample |
| `WhiteBalance` | Weißabgleich | 🟡 binary fragments `WhiteBal`+`ance` |
| `Curves` | Kurven | ✅ sample |
| `Levels` | Tonwerte | 🟡 binary |
| `HSL` | HSL | ✅ sample |
| `BlackAndWhite` | Schwarzweiß | 🟡 binary fragments `BlackAnd`+`White` |
| `ChannelMixer` | Kanalmischer | ✅ sample |
| `SplitToning` | Teiltonung | 🟡 fragment `SplitTon…` |
| `Vignette` | Vignette | 🟡 binary |
| `Grain` | Körnung | 🟡 binary |
| `LUT` | LUT | 🟡 binary |
| `Lens` | Objektiv | 🟡 binary |
| `ChromaticAberration` | Chrom. Aberration | 🟡 nib name only |
| `Crop`, `Perspective`, `Depth` | Geometrie / Tiefe | not relevant to the converter |

❓ The exact ID strings for every adjustment except the four confirmed ones are needed (see
sample request N-1). The converter must not invent IDs.

---

## 3. Known adjustments in detail

### 3.1 `RAW` (only meaningful for RAW files)

```json
{"preserve":false,"enabled":false,"defaultsUpdated":true,"disclosed":true,"enableGamutMap":true,
 "numeric":{"rawContrast":0,"rawSharpen":1,"moire":0}}
```

| key | sample | 🟡 CIRAWFilter property |
|---|---|---|
| `numeric.rawContrast` | 0 | `contrastAmount` |
| `numeric.rawSharpen` | 1 | `sharpnessAmount` |
| `numeric.moire` | 0 | `moireReductionAmount` |
| `enableGamutMap` | true | `isGamutMappingEnabled` (UI "Gamut Mapping") |

The decoder version lives in `EditVersion.decoderVersionString`, not here. ❓ Is there a local
tone map amount or noise reduction in RAW? (noise is in `Detail`.)

### 3.2 `Tone`

```json
{"enabled":true,"disclosed":false,"preserve":false,"defaultsUpdated":true,
 "baseBlackPoint":5,"baseWhitePoint":0.15,"bpIsAbs":false,"wpIsAbs":false,
 "supportsToneMap":false,"supportsBoost":true,
 "numeric":{"exposure":0,"recovery":0,"boost":1,"boostShadowSliderValue":0.9,"midtones":1,
            "highlights":1,"shadows":0,"blackPointDelta":-0,"whitePointDelta":0.375,"toneMap":0}}
```

Manual: Exposure is in EV (1.0 = 2×). Highlights, Shadows and Midtones apply to all images.
Recovery is a selective exposure for the brightest pixels. **RAW-only:** Boost (0…1, "0.5 or 0 for
a flatter look"), Boost Shadows (the black end of the boost curve), Blacks (RAW black point), and
Whites (modifies the baseline exposure).

| key | samples | meaning |
|---|---|---|
| `exposure` | 0 | EV ✅ (manual) |
| `recovery` | 0 | highlight recovery 🟡 |
| `boost` | 1 | RAW boost (CIRAWFilter `boostAmount`, 1 = full) 🟡 |
| `boostShadowSliderValue` | 0.9 | boost shadow amount (UI value, not the raw CI value) 🟡 |
| `midtones` | 1 | ❓ neutral value 1? |
| `highlights` | 1 | ❓ neutral value 1? |
| `shadows` | 0 | 🟡 |
| `blackPointDelta` | −0 | UI "Blacks" (RAW black point, CIRAWFilter `shadowBias`), offset from `baseBlackPoint` 🟡 |
| `whitePointDelta` | 0.225 / 0.375 | UI "Whites" (CIRAWFilter `baselineExposure`), offset from `baseWhitePoint` 🟡 |
| `toneMap` | 0 | local tone map (`supportsToneMap:false` here) 🟡 |
| `baseBlackPoint`, `baseWhitePoint`, `bpIsAbs`, `wpIsAbs` | 5, 0.15, false | image-dependent base values ❓ (are they recomputed when the preset is applied?) |
| `supportsToneMap`, `supportsBoost` | | capabilities of the source image (RAW → boost) |

### 3.3 `Enhance`

```json
{"enabled":true,"disclosed":false,
 "numeric":{"contrast":1.2,"saturation":1.1,"vibrancy":0.4,"lighten":0.1,"deepen":0.2}}
```

| key | neutral 🟡 | samples |
|---|---|---|
| `contrast` | 1 (multiplier) | 1, 1.2 |
| `saturation` | 1 (multiplier) | 0.8, 1.1 |
| `vibrancy` | 0 | −0.2, 0.4 |
| `lighten` | 0 | 0.1, 0.2 |
| `deepen` | 0 | 0, 0.2 |

### 3.4 `Detail`

```json
{"enabled":true,"disclosed":false,"preserve":false,"defaultsUpdated":true,"grainSeed":29.984333,
 "numeric":{"clarity":0.2,"sharpen":0,"blur":0,"lumaNoise":0,"colorNoise":0,"noiseDetail":0,
            "jpegNoise":0,"grainIntensity":0,"grainDensity":0.5}}
```

| key | neutral 🟡 | notes |
|---|---|---|
| `clarity` | 0 | 0.15 / 0.2 in the samples |
| `sharpen` | 0 | |
| `blur` | 0 | |
| `lumaNoise`, `colorNoise`, `noiseDetail` | 0 | noise reduction |
| `jpegNoise` | 0 | JPEG artefact reduction |
| `grainIntensity`, `grainDensity` | 0, 0.5 | legacy grain? (there is also a `Grain` panel ❓) |
| `grainSeed` | random float | RNG seed; generate one |

### 3.5 `Curves` ✅ (sample `curves hsl channel mixer`)

The inner object differs from the slider adjustments: it repeats `id`/`name`/`localizedName`
and has an empty `numeric`. The curve lives in `levelsCurvesData`:

```jsonc
{"id":"Curves","name":"Curves","localizedName":"Kurven","enabled":true,"disclosed":true,"numeric":{},
 "levelsCurvesData":{
   "curves": true,            // true = Curves; Levels probably shares this struct with curves:false 🟡
   "operateOnGray": true,     // 🟡 manual: "Luminance" vs "Equal RGB" mode (UI Grau ↔ RGB)
   "gamma": true,             // 🟡 manual: curve mode "Gamma" vs "Linear"
   "maxValue": 2,             // 🟡 the "1 / 2" toggle: manual "Extended Range" curve 0…2.0 (RAW only)
   "histogramMaxValue": 1,    // ❓
   "autoAlgorithm": 0,        // which Auto button was used (0 = none) 🟡
   "pointsArray": [ [<pt>…], [<pt>…], [<pt>…], [<pt>…] ]   // 4 channels
 }}
```

`pointsArray` holds **4 curves**. Only index 0 was edited in the sample. The manual lists the
channels as Combined, R, G, B, so the order is 🟡 `[combined, red, green, blue]`. ❓ This needs confirmation (request N-2).

Each point:
`{"x":0.2656,"y":0.1526,"deletable":true,"inactive":false,"invisible":false,"isWhitePoint":false}`.

Every curve has this fixed skeleton:

| # | x,y | flags | role |
|---|---|---|---|
| first | 0,0 | `invisible:true`, `deletable:false` | guard point |
| 2nd | 0,0 | `deletable:false` | black point (handle) |
| … | user points | `deletable:true` | |
| | 1,1 | `isWhitePoint:true`, `deletable:false` | white point (handle) |
| last | maxValue,maxValue (2,2) | `invisible:true`, `deletable:false` | guard point |

The converter must keep this skeleton. It should move the black and white handles to the
Photomator end points, insert the inner points as `deletable:true`, and keep the guard points.

### 3.6 `HSL` ✅

```json
{"enabled":true,"disclosed":true,"version":1,"numeric":{ "hueDelta_red":6.9, "saturationDelta_red":-0.22,
 "lumaDelta_red":0.11, "range_red":-0.21, … }}
```

The keys follow the pattern `<param>_<colour>`:

- param ∈ `hueDelta` (degrees, UI shows integers, e.g. 6.9 → "7"), `saturationDelta`,
  `lumaDelta`, `range` (all ≈ −1…1 ❓ exact limits)
- colour ∈ `red, orange, yellow, green, cyan, lightBlue, blue, purple, magenta` (9, in
  UI order)

Neutral = 0 for all 36 keys. Note the inner `"version":1`.

### 3.7 `ChannelMixer` ✅

```json
{"enabled":true,"disclosed":true,"numeric":{
 "red_red":1,"red_green":-0.2955,"red_blue":0.2334,"red_bias":0.0383,
 "green_red":0,"green_green":1,"green_blue":0,"green_bias":0,
 "blue_red":0,"blue_green":0,"blue_blue":1,"blue_bias":0}}
```

Keys: `<output>_<input>` and `<output>_bias` (UI "Konstant"). Identity = diagonal 1. This has
the same structure as Photomator's channel mixer.

---

## 4. Adjustments known only from UI and binary (shape ❓)

| adjustment | UI controls | field names found in the binary |
|---|---|---|
| WhiteBalance | Temperature (**Kelvin**, manual), Tint (±175), presets, auto, grey-point picker | `temperature`, `tint` |
| Levels | Luminance / RGB, Auto, black/white pickers | ❓ |
| SplitToning | Highlights, Shadows, Overall (hue / saturation / luma) + Balance | `highlights_hue`, `highlights_saturation`, `highlights_luma`, `shadows_*`, `overall_*`, `balance` |
| BlackAndWhite | R/G/B mixer (default luminance weights), filter presets Red/Orange/Yellow/Green/Blue/Equal | ❓ |
| SplitToning (manual) | Highlight, Shadow and Overall tint wheels + luminance; Balance does not affect Overall | see above |
| Vignette | intensity + centre point; applied after crop | `center` ❓ |
| Grain | ❓ | `grain_image_taus` (internal) |
| LUT | imported `.cube` files | ❓ how the LUT is referenced |
| Lens | lens profile, De-Vignette | not used |

---

## 5. CIRAWFilter reference (RAW-engine sliders)

Apple documents these ranges. The Nitro slider each one maps to is 🟡 inferred from the manual.

| CIRAWFilter | range / default | Nitro |
|---|---|---|
| `boostAmount` | 0…1, default 1 | `Tone.boost` |
| `boostShadowAmount` | 0…2, default 1 | `Tone.boostShadowSliderValue` (UI value; may be rescaled) |
| `shadowBias` | image-dependent | `Tone.blackPointDelta` + `baseBlackPoint` |
| `baselineExposure` | camera-dependent | `Tone.whitePointDelta` + `baseWhitePoint` |
| `localToneMapAmount` | 0…1, image-dependent | `Tone.toneMap` |
| `luminanceNoiseReductionAmount` | 0…1, image-dependent | `Detail.lumaNoise` |
| `colorNoiseReductionAmount` | 0…1, image-dependent | `Detail.colorNoise` |
| `detailAmount` | 0…3, image-dependent | `Detail.noiseDetail` |
| `moireReductionAmount` | 0…1, image-dependent | `RAW.moire` |
| `sharpnessAmount` | 0…1, image-dependent | `RAW.rawSharpen` |
| `contrastAmount` | 0…1, image-dependent | `RAW.rawContrast` |
| `isGamutMappingEnabled` | default true | `RAW.enableGamutMap` |
| `neutralTemperature` / `neutralTint` | 2000…50000 K / ±150 | `WhiteBalance.temperature` / `tint` (Nitro allows ±175) |
| `decoderVersion` | — | `decoderVersionString` |

Many defaults are image-dependent. A converter therefore cannot know a RAW's neutral
values, which is one more reason to leave the `RAW` block out unless the source has RAW settings.

## 6. Writing a Nitro preset (converter recipe)

1. Build an ordered `adjDataArr` containing only the adjustments the source preset uses.
   The order varies between samples (`Tone, Enhance, Detail, RAW` and `Curves, RAW, ChannelMixer, HSL`),
   so it probably follows the edit order and is irrelevant for rendering 🟡.
2. For each adjustment, write the complete key set from a known-good template (copy the
   neutral values from a baseline Nitro preset), override the mapped sliders, and set
   `enabled:true`, `disclosed:false`.
3. JSON-encode each inner object into the `json` string.
4. Wrap it in `editModel` with `formatVersion:1`, `currentVersionIndex:0`, one version,
   `decoderVersionString:"9.dng"` (❓ or omit to keep the image's version), `masks:[]`,
   `defaultOrientation:1`, `lowResMask:false`, `editingJPEGHalf:false`.
5. Write `{"name", "version":1, "editModel"}` to `<name>.nitropreset`.

Templates for every adjustment should come from real Nitro presets (sample request N-1), so
the converter never emits a key set that Nitro has not produced itself.
