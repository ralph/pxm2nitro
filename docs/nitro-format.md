# Nitro preset format (`.nitropreset`)

Status: reverse-engineered from the sample presets in `nitro_sample_presets/`, the strings and
Swift reflection data in `Nitro.app` (2026.09.01, build 247), and the UI itself. The `N…` presets
were created on purpose with known UI values; see
[sample-log.md](sample-log.md) for every value that was set. Nitro is made by Gentlemen
Coders (the RAW Power team), and its edit model comes from RAW Power.

Confidence markers: ✅ confirmed · 🟡 inferred · ❓ unknown (see [sample-requests.md](sample-requests.md)).

User presets live in:

```
~/Library/Group Containers/group.com.gentlemencoders.nitro/Library/Application Support/My Preset/
```

This folder is protected by macOS privacy controls (TCC). By decision, the converter writes to
a folder the user chooses; the user then copies the files into the folder above and
restarts Nitro.

Official docs exist only for behaviour, not for the file format:
Nitro manual <https://www.gentlemencoders.com/nitro/user-manual/index.html>, RAW Power 3 help
<https://www.gentlemencoders.com/manuals/RAW-Power-3.0-for-Mac-Help.pdf>, CIRAWFilter
<https://developer.apple.com/documentation/coreimage/cirawfilter>.

## 0. Behaviour that matters for the converter

- **Presets merge per adjustment** (manual): applying a preset replaces every adjustment block
  it contains completely and leaves the other blocks untouched. Sliders are never merged
  individually.
- **Processing order is fixed** (manual). The order of `adjDataArr` does not matter; samples
  store blocks in edit order.
- Nitro reads the preset folder **only at launch**.
- **Only changed adjustments are saved** ✅ (observed). The save dialog lists only adjustments
  whose values differ from neutral. An adjustment switched on at its defaults is not offered,
  and a preset without any edit cannot be saved at all.
- **Save dialog defaults** ✅ (observed): there is one switch per adjustment, and the switches
  remember the last choice (on first use Tone, Enhance and Detail were off; see sample-log).
- Per-image edits live in XMP sidecars (namespace `http://com.gentlemencoders/xmp/nitro/1.0/`).

---

## 1. File structure ✅

One preset is one file, `<Preset Name>.nitropreset`, containing UTF-8 JSON on a single line.
The file name is the preset name, including spaces and umlauts.

```jsonc
{
  "name": "N1 all",
  "version": 1,
  "editModel": {
    "formatVersion": 1,
    "currentVersionIndex": 0,
    "defaultOrientation": 1,          // EXIF/TIFF orientation 🟡
    "lowResMask": false,
    "editingJPEGHalf": false,
    "versions": [
      {
        "decoderVersionString": "8",  // RAW decoder: "9.dng" = UI "v9", "8" = UI "v8" ✅
        "masks": [],
        "adjDataArr": [ { "id": "Tone", "json": "<JSON string>" }, … ]
      }
    ]
  }
}
```

- **Double encoding** ✅: `adjDataArr[].json` is a *string* that contains JSON. The converter
  has to build the inner object, serialise it, and store the resulting string.
- **Decoder version** ✅: the RAW Tuning panel's v8/v9 choice is written to
  `decoderVersionString`. The sliders on offer also depend on it: v8 adds Moiré, Color Noise
  and Noise Detail (§3.1, §3.4).

### Common inner keys

| key | meaning |
|---|---|
| `enabled` | bool, the adjustment's checkbox ✅ |
| `disclosed` | bool, whether the panel is expanded in the UI (cosmetic only) ✅ |
| `numeric` | dict of `String → Double`, the slider values ✅ |
| `preserve`, `defaultsUpdated` | bools that only some adjustments have (Tone, Detail, RAW); always `false` and `true` respectively. Copy them unchanged. |

---

## 2. Adjustment IDs ✅ (all seen in samples)

