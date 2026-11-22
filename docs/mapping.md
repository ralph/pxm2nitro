# Photomator → Nitro mapping

Formats: [photomator-format.md](photomator-format.md) · [nitro-format.md](nitro-format.md).
Unresolved items are marked ❓ and are listed again in [sample-requests.md](sample-requests.md).

## Implementation status

| Photomator block | Nitro | code | status |
|---|---|---|---|
| Curves | Curves | `CurvesMapper` | ✅ implemented (slot order / handle y still to verify in Nitro) |
| Levels | Levels | `LevelsMapper` | ✅ black/white; midtone handles reported |
| Channel Mixer | ChannelMixer | `ChannelMixerMapper` | ✅ 1:1 |
| Selective Color | HSL | `SelectiveColorMapper` | ⚠️ implemented with placeholder scales (`MappingConstants`), reports `uncalibrated` |
| everything else | — | — | skipped with a diagnostic |

## 0. Ground rules

1. **Only enabled Photomator blocks** (`E == 1`) are converted. A disabled block produces
   nothing.
2. **Neutral values are skipped.** A Nitro adjustment is emitted only if at least one mapped
   value is not neutral.
3. **Nitro templates:** every emitted Nitro adjustment starts from a template copied
   from a real Nitro preset (all keys at neutral). The mapped values then overwrite the
   template. This way we never write a key set Nitro has not written itself.
4. **Preset intensity (`in`)**: scalar values are multiplied by `in`. Curves are blended
   toward identity (`y' = x + in·(y − x)`). In all samples `in == 1`.
5. **No approximations by default.** Only mappings with a direct Nitro counterpart are
   converted. Anything else is **skipped with a warning** (the library returns structured
   diagnostics; the CLI prints them per preset). Approximations (marked *opt-in* below) are a
   later, explicitly enabled option. An adjustment counts as "missing in Nitro" only after
   the feature check N-6 confirms it.
6. **Scaling functions** (`k_*` below) are placeholders until the calibration samples arrive.
   Both apps store most sliders as roughly −1…1 floats, but the units differ (see §3).

## 1. Overview

| Photomator block | → Nitro | quality | notes |
|---|---|---|---|
| `l` Light: exposure | `Tone.exposure` | 🟢 likely good | scale ❓ (EV vs %) |
| `l` Light: highlights | `Tone.highlights` (or `Tone.recovery` for negative values) | 🟡 | ✅ Nitro neutral is 1.0. Scale ❓ |
| `l` Light: shadows | `Tone.shadows` | 🟡 | scale ❓ |
| `l` Light: brightness | `Enhance.lighten` (+) / `Enhance.deepen` (−) **or** `Tone.midtones` | 🟠 | decide after calibration |
| `l` Light: contrast | `Enhance.contrast` = 1 + k·c | 🟡 | |
| `l` Light: blackPoint | `Tone.blackPointDelta` | 🟠 | sign and scale ❓ |
| `l` Light: clarity `C` | `Detail.clarity` | 🟡 | |
| `l` Light: texture `T` | — | ⚪ | always 0 in the samples; skip and warn if non-zero |
| `f` Fade | default: **skip and warn** (unless N-6 finds a Nitro Fade). Opt-in: bake into the master curve | 🟠 | semantics ❓ |
| `w` White Balance (relative temp/tint) | default: **skip and warn** | 🔴 | ✅ Nitro stores absolute Kelvin (`temperature: 4321`) and tint, while Photomator stores a relative shift. A preset cannot know the as-shot value. ❓ N-1 `WB jpg` shows whether Nitro behaves relatively on non-RAW files |
| `hS` saturation | `Enhance.saturation` = 1 + k·s | 🟢 | |
| `hS` vibrancy | `Enhance.vibrancy` | 🟢 | scale ❓ |
| `hS` hue | default: **skip and warn**. Opt-in: the same `HSL.hueDelta_*` shift on all 9 colours | 🟠 | approximation of a global hue rotation |
| `L` Levels | Nitro `Levels` (black/white input only) | 🟠 | ✅ Nitro Levels stores only the black and white input handles per channel, with no gamma or output values. Photomator's gray, quarter and output handles have no target, so: black/white → Levels, the rest skipped with a warning. Opt-in: bake into curves |
| `C` Curves (rgb, r, g, b, l) | `Curves.levelsCurvesData.pointsArray` | 🟢 | see §2.1 |
| `S` Sharpen | `Detail.sharpen` | 🟡 | radius is dropped |
| `cl` Selective clarity | default: **skip and warn**. Opt-in: `Detail.clarity` (midtones value) | 🟠 | never used in the samples |
| `B` Color Balance | default: **skip and warn**. Opt-in: baked into R/G/B curves, or `SplitToning` | 🟠 | see §2.3. Frequent (31/83), so this is the most valuable opt-in |
| `ca` Selective Color (8 hues) | `HSL` (9 hues) | 🟡 | see §2.2 |
| `m` Channel Mixer | `ChannelMixer` | 🟢 1:1 | see §2.4 |
| `b` Black & White | `BlackAndWhite` (+ `SplitToning` for tone) | 🟠 | Nitro shape ❓ |
| `M` Color Monochrome | default: **skip and warn**. Opt-in: `BlackAndWhite` + `SplitToning` | 🔴 | never used |
| `s` Sepia | default: **skip and warn**. Opt-in: `BlackAndWhite` + `SplitToning` | 🔴 | never used |
| `v` Vignette | `Vignette` | 🟡 | Nitro shape ❓ |
| `g` Grain | `Grain` (or `Detail.grainIntensity/grainDensity`) | 🟡 | Nitro shape ❓ |
| `cL` LUT | `LUT` | 🟠 | needs the `.cube` file on both sides ❓ |
| `r` Replace Color, `R` Remove Color, `i` Invert | — | ❌ skip and warn | never used in the samples |
| RAW params (very likely never in presets, see the format doc §4) | `RAW`, `Tone.boost`, `Tone.boostShadowSliderValue`, `Detail.*Noise`, `decoderVersionString` | 🟢 likely | ❓ sample needed |

