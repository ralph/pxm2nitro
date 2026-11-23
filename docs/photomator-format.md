# Photomator / Pixelmator Pro adjustment preset format

Status: reverse-engineered from 83 presets (30 user samples in `sample_presets_photomator/`
plus the 53 built-in presets shipped in
`/Applications/Photomator.app/Contents/Resources/Adjustments.library`) and from the Swift
field names compiled into `PTFoundation.framework`.
Tested against Photomator 3.4.15 (build 20260717) and Pixelmator Pro 3.8 (build 20260323)
on macOS 27.2.

External cross-check: the open-source **pxdlib** project documents the same terse-key JSON as
used for Pixelmator Pro `.pxd` layer styles
(<https://github.com/yunruse/pxdlib/blob/HEAD/docs/pxd/styles.md>, Pixelmator Pro 2.x era).
Its key names agree with the mapping below. UI ranges come from the Pixelmator support guides
(<https://support.pixelmator.com/pixelmator-pro-user-guide/adjust-colors/>,
<https://support.pixelmator.com/photomator-user-guide/color-adjustments/>).

Photomator and Pixelmator Pro share the same `PTFoundation.framework`, which reads and writes
presets. Both apps therefore use **the same format**. (Pixelmator Pro also has layer-style,
brush, text-style and crop presets; this document covers only colour-adjustment presets.)

Confidence markers used below:

- ✅ **confirmed**: seen in the data with an unambiguous meaning, or named outright by a
  binary string
- 🟡 **inferred**: the name comes from the Swift field list and the data fits it, but the
  short key → field mapping has not been checked by a controlled test
- ❓ **unknown**: needs a sample (see [sample-requests.md](sample-requests.md))

---

## 1. Package layout

An exported preset group is a **directory package** with the extension `.adjustments`. The
built-in library uses the same layout as `Adjustments.library`.

```
BW.adjustments/
├── Adjustments-LibraryInfo.plist      library header
├── collections/
│   └── <COLLECTION-UUID>.plist        one per group, lists preset UUIDs in display order
├── presets/
│   └── <PRESET-UUID>.plist            one per preset (independent of each other)
└── resources/                         empty in all samples (probably holds LUT .cube data)
```

All plists are XML plists (`plistlib` / `PropertyListSerialization` read them directly).

### 1.1 `Adjustments-LibraryInfo.plist`

| key | type | example | meaning |
|---|---|---|---|
| `identifier` | string (UUID) | `5533BA32-…` | library ID |
| `collections-list` | [string] | `[7D63CAFD-…]` | collection UUIDs (files in `collections/`) |
| `libraryStructureVersion` | int | `2` | |
| `contentStructureVersion` | int | `4` | |
| `contentBaseVersion` | int | `2450` | app content version that wrote it |
| `contentEditCount` | int | `0` | |
| `resources` | dict | `{}` | resource index (empty in all samples) ❓ LUT presets |

### 1.2 `collections/<UUID>.plist`

| key | type | example | meaning |
|---|---|---|---|
| `id` | string | UUID | same as the file name |
| `name` | string | `BW`, `🎞️` | short group name shown in the UI |
| `presets-list` | [string] | UUIDs | presets in display order |
| `options` | int | `2` | ❓ always 2 |
| `created-at-base-version` | int | `1625` | |
| `meta` | dict | see below | display metadata |

`meta` keys seen: `PXTKitPresetsGroupDescriptiveNameKey` ("Black & White"),
`PXTKitPresetsGroupDescriptionKey` (long text, uses a literal `@newline` as the line break),
`PXTKitPresetsGroupHeaderColorKey` (hex `fdfdfd`), `PXTKitPresetsGroupIsUserCustom`,
`PXTKitPresetsGroupIsUnlocked`, `PXTKitPresetsGroupIsColapsedKey` (sic),
`PXTKitPresetsGroupIsRecents` (bools).

### 1.3 `presets/<UUID>.plist`

| key | type | example | meaning |
|---|---|---|---|
| `id` | string | UUID | same as the file name |
| `name` | string | `002`, `EK100+` | preset name; the converter should use it for the Nitro preset name, prefixed with the collection name, e.g. `BW 002` |
| `options` | int | `2` | ❓ always 2 |
| `created-at-base-version` | int | `2450` | |
| `properties` | array of `{key, value}` | | the payload |

`properties` entries seen: only `key = "ColorAdjustmentData"`, `value = <data>`.

The binary also knows other preset property kinds: `AdjustmentsPresetProperty`,
`CropPresetProperty`, `PTBatchRecipePresetPropertyKey`, `PTRawParametersKey`. **No sample
contains RAW parameters yet** (❓ see the sample requests). RAW develop settings
(`PTRawParameters`, see §4) may be stored as a separate property next to
`ColorAdjustmentData`.

---

## 2. `ColorAdjustmentData`: encoding conventions

`value` is raw bytes of **UTF-8 JSON**. It is not base64 inside the JSON; the plist `<data>`
element is the only base64 layer.

### 2.1 Versioned containers

PTFoundation's Codable types are wrapped in version containers. Two styles appear:

- **Compact (most nodes):** a 2-element array `[version, payload]`, e.g.
  `"l": [1, {...}]`. The root itself is `[2, {...}]` or `[3, {...}]`.
- **Verbose (some nested structs):**
  `{"version": 1, "versionSpecifiContainer": {...}}` (note the typo *Specifi*, which must be
  matched exactly).

A decoder should accept both styles anywhere. An encoder is not needed (we only read
Photomator).

### 2.2 Common keys inside every adjustment payload

| key | meaning |
|---|---|
| `V` | adjustment struct version (always 1; `true` in the verbose style) ✅ |
| `E` | **enabled** (0/1, or bool in the verbose style). Values of disabled adjustments are still stored and must be ignored ✅ |
| `A` | auto-enhance applied (0/1) 🟡 (`isAutoEnhanced`) |

### 2.3 Colours (`PTColor`)

`[1, {"m": 2, "c": [r, g, b, a], "csr": 0}]`. `m` is the colour mode (2 = RGB) and `c`
holds the components 0…1 including alpha. `csr` is an index into the colour-space table in
root `ctx` (§3).

### 2.4 Root-level keys

| key | example | meaning |
|---|---|---|
| root version | `2` or `3` | v3 adds `av` and `li` |
| `ctx` | `[1,{"cs":[1,{"map":{"0":[1,{"icc":"<base64 ICC>","k":0,"m":2}]}}]}]` | coding context: colour-space table. Entry `0` has an embedded ICC profile (sRGB IEC61966-2.1, 4192 bytes, or Display P3, 536 bytes) ✅ |
| `csr` | `0` | colour-space reference of the whole adjustment stack → `ctx` entry ✅ |
| `in` | `1` | preset **intensity** 0…1 (global "amount" slider) 🟡 |
| `u` | `1` | 🟡 probably `useExtendedRGBIntermediates` |
| `e` | `0` | 🟡 probably `shouldPerformAutoEnhance` / `isAutoEnhanced` |
| `av` | `0`/`1` | 🟡 `adjustmentsVersion` / `colorAdjustmentsAlgorithm` (v3 only) |
| `li` | `false` | ❓ (v3 only); candidate: `ignoreRAWProcessing` |

---

## 3. Adjustment blocks

The Swift field list of the colour-adjustment container (in this order, from
`__swift5_reflstr`) is:

`lightness, fade, whiteBalance, hueSaturation, levels, curves, sharpen, selectiveClarity,
colorBalance, hsbColors, replaceColor, removeColor, channelMixer, colorMonochrome,
blackAndWhite, sepia, invert, lensCorrection, vignette, grain, cubeLUT`

Short key → adjustment, with the UI name in Photomator:

| key | adjustment | Photomator UI | conf. |
|---|---|---|---|
| `l` | lightness | Light | ✅ |
| `f` | fade | Fade (?) | 🟡 |
| `w` | whiteBalance | White Balance | ✅ |
| `hS` | hueSaturation | Color (Hue / Saturation / Vibrance) | ✅ |
| `L` | levels | Levels | ✅ |
| `C` | curves | Curves | ✅ |
| `S` | sharpen | Sharpen | ✅ |
| `cl` | selectiveClarity | Clarity / Texture per tone range | ✅ |
| `B` | colorBalance | Color Balance | ✅ |
| `ca` | hsbColors | Selective Color | ✅ |
| `r` | replaceColor | Replace Color | 🟡 |
| `R` | removeColor | Remove Color (newer, v3 only) | 🟡 |
| `m` | channelMixer | Channel Mixer | ✅ |
| `M` | colorMonochrome | Color Monochrome | ✅ |
| `b` | blackAndWhite | Black & White | ✅ |
| `s` | sepia | Sepia | 🟡 |
| `i` | invert | Invert | 🟡 |
| — | lensCorrection | Lens Correction | ❓ not present in any sample |
| `v` | vignette | Vignette | ✅ |
| `g` | grain | Grain | ✅ |
| `cL` | cubeLUT | LUT | 🟡 |

Every preset in the samples contains **all** blocks (except lens correction). Most are
disabled. Only the `E` flag says whether a block is active.

**Storage convention** (pxdlib + docs, checked with sample `C`, see `sample-log.md`): sliders the
UI shows in % are stored as `value = percent / 100` (so ±100 % ↔ ±1, ±200 % ↔ ±2). ✅ **Exceptions:**
Light highlights/shadows (UI ±100 % ↔ ±2), Selective Color hue (UI ±100 % ↔ ±4) and
brightness (UI ±200 % ↔ ±4). `i` is always an intensity 0…1 (default 1), and `A` means an ML
auto adjustment was applied. Typed values beyond the range are clamped to it.

UI ranges from the Pixelmator guides (typed entry; option-drag can exceed the normal slider span):

| adjustment | slider: UI range |
|---|---|
| White Balance | Temperature ±200 %, Tint ±200 % (slider ±100 %); relative % even on a RAW ✅ |
| Hue & Saturation | Hue ±100 %, Saturation ±100 %, Vibrance ±200 % ✅ |
| Light / Basic | Exposure ±400 % (slider ±200 %), Highlights ±100 %, Shadows ±100 %, Brightness ±200 %, Contrast ±200 %, Black Point ±200 %, Clarity ±100 %, Texture ±100 % ✅ |
| Selective Clarity | Clarity / Texture ±100 % per tone range |
| Selective Color | Hue ±100 % (stored ±4), Saturation range ? (stored % / 100), Brightness ±200 % (stored ±4) ✅ |
| Black & White | Red/Green/Blue ±100 %, Tone ±200 %, Intensity |
| Fade | Blacks (default 100 %) / Whites (default 0 %), 0…200 % ✅ (Photomator shows them too) |
| Channel Mixer | Red, Green, Blue, Constant ±200 % |
| Vignette | Exposure ±200 %, Black Point ±200 %, Softness 0…100 % |
| Grain | Size 0…400 %, Intensity 0…100 % |
| Sharpen | Radius 0…10 px (typed up to 100), Intensity 0…100 % |
| Color Monochrome, Sepia, Invert, LUT | Intensity |

Below, *range seen* is the observed min…max over all 83 presets where the block is enabled,
and *default* is the value seen in disabled blocks. UI ranges in rows without ✅ are
❓ until checked against a calibration sample.

### 3.1 `l` Light (lightness)

| key | field | default | range seen | notes |
|---|---|---|---|---|
| `e` | exposure | 0 | 0 … 0.57 | ✅ UI shows %: ±1 = ±100 %, range ±4 |
| `h` | highlights | 0 | −1.2 … 0.8 | ✅ UI ±100 % ↔ ±2 |
| `s` | shadows | 0 | −0.1 … 1.07 | ✅ UI ±100 % ↔ ±2 |
| `b` | brightness | 0 | −0.35 … 0.20 | 🟡 |
| `c` | contrast | 0 | −0.65 … 0.30 | 🟡 |
| `B` | blackPoint | 0 | −0.31 … 0.40 | ✅ ±1 = ±100 %, range ±2; positive deepens the blacks |
| `C` | clarity (`basicClarity`) | 0 | −0.5 … 0 | ✅ ±1 = ±100 % |
| `T` | texture (`basicTexture`, UI "Struktur") | 0 | always 0 | ✅ ±1 = ±100 % |
| `A` | auto-enhanced | 0 | | |

The field list also has `basicDehaze`/`basicDehazeTint` (`dehaze`, `dehazeTint`). They are
not present in the samples ❓.

### 3.2 `f` Fade

| key | default | range seen | notes |
|---|---|---|---|
| `f` | 1 (some disabled blocks have 0.5) | 0.35 … 1.10 | ✅ Blacks ("Schwarztöne"), UI % / 100, 0…2 |
| `c` | 0 | 0 … 0.2 | ✅ Whites ("Weißtöne"), UI % / 100, 0…2 |

✅ Sample `C` (P-4): Photomator's Fade panel shows Blacks and Whites, like Pixelmator Pro
(`fadeBlack`/`fadeWhite`); pxdlib's "`f` = intensity" is wrong. How they shape the tone curve is ❓.

### 3.3 `w` White Balance

| key | field | default | range seen |
|---|---|---|---|
| `t` | temperature | 0 | −0.05 … 0.096 |
| `T` | tint | 0 | −0.196 … 0 |
| `A` | auto | 0 | |

These are **relative** shifts on rendered pixels (not Kelvin), ±1 = ±100 %, range ±2. ✅ The UI
shows % even on a RAW file (P-5). Field list: `temperature, tint, grey, whiteBalanceAutoEnhance`.

### 3.4 `hS` Color (hue / saturation)

| key | field | default | range seen |
|---|---|---|---|
| `h` | hue | 0 | −0.1 … 0 |
| `s` | saturation | 0 | −0.2 … 0 |
| `v` | vibrancy | 0 | −0.35 … 0.15 |

✅ All three are UI % / 100 (P-6): hue and saturation ±1, vibrance ±2.

### 3.5 `L` Levels

Sub-objects (each verbose-style, optional, only present when changed): `rgb`, `r`, `g`, `b`,
`l` (luminance). Each one has:

| key | identity value |
|---|---|
| `black` | 0 |
| `midOfBlackAndGray` | 0.25 |
| `gray` | 0.5 |
| `midOfGrayAndWhite` | 0.75 |
| `white` | 1 |

All values are input levels 0…1, five handles. ❓ There are no output levels in the samples.

### 3.6 `C` Curves

Sub-objects (compact `[1,{…}]`): `rgb`, `r`, `g`, `b`, `l` (luminance). Each one has:

| key | meaning |
|---|---|
| `p` | control points `[[x, y], …]`, 0…1, sorted by x. Identity = `[[0,0],[1,1]]` |
| `d`, `l`, `s`, `h` | 🟡 parametric region sliders (darks / lights / shadows / highlights). Always 0 in the samples |

The curve interpolation is ❓, probably a monotone cubic spline. `C` is enabled in 82 of 83
presets and carries most of the "look".

### 3.7 `S` Sharpen

`i` intensity (default 0.5), `r` radius (default 2.5). Seen: i 0.25…0.5, r 1…2.5.

### 3.8 `cl` Selective clarity (verbose style, `E`/`V` are bools)

`s`, `m`, `h` (shadows / midtones / highlights), each `{clarity, texture}`. Disabled and 0 in
all samples.

### 3.9 `B` Color Balance

Verbose sub-objects `M` (master, overall), `s` (shadows), `m` (midtones), `h` (highlights).
Each one is `{red, green, blue, luminance, saturation}` with values about −0.6…0.6, 0 =
neutral. The UI is a colour wheel per range. The wheel position is stored as R/G/B offsets
(they sum to 0) plus luminance and saturation (UI % / 100, the arcs beside each wheel).

⚠️ Sample `C` (P-6, "3-Wege-Farbtöne" mode, wheels Lichter / Mitteltöne / Schatten) stores the
**midtones wheel as `M`**, next to `h` and `s`, and writes no `m`. So `M` is not always the
master. The mode menu has more options (not sampled), which probably use `M`/`m` differently ❓.

### 3.10 `ca` Selective Color (hsbColors)

`a`: an array of **8** verbose entries, each with:

| key | range seen | notes |
|---|---|---|
| `hue` | −0.92 … 1.6 | ±4 = UI ±100 %; how many degrees that is in Nitro is ❓ |
| `saturation` | −0.7 … 0.6 | |
| `brightness` | −1.6 … 0.77 | |
| `color` | always `[0,0,0,1]` | unused for the 8 standard ranges (probably a custom picked colour) |

Index → colour range ✅ (the documented UI order: reds, oranges, yellows, greens, cyans, blues,
violets, magentas; ✅ storage order = UI order, checked with P-2):
`0 red, 1 orange, 2 yellow, 3 green, 4 cyan, 5 blue, 6 violet, 7 magenta`.
✅ Saturation is UI % / 100. Hue shows ±100 % in the UI but stores ±4, and brightness shows
±200 % but stores ±4 (P-2). `ca` is enabled in every preset and is heavily used.

### 3.11 `r` Replace Color, `R` Remove Color 🟡

`r`: `{r: [1, {i: 1, r: 0.5}]}`. Source and target colours are not stored when unused.
`R`: `{c: <PTColor>, R: 0.25, r: 0.5, i: 1}` (colour, colour range, luminance range,
intensity). Never enabled in the samples. Not convertible.

### 3.12 `m` Channel Mixer

Verbose sub-objects `r`, `g`, `b` (output channel), each `{red, green, blue, constant}`.
Example (LS_005): `b = {red: -0.5, green: 1.5, blue: 0, constant: 0}`. ❓ Are absent channels
identity (r = {1,0,0,0})?

### 3.13 `M` Color Monochrome

`c` colour (default sepia-ish `[0.592, 0.45, 0.305, 1]`), `i` intensity. Never enabled.

### 3.14 `b` Black & White

| key | meaning |
|---|---|
| `b` | balance `{red, green, blue, luminance, saturation}` (verbose); a filter colour expressed like a colour-balance wheel |
| `t` | tone (toning amount, 0 … 0.45) 🟡 |
| `i` | intensity (1) |

### 3.15 `s` Sepia, `i` Invert

`i` intensity (1). Never enabled.

### 3.16 `v` Vignette

| key | field | default | range seen |
|---|---|---|---|
| `e` | exposure | 0.5 | 0.01 … 0.5 |
| `b` | blackPoint | 0 | 0 … 0.6 |
| `s` | softness | 1 | 0.2 … 1 |

### 3.17 `g` Grain

`i` intensity (default 0.5), `s` size (default 0.25).

### 3.18 `cL` LUT

`a` amount (1). The LUT data (`cubeLUTData`) is not present in the samples. ❓ Probably stored in
`resources/` and referenced from the library info.

---

## 4. RAW parameters (`PTRawParameters`): not yet seen in presets

`PTFoundation` has a versioned `PTRawParameters` struct that wraps `CIRAWFilter`. Its fields
are:

`exposure, baselineExposure, bias, boost, boostShadowAmount, isDisabledGamutMap,
neutralChromaticityX, neutralChromaticityY, neutralTemperature, neutralTint,
isEnabledSharpening, isEnabledChromaticNoiseTracking, noiseReductionAmount,
isEnabledVendorLensCorrection, luminanceNoiseReductionAmount, colorNoiseReductionAmount,
noiseReductionSharpnessAmount, noiseReductionContrastAmount, noiseReductionDetailAmount,
decoderVersion, extendedDynamicRangeAmount (+ inputLocalToneMapAmount)`

These map almost 1:1 onto `CIRAWFilter` properties, so they would map cleanly onto Nitro's
`RAW`/`Tone`/`Detail` blocks. **Probably not in presets.** The Photomator and Pixelmator documentation describes no
user-facing RAW sliders (Boost, decoder noise reduction etc.). RAW files become "RAW layers"
and the normal colour adjustments run on extended-range data
(<https://support.pixelmator.com/faq-photomator/advanced-workflows/working-with-raw-files-in-photomator.md>).
`PTRawParameters` is most likely internal per-document state. Request P-1 (low priority)
confirms this.

---

## 5. Decoding recipe (for the Swift implementation)

1. Enumerate `presets/*.plist` (or follow `collections/*.plist` → `presets-list` for order
   and grouping).
2. `PropertyListDecoder` → `{id, name, properties: [{key, value: Data}]}`.
3. For `ColorAdjustmentData`: `JSONSerialization.jsonObject(with:)`, which gives `[Int, [String: Any]]`.
4. Unwrap version containers recursively (the `[Int, Dict]` and `{version, versionSpecifiContainer}` styles).
5. For each block with `E == 1`, read the fields above. Ignore disabled blocks.
6. Ignore `ctx` (ICC) except to note the working colour space.

A Python reference decoder is in [`tools/decode_photomator.py`](tools/decode_photomator.py).