| `id` | UI (de) | sample |
|---|---|---|
| `WhiteBalance` | Weißabgleich | N1 |
| `Tone` | Tonwert | Lebendig, N1 |
| `Enhance` | Verbessern | Lebendig, N1 |
| `Detail` | Detail | Lebendig, N1 |
| `RAW` | RAW Tuning | Entsättigen, N1 |
| `Levels` | Tonwerte | N1 |
| `Curves` | Kurven | curves…, N1 |
| `HSL` | HSL | curves…, N1 |
| `BlackAndWhite` | Schwarzweiß | N0, N1 |
| `SplitToning` | Split-Farbtöne | N1 |
| `ChromaticAberration` | Chromatische Aberration | N1 |
| `ChannelMixer` | Kanalmischer | curves… |
| `Vignette` | Vignette | N0, N1 |
| `LUT` | LUT (presets tab → LUTs) | N1 |
| `Lens`, `Crop`, `Perspective`, `Depth` | — | not sampled, and not needed by the converter |

There is **no separate Grain panel** in this Nitro version. The grain keys sit in `Detail`
and are not shown in the UI.

---

## 3. Adjustments

The **UI** column gives the German label shown in the app. Defaults are the values seen in
the UI for this RAW file.

### 3.1 `RAW` (RAW Tuning)

```json
{"enabled":true,"disclosed":true,"preserve":false,"defaultsUpdated":true,"enableGamutMap":false,
 "numeric":{"moire":0.29,"rawContrast":0.43,"rawSharpen":0.57}}
```

| key | UI | default | CIRAWFilter 🟡 |
|---|---|---|---|
| `rawSharpen` | RAW-Schärfe | 1.0 | `sharpnessAmount` |
| `rawContrast` | RAW Kontrast | 0.0 | `contrastAmount` |
| `moire` | Moiré (only shown with decoder v8) | 0.55 on this image, 0 in other samples | `moireReductionAmount` |
| `enableGamutMap` | Spektrum-Mapping checkbox | true | `isGamutMappingEnabled` |

### 3.2 `Tone`

```json
{"enabled":true,"disclosed":true,"preserve":false,"defaultsUpdated":true,
 "baseBlackPoint":5,"baseWhitePoint":0.15,"bpIsAbs":false,"wpIsAbs":false,
 "supportsBoost":true,"supportsToneMap":false,
 "numeric":{"boost":0.73,"exposure":0.37,"highlights":0.61,"shadows":0.23,"midtones":1.17,
            "blackPointDelta":0.13,"whitePointDelta":0.29,"recovery":0.41,
            "boostShadowSliderValue":0.53,"toneMap":0}}
```

The numeric values are stored exactly as the UI shows them ✅.

| key | UI | neutral / default |
|---|---|---|
| `boost` | Verstärkung (RAW only) | 1.0 |
| `exposure` | Belichtung, in EV | 0.0 |
| `highlights` | Glanzlichter | **1.0** |
| `shadows` | Schatten | 0.0 |
| `midtones` | Mitteltöne | **1.0** |
| `blackPointDelta` | Schwarz (RAW only) | 0.0 |
| `whitePointDelta` | Weiß (RAW only) | 0.0 |
| `recovery` | Wiederherstellen | 0.0 |
| `boostShadowSliderValue` | Schatten verstärken (RAW only) | **0.9** |
| `toneMap` | not shown here (`supportsToneMap:false`) | 0 |

✅ Slider ranges (N-3, `N3 max` / `N3 min`): `boost` 0…1, `exposure` ±3, `highlights` 0…1 (so it can
only recover), `shadows` ±1, `midtones` 0.5…1.5, `blackPointDelta` ±1, `whitePointDelta` ±1,
`recovery` ±1, `boostShadowSliderValue` 0…1. On a JPEG the Tone panel shows only Belichtung,
Glanzlichter, Schatten, Mitteltöne and Wiederherstellen.