How often each block is used across the 83 Photomator presets: Curves 82, Selective Color 83
(enabled; often all zero), Light 83, Color Balance 31, Fade 22, Grain 21, Color 21, B&W 11,
White Balance 10, Vignette 6, Sharpen 5, Channel Mixer 2. **Curves + Selective Color + Light
+ Color Balance carry almost every look**, so they are the MVP.

## 2. Detailed rules

### 2.1 Curves

Photomator `C` has five curves: `rgb`, `r`, `g`, `b`, `l` (luminance). Nitro has one curve
set with 4 slots (🟡 `[master, red, green, blue]`) and a flag `operateOnGray` that switches
the master between luminance ("Grau") and RGB.

- `rgb` → master with `operateOnGray:false`.
- `l` (luminance) → master with `operateOnGray:true`, used only when `rgb` is identity.
  If both are non-identity, compose `l ∘ rgb` into one RGB master curve and warn. (In all
  83 samples `l` is identity.)
- `r`, `g`, `b` → slots 1…3.
- Points: Photomator `p` gives `[[x,y],…]`, with the first and last points as end points.
  Nitro keeps a skeleton: guard `(0,0)`, black handle, inner points, white handle
  (`isWhitePoint`), and guard `(maxValue, maxValue)`. Map the Photomator end points to the black
  and white handles, and the inner points to `deletable:true` points.
  ❓ Can Nitro's black and white handles carry y ≠ 0 / y ≠ 1? Photomator end points often do
  (e.g. `[0, 0.034]`, `[1, 0.936]`, i.e. a matte look). If not, keep the handles at (0,0)/(1,1) and
  add near-end inner points (x = 0.001 / 0.999).
- Interpolation: both apps probably use a smooth spline, but not necessarily the same one.
  ❓ Phase 2: check visually. If they differ, resample the Photomator curve with its own
  spline into 8–16 points.
- Photomator's parametric region sliders `d/l/s/h` are always 0 in the samples. If one is not
  zero, warn.

### 2.2 Selective Color (`ca`) → HSL

| Photomator `ca.a[i]` ✅ (docs order) | Nitro colour |
|---|---|
| 0 red | `red` |
| 1 orange | `orange` |
| 2 yellow | `yellow` |
| 3 green | `green` |
| 4 cyan / aqua | `cyan` |
| 5 blue | `blue` (and `lightBlue` = mean of cyan and blue, see below) |
| 6 violet | `purple` |
| 7 magenta | `magenta` |

- `hue` → `hueDelta_<c>` = k_hue · hue. Nitro uses degrees. Photomator stores percent/100
  (UI ±400 %). Which angle 100 % equals is ❓ and needs a visual calibration.
- `saturation` → `saturationDelta_<c>` = k_sat · saturation.
- `brightness` → `lumaDelta_<c>` = k_lum · brightness.
- `range_<c>` = 0 (Nitro default; Photomator has no per-colour range).
- Nitro has an extra `lightBlue` swatch. Options: (a) leave it at 0, (b) average cyan and blue.
  Recommendation: (b), configurable.
  ❓ The hue centres of both apps decide which is better (calibration request).

### 2.3 Color Balance (`B`): opt-in only

Default: skip and warn. The options below are candidates for the later approximation mode.

Photomator stores per range (`s`, `m`, `h`, master `M`) the values `{red, green, blue, luminance,
saturation}` from a colour wheel. Two options:

1. **R/G/B curve baking (recommended):** turn each range's RGB offset into a bump on the
   per-channel curves (shadows ≈ x 0.25, midtones ≈ 0.5, highlights ≈ 0.75, master =
   uniform). Then compose with Photomator's own `r/g/b` curves and refit to Nitro points.
   This stays close to the original and leaves `SplitToning` free.
