# Sample requests: missing data

Each request below closes one or more ❓ items in the format and mapping docs. The requests
are ordered by priority. **P1 blocks the MVP, P2 is needed for good quality, P3 is nice to have.**

## How to deliver

- **Nitro:** copy the `.nitropreset` files from
  `~/Library/Group Containers/group.com.gentlemencoders.nitro/Library/Application Support/My Preset/`
  into `nitro_sample_presets/`.
- **Photomator:** put all request presets into one new preset group named `REQ`, export the
  group, and put `REQ.adjustments` into `sample_presets_photomator/`.
- **Values:** name each preset exactly as given (e.g. `N1 Tone`). Note **the values the UI
  displays** in [`sample-log.md`](sample-log.md) (a template is there). The UI number next to
  the stored number gives the scale, so the log matters as much as the file.
- Use the same two test images throughout: **one camera RAW** and **one JPEG/HEIC**.
- Pick "odd" values that are easy to spot (e.g. 23, −37, 0.61), never round defaults.

---

## Nitro

> **Status 2026-11-23:** all Nitro requests are **done** (via computer use, see
> [sample-log.md](sample-log.md)), except where an item is impossible: Nitro has no Grain panel
> and no RGB curve mode. The presets `N0 defaults`, `N1 all`, `N1 WB jpg`,
> `N2 curves slots|range2|ends`, `N3 max|min` and `N4 sony tone|applied` are in
> `nitro_sample_presets/`. Still open: whether `operateOnGray: false` renders differently.

### N-0 Baseline (P1, done; Nitro never saves neutral blocks, so only B&W and Vignette were saved)
1. Open the RAW, choose *Revert to Original* (or reset all), save a preset as `N0 raw`.
2. Same with the JPEG: `N0 jpg`.
3. If the save dialog lets you pick which adjustments to include, **select all**.

Closes: neutral values of every adjustment, the full ID list, whether `highlights/midtones = 1` is
neutral, whether `baseBlackPoint/baseWhitePoint` are image-dependent (✅ N-4.2: they are).

### N-1 One preset per adjustment (P1)
On the **RAW** file, starting from the original each time, enable **only** that adjustment,
set **every** slider to a distinct odd value, save the preset, and log the displayed values.

| preset name | adjustment | notes |
|---|---|---|
| `N1 Tone` | Tone | all sliders incl. Boost and boost shadows |
| `N1 Enhance` | Enhance | |
| `N1 Detail` | Detail | incl. noise and grain sliders if present |
| `N1 WB raw` | White Balance | note whether the UI shows Kelvin |
| `N1 WB jpg` | White Balance, **on the JPEG** | relative or absolute? |
| `N1 Levels lum` | Levels, Luminance mode | move black, gray and white (and output handles if present) |
| `N1 Levels rgb` | Levels, RGB mode | change R only |
| `N1 BW` | Black & White | all controls |
| `N1 Split` | Split Toning | different hue, sat and luma for highlights, shadows and overall + balance |
| `N1 Vignette` | Vignette | incl. a moved centre |
| `N1 Grain` | Grain | |
| `N1 LUT` | LUT, a built-in one | amount ≠ 100 % if possible |
| `N1 RAW` | RAW | all sliders, gamut mapping off, decoder 8 |

### N-2 Curves layout (P1, done)
1. `N2 curves slots`: in **Grau** (gray) mode add one point to the master at about
   (0.25, 0.40). Switch to Red and add a point at about (0.50, 0.70), Green at about (0.50, 0.30),
   Blue at about (0.75, 0.90). Note the exact In/Out numbers.
2. ~~`N2 curves rgb`: the same master point, but with the channel selector on **RGB** instead
   of Grau.~~ Not possible: the curve channel menu has no RGB mode.
3. `N2 curves range2`: the toggle on **2** instead of the default **1**.
4. `N2 curves ends`: drag the master **black handle up** (output ≈ 0.10) and the **white
   handle down** (output ≈ 0.90), if Nitro allows it. Note whether that works.

Closes: curve slot order, `operateOnGray`, the meaning of `maxValue`, whether the end points
can carry y ≠ 0/1.

### N-3 Slider ranges (P2, done; Nitro has no Grain panel)
1. `N3 max`: Tone, Enhance, Detail, White Balance, HSL (red only: all four sliders), Split
   Toning, Vignette and Grain, **every slider at its maximum**.