✅ `baseBlackPoint` and `baseWhitePoint` depend on the camera (N-4.2): 5 / 0.15 on the Leica
M11 (every earlier sample), 3 / 0.35 on a Sony ARW. Nitro **ignores the preset's values** and
keeps the image's own: applying a preset with 5 / 0.15 to the Sony and saving again still gives
3 / 0.35 (`N4 sony applied`). So the converter's fixed 5 / 0.15 template values are harmless.

Earlier samples had `whitePointDelta` set to 0.225 or 0.375. That means the "Weiß" slider had
been moved in those presets.

### 3.3 `Enhance`

| key | UI | neutral |
|---|---|---|
| `deepen` | Tiefen | 0 |
| `lighten` | Lichter | 0 |
| `contrast` | Kontrast | **1.0** (multiplier) |
| `saturation` | Sättigung | **1.0** (multiplier) |
| `vibrancy` | Farbdynamik | 0 |

✅ Ranges (N-3): `deepen` and `lighten` 0…≈2 (dragging reached 1.99), `contrast` and `saturation` 0…2, `vibrancy` ±1.

### 3.4 `Detail`

```json
{"enabled":true,"disclosed":true,"preserve":false,"defaultsUpdated":true,"grainSeed":25.016823,
 "numeric":{"clarity":0.33,"sharpen":0.21,"lumaNoise":0.39,"colorNoise":0.61,"noiseDetail":0.17,
            "blur":0,"jpegNoise":0,"grainIntensity":0,"grainDensity":0.5}}
```

| key | UI | default |
|---|---|---|
| `clarity` | Klarheit | 0 |
| `sharpen` | Schärfen | 0 |
| `lumaNoise` | Bildrauschen | 0 (v9) / 0.8 (v8 on this image) |
| `colorNoise` | Farbrauschen (v8 only) | 0.5 |
| `noiseDetail` | Rauschdetails (v8 only) | 0 |
| `blur`, `jpegNoise`, `grainIntensity`, `grainDensity` | **not in the UI** | 0, 0, 0, 0.5 |
| `grainSeed` | — | random float. The converter writes a fixed seed so its output is reproducible; it only matters with grain, which the converter does not write |

✅ Ranges (N-3): `clarity` ±1, `sharpen` ±1, `lumaNoise` 0…1. `grainSeed` differs per save
(25.016823 in `N1 all`, 22.054216 in `N3 max`/`N3 min`).

🟡 `grainIntensity`/`grainDensity` look like a working film grain. A test preset with a
non-zero value would show whether Nitro actually renders it (❓).

### 3.5 `WhiteBalance`: absolute ✅

```json
{"enabled":true,"disclosed":true,"autoWB":false,"applyFaceBalance":false,
 "numeric":{"temperature":4321,"tint":-17}}
```

`temperature` is in **Kelvin** and `tint` is on Nitro's ±175 scale. The values are written
exactly as the UI shows them. This RAW's as-shot values were 5277 K and tint 25.
`autoWB` and `applyFaceBalance` correspond to the Auto button and face-based auto WB.
✅ Ranges (N-3): `temperature` 1000…20000 K, `tint` ±175.

✅ JPEG (N-1 `WB jpg`, IMG_6659.JPG): the panel also shows Kelvin. The untouched JPEG shows
5001 K / tint 10, a nominal neutral rather than a measured as-shot value. Raising it to 7851 K warms
the image, and it is stored the same way (`temperature: 7850.726`, `tint: -42.883476`). So a
JPEG preset is still absolute: its values only mean "neutral + shift" relative to 5001 K / 10.

### 3.6 `Levels` and `Curves` (`levelsCurvesData`)

Both adjustments share the same struct:

```jsonc
"levelsCurvesData": {
  "curves": false,            // false = Levels, true = Curves ✅
  "operateOnGray": true,      // ✅ always true when saved from the UI (N-2); see below
  "gamma": true,              // 🟡 Gamma vs Linear mode
  "maxValue": 2,              // ✅ always 2
  "histogramMaxValue": 1,     // ✅ the UI "1 | 2" toggle: 1 or 2 (the graph's x range)
  "autoAlgorithm": 0,         // 0 = no Auto button used
  "pointsArray": [ [pts], [pts], [pts], [pts] ]   // 4 channels ✅ [master, R, G, B]
}
```