2. **SplitToning:** convert each RGB offset into hue angle and saturation magnitude, and map
   shadows → `shadows_*`, highlights → `highlights_*`, midtones and master → `overall_*`.
   This is simpler but less faithful (Nitro split toning tints; it does not subtract).

Luminance and saturation per range are folded into the master curve (luminance) and dropped
(saturation, with a warning).

Order of operations: Photomator probably applies its adjustments in the field order
(`… levels, curves, …, colorBalance …`) ❓. When baking, compose in this order:
`levels → curves → colorBalance`.

### 2.4 Channel Mixer (`m`) → ChannelMixer (1:1)

`m.<out> = {red, green, blue, constant}` → `<out>_red`, `<out>_green`, `<out>_blue`, `<out>_bias`,
where `out ∈ {r→red, g→green, b→blue}`. A missing output channel becomes identity
(`<out>_<out> = 1`, others 0) ❓ (confirm absence = identity).
Scale: both apps show "1.0" for identity, so no scaling is expected.

### 2.5 Levels (`L`)

Each Photomator channel has 5 input handles. Converted to a curve, this is
black → (b, 0), white → (w, 1), with the gamma defined by the gray handle
(`midOfBlackAndGray`/`midOfGrayAndWhite` look derived, 0.25/0.75 at identity). If Nitro's
`Levels` (probably `levelsCurvesData` with `curves:false`) has the same handles, map 1:1;
otherwise bake into the curves.

### 2.6 Fade (`f`): skip unless N-6 finds a Nitro equivalent; the curve baking below is opt-in

❓ Semantics are pending. Working hypothesis: fade raises black output and/or lowers white
output. Bake it into the master curve by moving the black and white handle outputs.

### 2.7 Light (`l`)

Photomator stores percent/100 (Exposure UI ±400 %, Highlights/Shadows ±100 %, Brightness/
Contrast/Black Point ±200 %). Nitro Exposure is in EV. How much EV Photomator's "100 %
exposure" equals is ❓. Calibrate visually; the first guess is 100 % ≈ 1 EV. Notes:

- Nitro `Tone.highlights` and `Tone.midtones` are 1 in all samples. They are either
  multipliers (neutral 1) or sliders whose default is 1. ❓ Baseline sample.
- Negative Photomator `highlights` (recover) may fit `Tone.recovery` better than
  `Tone.highlights`.
- Photomator `blackPoint` raises or lowers the black level. Nitro `blackPointDelta` is an offset to the
  image-dependent `baseBlackPoint`.

### 2.8 RAW

Photomator has no user-facing RAW sliders, so presets will most likely never contain RAW settings.
The converter emits **no** `RAW` block and does not touch `Tone.boost` & co. Nitro's per-adjustment
merge then keeps the image's own RAW and Tone settings, but only if no `Tone` block is emitted.
⚠️ As soon as we emit `Tone` (for exposure, highlights, …), the whole Tone block replaces the
image's one, including Boost and Blacks/Whites. The template values must therefore be Nitro's
neutral defaults (request N-0). For reference only, if RAW params ever turn up:

| PTRawParameters | Nitro |
|---|---|
| `exposure` | `Tone.exposure` (added to the Light exposure) |
| `boost` | `Tone.boost` |
| `boostShadowAmount` | `Tone.boostShadowSliderValue` (scale ❓) |
| `isDisabledGamutMap` | `RAW.enableGamutMap = !value` |
| `isEnabledSharpening` / sharpness | `RAW.rawSharpen` |
| `luminanceNoiseReductionAmount` | `Detail.lumaNoise` |
| `colorNoiseReductionAmount` | `Detail.colorNoise` |
| `noiseReductionDetailAmount` | `Detail.noiseDetail` |
| `neutralTemperature/Tint` | `WhiteBalance` (absolute, RAW only) ❓ |
| `decoderVersion` | `decoderVersionString` |
| `localToneMapAmount` | `Tone.toneMap` |
| `extendedDynamicRangeAmount` | — ❓ |

If a preset carries no RAW parameters, the converter emits no `RAW` block and leaves `Tone.boost`
at its template value.

## 3. Calibration plan (scale factors)

For each slider pair (Photomator field ↔ Nitro key) we need `nitro = f(photomator)`. Usually
this is linear `k·x (+ offset)`, possibly with clamping to the Nitro range. Sources, cheapest
first:

1. **Display values:** a preset saved with a known UI value gives "stored value ↔ UI value"
   for each app. If both UIs show the same unit (e.g. EV, %), the mapping follows directly.
2. **Extreme values:** saving at slider min/max gives the stored range, which gives a linear
   fit when the UI semantics match.
3. **Visual matching (phase 2):** apply a Photomator preset to a test image, then tune the
   Nitro slider until it matches. This is needed only for sliders without a shared unit
   (brightness, clarity, vibrance, selective-colour hue).

The library keeps all factors in one table (`MappingConstants.swift`) so that calibration does
not change any logic.