2. `N3 min`: the same at the **minimum**.
3. Log the displayed min and max values.

### N-4 Apply behaviour (done), no file needed, just observations
1. ~~Do adjustments missing from a preset stay?~~ The manual answers this: presets replace each
   adjustment block they contain and leave the others untouched.
2. Does applying a preset change Boost / black point for a different camera's RAW (are
   `baseBlackPoint/baseWhitePoint` from the preset used or recomputed)? ✅ N-4.2, see
   `nitro-format.md` §3.2.

### N-6 Feature check: does Nitro really lack these? (P1, done)
For each Photomator adjustment below, check whether Nitro has an equivalent control
(any panel, including Quick Fixes or the `…` menus). Write *yes + where* or *no*.

| Photomator adjustment | Nitro equivalent? |
|---|---|
| Fade (lift blacks / matte look) | no (only via the Curves end handles) |
| Color Balance (shadows / midtones / highlights colour wheels) | no. Split-Farbtöne has highlights, shadows and overall wheels plus luminance and balance, but no midtones |
| Global Hue shift (Hue & Saturation → Hue) | no (HSL works per colour only) |
| Selective Clarity (clarity per shadows / midtones / highlights) | no (Detail → Klarheit is global) |
| Texture | no |
| Dehaze | no |
| White Balance on a JPEG: relative shift or Kelvin? | Kelvin, from a nominal 5001 K / tint 10 (N-1 `WB jpg`) |
| Sharpen radius | no (Detail → Schärfen, RAW Tuning → RAW-Schärfe) |
| Color Monochrome / Sepia (tint the whole image one colour) | no (B&W + Split-Farbtöne at most) |
| Replace Color / Remove Color | no |
| Invert | no (only via Curves) |
| Levels output handles (output black/white) | no (input black / gray / white only) |
| Curves black/white handle with output ≠ 0/1 | yes (N-2.4) |

Checked 2026-11-23 in every panel of the edit tab, Quick Fixes (Auto-Verbessern, KI-Radierer,
Fleck- und Drahtentfernung, Klonen) and the mask tab. The full edit list: Beschnitt & Perspektive,
Weißabgleich, Tonwert, Verbessern, Detail, RAW Tuning, Tonwerte, Kurven, HSL, Schwarzweiß,
Split-Farbtöne, Chromatische Aberration, Objektiv, Kanalmischer, Vignette, plus LUTs in the
presets tab.

### N-5 Import test (P1, done for `BW 001` and `LS 002`)
1. Generate presets: `swift run pxm2nitro convert sample_presets_photomator/*.adjustments -o ~/Desktop/pxm2nitro-out`
2. Copy these into Nitro's preset folder and restart Nitro:
   - `BW 001.nitropreset` (master RGB curve with lifted black / lowered white handle → tests handle y ≠ 0/1)
   - `filmic PT800.nitropreset` (Levels RGB black + Curves + HSL)
   - `LS 005.nitropreset` (Channel Mixer blue row)
   - `LS 002.nitropreset` (Levels in luminance mode, red/blue curves → tests the curve slot order)
3. Apply each to an image and note:
   - Does Nitro list and apply the preset at all?
   - Curves: does the master curve start above 0 and end below 1 (handle y kept), and do red/blue
     changes land on the red and blue curves (slot order)?
   - Levels: black/white handles where expected? Grau vs RGB mode?
   - HSL: plausible strength? (scales are placeholders)

---

## Photomator

> **Status 2026-11-23:** group `C` (`sample_presets_photomator/C.adjustments`, 14 presets on
> L1008408.DNG, created via computer use) covers P-2, P-3, P-4, P-5 (RAW only), P-6 (except
> `P6 mixer red`) and P-9. Values and findings are in [sample-log.md](sample-log.md). Still
> open: P-0 (Photomator does not save a preset without edits), P-1, P-5 on a JPEG, P-6 mixer,
> P-7, P-8 and P-10.

### P-0 Baseline (P2)
`P0 jpg` and `P0 raw`: an untouched image saved as a preset. This shows which blocks a
"default" preset writes, and the default `f` (fade) values.