Point format: `{"x","y","deletable","inactive","invisible","isWhitePoint"}`. Every channel
has this skeleton:

| point | x,y | flags |
|---|---|---|
| guard | 0,0 | `invisible:true` |
| black handle | (bx, by), by usually 0 | `deletable:false` (true once moved up, see below) |
| user points (Curves only) | … | `deletable:true` |
| white handle | (wx, wy), wy usually 1 | `isWhitePoint:true` |
| guard | 2,2 | `invisible:true` |

- **Levels** ✅ (`N1 all`): the black input 0.07 is stored as black handle `x:0.072164945`.
  The UI mid value 0.54 is **not stored**; it is just shown as the midpoint between the black
  and white handles. Levels therefore stores only black and white input per channel, and no
  gamma or output values. ❓ Whether moving the mid handle adds a point is untested.
- **Curves** ✅: the added point 0.25 → 0.37 is stored as `{x:0.25, y:0.3736842}`. The
  Curves inner object also repeats `"id":"Curves","name":"Curves","localizedName":"Kurven"`
  and has `"numeric":{}`. Levels does not repeat these.
- ✅ Channel order (N-2 `N2 curves slots`): a master point at 0.25 → 0.40 and R 0.5 → 0.7,
  G 0.5 → 0.3, B 0.75 → 0.9 land in `pointsArray[0…3]` in that order. N-5 confirmed it the other
  way round with the curves overlay.
- ✅ The "1 | 2" toggle (`N2 curves range2`) only changes `histogramMaxValue` (1 → 2) and extends
  the graph to x = 0…2. The points do not change.
- ✅ End handles (`N2 curves ends`): the UI can move the black handle to (0, 0.1) and the white
  handle to (1, 0.9). They are stored as `{x:0, y:0.1}` (now with `deletable:true`) and
  `{x:1, y:0.9, isWhitePoint:true}`. Imported handles with y ≠ 0/1 also work (N-5).
- The channel menu has only Grau, Rot, Grün, Blau and "Overlay anzeigen". There is no RGB
  master mode, and the UI always saves `operateOnGray: true`. Presets with `operateOnGray: false`
  still load and show the curve under "Grau"; whether the two render differently is ❓. The
  colour-wheel button next to "Auto" is "Auto RGB", which replaces the curves with automatic ones.

### 3.7 `HSL` ✅

The keys follow the pattern `<param>_<colour>`:

- `<param>` is one of `hueDelta` (in degrees, as shown in the UI: 11 → `11`),
  `saturationDelta`, `lumaDelta`, `range`.
- `<colour>` is one of `red, orange, yellow, green, cyan, lightBlue, blue, purple, magenta`.

All 36 keys are always written, and 0 is neutral. The block also has an inner `"version":1`.
UI values are stored 1:1 (red: 11 / 0.23 / −0.17 / 0.31). ✅ Ranges (N-3): `hueDelta` ±60°,
`saturationDelta`, `lumaDelta` and `range` ±1.

### 3.8 `ChannelMixer` ✅

The keys are `<out>_<in>` and `<out>_bias` (UI "Konstant"), with `out` and `in` each one of
`red, green, blue`. Identity is `<c>_<c> = 1` and every other key 0.

### 3.9 `BlackAndWhite` ✅

`numeric: {red, green, blue}`. The defaults are `0.299 / 0.587 / 0.114` (Rec.601 luma); the UI
rounds them to 0.3 / 0.59 / 0.11.

### 3.10 `SplitToning` ✅

```json
"numeric":{"highlights_hue":0.1195,"highlights_saturation":0.8549,"highlights_luma":0,
           "shadows_hue":0.6404,"shadows_saturation":0.9176,"shadows_luma":0,
           "overall_hue":0.1929,"overall_saturation":0.7120,"overall_luma":0.13,"balance":0.63}
```