### P-1 RAW settings in presets (P3; the docs say Photomator has no RAW sliders, this only confirms it)
On the **RAW** file, change the RAW-specific settings (the RAW section / "RAW" or "Develop"
panel: exposure, boost, boost shadows, noise reduction, sharpening, lens correction,
decoder version, whatever is available). Save `P1 raw`. **Question:** does the preset save
dialog offer to include RAW settings? Closes: whether `PTRawParameters` appear in presets.

### P-2 Selective Color index order and hue unit (P2; the docs give the colour order, this confirms the storage order)
Selective Color only. For each colour swatch, in UI order, set **saturation** to a different
value: 1st = 10, 2nd = 20, 3rd = 30, … 8th = 80. Also set the **hue** of the first swatch to
its maximum and the **brightness** of the second swatch to its minimum. Save `P2 selective`.
Log the swatch colours in UI order. Closes: index → colour, and the hue and brightness units.

### P-3 Light (P1)
1. `P3 light`: Exposure, Highlights, Shadows, Brightness, Contrast, Black Point (and
   Clarity, Texture, Dehaze if present in the Light section), each at a distinct odd value.
   Log the displayed values **and units** (EV? %?).
2. `P3 light max`: all of them at maximum. Log the values.
3. On a RAW file: apply a converted preset with a black point and compare Nitro's Black slider
   with Photomator's look (does positive mean deeper blacks in both? how far?).

### P-4 Fade (P1)
`P4 fade`: Fade only, at a distinct value (log all controls the Fade panel shows).
`P4 fade max`: at maximum.

### P-5 White Balance (P2)
`P5 wb jpg` on the JPEG and `P5 wb raw` on the RAW: temperature and tint at distinct values.
Log whether the RAW shows Kelvin.

### P-6 Color, Color Balance, B&W, Channel Mixer (P2)
- `P6 color`: Hue, Saturation, Vibrance at distinct values.
- `P6 balance`: Color Balance: shadows wheel, midtones wheel, highlights wheel and the
  master, each moved differently, plus the luminance slider. Log what the UI shows (angle and
  amount?).
- `P6 bw`: Black & White with a filter colour and tone.
- `P6 mixer red`: Channel Mixer, change **only the red output**. Shows whether untouched
  outputs are stored.

### P-7 Levels output (P3)
`P7 levels`: if Levels has output handles, move them. Change luminance and RGB.

### P-8 LUT (P3)
`P8 lut`: apply any LUT at 60 %, export the group. Shows how LUT data is stored (`resources/`?).

### P-10 Pixelmator Pro (P2)
In Pixelmator Pro, create a small adjustment preset group (2–3 presets, e.g. Curves + Selective
Color + Light), export it, and put it next to the Photomator samples. Confirms that the format
is identical and shows any extra properties Pixelmator Pro writes.

### P-9 Vignette / Grain / Sharpen (P3)
`P9 fx`: Vignette, Grain and Sharpen at distinct values. Log the values.

---

## Answers expected per item

| ❓ | closed by |
|---|---|
| Nitro adjustment ID strings | ✅ N-0, N-1 |
| Nitro neutral values (`highlights=1`?) | ✅ N-0 |
| Nitro slider ranges | ✅ N-3 (`nitro-format.md` §3) |
| Curves slot order, `operateOnGray`, `maxValue`, end-point handles | ✅ N-2/N-5 (`operateOnGray:false` rendering still ❓) |
| Preset application semantics | ✅ manual (per-adjustment replacement); ✅ N-4.2 for base black/white points |
| Photomator RAW params in presets | 🟡 docs say no; P-1 confirms |
| Selective Color index → colour, hue unit | ✅ P-2 (hue in Nitro degrees still ❓) |
| Light units | ✅ P-3 (black point sign ✅; scales ❓) |
| Fade semantics | ✅ P-4 (keys; the tone curve it applies is still ❓) |
| WB relative vs absolute | ✅ Photomator relative even on RAW (P-5); Nitro Kelvin on RAW and JPEG (N-1) |
| Colour balance UI ↔ storage | 🟡 P-6 (3-way mode only) |
| LUT storage | 🟡 N-1 LUT (built-ins ✅, user LUTs ❓), P-8 |
| Which adjustments Nitro truly lacks | ✅ N-6 |
| Pixelmator Pro format identical | P-10 |