- `*_hue` is a 0…1 fraction of the colour wheel (0.12 ≈ 43°, orange).
- `*_saturation` is 0…1, the distance from the wheel's centre.
- `*_luma` is the "Luminanz" slider for the selected wheel.
- `balance` defaults to 0.5.
- ✅ Ranges (N-3): `*_saturation` 0…1 (the wheel's rim), `*_luma` ±1, `balance` 0…1. There is
  no midtones wheel, so this is close to Photomator's Color Balance but not the same.

### 3.11 `ChromaticAberration` ✅

`numeric: {redCyan, blueYellow, purpleAmount, purpleRange, greenAmount, greenRange}`.
The defaults are 0, 0, 0, 0.2, 0, 0.2.

### 3.12 `Vignette` ✅

`{"center":[0.5,0.5], "numeric":{"intensity":0.37,"radius":0.71}}`. The defaults are intensity
0.5 and radius 0.5. As with B&W, a default vignette still changes the image.
✅ Ranges (N-3): `intensity` ±1, `radius` 0…1. A negative intensity probably brightens the corners (not checked visually ❓).

### 3.13 `LUT` ✅

```json
{"enabled":true,"disclosed":false,
 "dataParameters":{"lutName":"Velvia","encodedFilePath":"($APP_LUT)/Film Simulation/Velvia.rawpowerCubeData"},
 "numeric":{"intensity":0.46597072}}
```

- Built-in LUTs are referenced through the `($APP_LUT)` placeholder.
- ❓ How imported user LUTs are referenced (probably a different placeholder pointing at the
  user's LUT folder with `.rawpowerCubeData`).

---

## 4. CIRAWFilter reference

The ranges and defaults below are Apple's documentation. The Nitro key each one maps to is
🟡 inferred.

| CIRAWFilter | range / default | Nitro |
|---|---|---|
| `boostAmount` | 0…1, default 1 | `Tone.boost` |
| `boostShadowAmount` | 0…2, default 1 | `Tone.boostShadowSliderValue` (UI default 0.9) |
| `shadowBias` | image-dependent | `Tone.blackPointDelta` |
| `baselineExposure` | camera-dependent | `Tone.whitePointDelta` |
| `localToneMapAmount` | 0…1 | `Tone.toneMap` |
| `luminanceNoiseReductionAmount` | 0…1 | `Detail.lumaNoise` |
| `colorNoiseReductionAmount` | 0…1 | `Detail.colorNoise` |
| `detailAmount` | 0…3 | `Detail.noiseDetail` |
| `moireReductionAmount` | 0…1 | `RAW.moire` |
| `sharpnessAmount` | 0…1 | `RAW.rawSharpen` |
| `contrastAmount` | 0…1 | `RAW.rawContrast` |
| `isGamutMappingEnabled` | default true | `RAW.enableGamutMap` |
| `neutralTemperature` / `neutralTint` | 2000…50000 K / ±150 | `WhiteBalance.temperature` / `tint` |
| `decoderVersion` | — | `decoderVersionString` |

## 5. Writing a Nitro preset (converter recipe)

1. Emit only the adjustments that the conversion actually changes. Nitro itself never saves
   neutral blocks, and an emitted block replaces the image's own block of that type.
2. Avoid emitting `Tone` and `RAW` unless needed. If `Tone` is emitted, it has to carry the
   neutral RAW values (`boost` 1, `boostShadowSliderValue` 0.9, `blackPointDelta`/`whitePointDelta`
   0), or it will override the image's RAW look.
3. Build every block from the full key set shown above, override the mapped values, then set
   `enabled:true` and `disclosed:false`.
4. JSON-encode each inner object into its `json` string.
5. Wrap the blocks in the `editModel` with `decoderVersionString:"9.dng"`, `masks:[]`, and the
   constants from §1.
