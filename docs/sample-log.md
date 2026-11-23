# Sample log

UI values **as displayed** for the request presets (see [sample-requests.md](sample-requests.md)).
Decimal commas in the UI are written as dots here.

## Nitro: `N0 defaults` and `N1 all` (L1008408.DNG, Nitro 2026.09.01, created via computer use on 2026-11-22)

### Observations while creating them

- **Nothing to save without edits:** with no adjustment changed, *Sichern…* only shows an alert.
- **Enabled-but-neutral adjustments are not saved:** the save dialog lists only adjustments
  whose values differ from neutral. Enabling Tone/Enhance/Levels/Curves/HSL/… at defaults
  doesn't count; Black & White and Vignette do (they change the image even at default values).
- **Save dialog defaults:** it has one switch per changed adjustment. On 2026-11-22 Tone, Enhance
  and Detail were switched OFF by default and the others ON. On 2026-11-23 all switches were ON;
  the dialog seems to remember the last choice.
  HSL did not appear in the list for `N1 all`, but the file contains it anyway.
- **Decoder v8 vs v9:** v8 adds sliders: Detail → *Farbrauschen* (color noise, default 0.5) and
  *Rauschdetails* (noise detail, 0.0). RAW Tuning → *Moiré* (default 0.55 on this image).
  *Bildrauschen* (luma noise) changed to 0.8 when switching to v8.
- **White Balance on RAW shows absolute Kelvin:** as-shot 5277 K, tint 25.
- **Curves panel** shows the "1 | 2" toggle with **1** selected by default.

### UI defaults seen (RAW, decoder v9)

| adjustment | slider (de) | default |
|---|---|---|
| White Balance | Temperatur / Farbstich | 5277 / 25 (as shot) |
| Tone | Verstärkung (Boost) | 1.0 |
| Tone | Belichtung (Exposure) | 0.0 |
| Tone | Glanzlichter (Highlights) | 1.0 |
| Tone | Schatten (Shadows) | 0.0 |
| Tone | Mitteltöne (Midtones) | 1.0 |
| Tone | Schwarz (Blacks) | 0.0 |
| Tone | Weiß (Whites) | 0.0 |
| Tone | Wiederherstellen (Recovery) | 0.0 |
| Tone | Schatten verstärken (Boost Shadows) | 0.9 |
| Enhance | Tiefen (Deepen) / Lichter (Lighten) | 0.0 / 0.0 |
| Enhance | Kontrast / Sättigung | 1.0 / 1.0 |
| Enhance | Farbdynamik (Vibrancy) | 0.0 |
| Detail | Klarheit / Schärfen / Bildrauschen | 0.0 / 0.0 / 0.0 |
| RAW Tuning | RAW-Schärfe / RAW Kontrast | 1.0 / 0.0, Spektrum-Mapping on |
| Levels | in black / gray / white | 0.0 / 0.5 / 1.0 |
| HSL | Farbton / Sättigung / Luminanz / Bereich | 0 / 0.0 / 0.0 / 0.0 |
| Black & White | Rot / Grün / Blau | 0.30 / 0.59 / 0.11 |
| Split Toning | Luminanz / Balance | 0.0 / 0.5 |
| Chrom. Aberration | Rot/Cyan, Blau/Gelb, Lila-Int., Lila-Bereich, Grün-Int., Grün-Bereich | 0, 0, 0, 0.2, 0, 0.2 |
| Lens | Verzerrung, Innen, Mitte, Außen, Rand; De-Vignette Anteil / Radius / Abfall | 0…0; 0 / 0.5 / 0.2 |
| Channel Mixer | Rot / Grün / Blau / Konstant (red tab) | 1.0 / 0 / 0 / 0 |
| Vignette | Intensität / Radius | 0.5 / 0.5 |

`N0 defaults` contains only Black & White and Vignette at these defaults.

### `N1 all`: values set

| adjustment | slider | UI value |
|---|---|---|
| White Balance | Temperatur / Farbstich | 4321 / −17 |
| Tone | Verstärkung | 0.73 |
| Tone | Belichtung | 0.37 |
| Tone | Glanzlichter | 0.61 |
| Tone | Schatten | 0.23 |
| Tone | Mitteltöne | 1.17 |
| Tone | Schwarz | 0.13 |
| Tone | Weiß | 0.29 |
| Tone | Wiederherstellen | 0.41 |
| Tone | Schatten verstärken | 0.53 |
| Enhance | Tiefen / Lichter | 0.19 / 0.27 |
| Enhance | Kontrast / Sättigung / Farbdynamik | 1.31 / 0.83 / 0.47 |
| Detail | Klarheit / Schärfen | 0.33 / 0.21 |
| Detail | Bildrauschen / Farbrauschen / Rauschdetails | 0.39 / 0.61 / 0.17 |
| RAW Tuning | Decoder | **v8** |
| RAW Tuning | Moiré / RAW-Schärfe / RAW Kontrast | 0.29 / 0.57 / 0.43 |
| RAW Tuning | Spektrum-Mapping | **off** |
| Levels (Grau) | black / gray / white input | 0.07 / 0.54 / 1.0 |
| Curves (Grau, mode 1) | one added point | in 0.25 → out 0.37 |
| HSL | red: Farbton / Sättigung / Luminanz / Bereich | 11 / 0.23 / −0.17 / 0.31 |
| Black & White | Rot / Grün / Blau | 0.41 / 0.37 / 0.22 |
| Split Toning | highlights wheel → upper right (orange), shadows wheel → lower left (blue), overall wheel → top (yellow-green); Luminanz (overall) / Balance | 0.13 / 0.63 |
| Chrom. Aberration | Rot/Cyan, Blau/Gelb, Lila-Int., Lila-Bereich, Grün-Int., Grün-Bereich | 0.11, −0.13, 0.27, 0.33, 0.19, 0.37 |
| LUT | Built-in → Film Simulation → **Velvia**, Intensität | 0.47 |
| Vignette | Intensität / Radius | 0.37 / 0.71 |
| Lens, Channel Mixer | — | not changed (Channel Mixer covered by `curves hsl channel mixer`) |

## Photomator: group `C` (L1008408.DNG, created via computer use on 2026-11-23)

Values were typed into the value fields. Typing more than the maximum clamps, which gives the
range. Photomator names new presets "Voreinstellung", "Voreinstellung 1", …; the stored value
is from `C.adjustments`.

| preset | request | block | UI value → stored |
|---|---|---|---|
| Voreinstellung | P3 light | Light | Belichtung 23 % → `e` 0.23; Lichter −37 % → `h` **−0.74**; Schatten 41 % → `s` **0.82**; Helligkeit −19 % → `b` −0.19; Kontrast 29 % → `c` 0.29; Schwarzpunkt 13 % → `B` 0.13; Struktur −27 % → `T` −0.27; Klarheit 33 % → `C` 0.33 |
| Voreinstellung 1 | P3 light max | Light | 400 / 100 / 100 / 200 / 200 / 200 / 100 / 100 % → `e` 4, `h` 2, `s` 2, `b` 2, `c` 2, `B` 2, `T` 1, `C` 1 |
| Voreinstellung 2 | P3 light min | Light | the negatives of the maximums |
| Voreinstellung 3 | P4 fade | Fade | Schwarztöne 63 % → `f` 0.63, Weißtöne 17 % → `c` 0.17 (defaults 100 % / 0 %) |
| Voreinstellung 4 | (extra) | Fade | `f` 2, `c` 0.17: a save between the two max entries |
| Voreinstellung 5 | P4 fade max | Fade | 200 % / 200 % → `f` 2, `c` 2 |
| Voreinstellung 6 | P6 color | Color | Farbton 23 % → `h` 0.23, Sättigung −37 % → `s` −0.37, Lebendigkeit 41 % → `v` 0.41 |
| Voreinstellung 7 | P6 color max | Color | 100 / 100 / 200 % → `h` 1, `s` 1, `v` 2 |
| Voreinstellung 8 | P6 bw | B&W | Rot 23, Grün −37, Blau 11, Ton 29, Intensität 61 % → filter `b` {red 0.23, green −0.37, blue 0.11}, `t` 0.29, `i` 0.61 |
| Voreinstellung 9 | P6 balance | Color Balance | mode "3-Wege-Farbtöne"; Lichter puck slightly up-right, Mitteltöne puck slightly down-left + right arc 54 %, Schatten puck slightly up-right → `h`, **`M`** (luminance 0.538) and `s`, each R/G/B offsets that sum to 0 |
| Voreinstellung 10 | P2 selective | Selective Color | saturation 10…80 % in UI order → `a[0…7].saturation` 0.1…0.8; red hue 100 % (max) → `hue` **4**; orange brightness −200 % (min) → `brightness` **−4** |
| Voreinstellung 11 | P9 fx | Vignette, Sharpen, Grain | Vignette Belichtung 37 / Schwarzpunkt 13 / Weichheit 61 % → `e` 0.37, `b` 0.13, `s` 0.61; Schärfen Radius 4.3 px / Intensität 73 % → `r` 4.3, `i` 0.73; Körnung Größe 41 / Intensität 29 % → `s` 0.41, `i` 0.29 |
| Voreinstellung 12 | P5 wb raw | White Balance | Temperatur −23 %, Färbung 17 % → `t` −0.23, `T` 0.17 (the RAW shows %, not Kelvin) |
| Voreinstellung 13 | P5 wb raw max | White Balance | 200 % / 200 % → `t` 2, `T` 2 |

Observations:

- Photomator saves no preset when nothing is edited (P-0 could not be created).
- Defaults in the UI: Vignette Belichtung 50 %, Schwarzpunkt 0 %, Weichheit 100 %; Schärfen
  2.5 px / 50 %; Körnung Größe 25 % / Intensität 50 %; B&W Intensität 100 %.
- Bold values break the "percent / 100" rule (see `photomator-format.md`).

## Nitro: import test (N-5) and black point (P-3.3), L1008408.DNG, 2026-11-23

- **N-5:** all 38 converted presets appear under "Meine Presets" after a restart and apply.
  - `BW 001`: B&W, HSL and Tone apply. The master curve keeps its end handles (black ≈ 0.03,
    white ≈ 0.94) and the inner points.
  - `LS 002`: Levels black 0.0 / gray 0.44 / white 0.88 (gray is the midpoint, as written). The
    master curve's black handle sits at ≈ 0.14. With "Overlay anzeigen" the red, green and blue
    curves have the expected shapes, which confirms the slot order `[master, R, G, B]`.
  - The curve channel menu offers Grau / Rot / Grün / Blau / Overlay anzeigen. There is no
    separate RGB entry, so the master channel is always shown as "Grau".
- **P-3.3, black point sign:**
  - Nitro: with `C Voreinstellung` applied, Black −1.0 crushes the shadows (the black phone on
    the wall turns pure black, a spike at the histogram's left edge), and +1.0 lifts them (no
    pure black left). The Black slider's range is ±1 in steps of 0.1 via the arrows.
  - Photomator: Schwarzpunkt +100 % darkens the phone and moves the histogram left, and −100 %
    lifts the blacks.
  - So the signs are **opposite**. Photomator +100 % looked weaker than Nitro −1.0; the scale
    is still open.
- Opening a `.nitropreset` with `open -a Nitro` does not import it. Nitro treats it as an image
  and asks for folder access.

## Nitro: N-1 `WB jpg`, N-2, N-3, N-4.2, N-6 (2026-11-23, via computer use)

- **`N1 WB jpg`** (IMG_6659.JPG): the untouched JPEG shows 5001 K / tint 10 (a nominal neutral,
  not as-shot data). Three clicks on each arrow give 7851 K / −43 (one click ≈ 950 K / 17.7
  tint), stored as `temperature: 7850.726`, `tint: -42.883476`; the image turns warmer. The
  JPEG's Tone panel has no Verstärkung, Schwarz, Weiß or Schatten verstärken.
- **`N2 curves slots`** (L1008408.DNG): points set with the E/A fields; master 0.25 → 0.40,
  Rot 0.5 → 0.7, Grün 0.5 → 0.3, Blau 0.75 → 0.9 → `pointsArray[0…3]` in that order.
  `operateOnGray: true` (the only mode the UI has), `maxValue: 2`, `histogramMaxValue: 1`.
- **`N2 curves range2`**: the same with the "1 | 2" toggle on 2 → only `histogramMaxValue: 2`
  changes. The graph then spans x = 0…2 with the white handle in the middle.
- **`N2 curves ends`**: black handle moved to 0 → 0.1, white handle to 1 → 0.9 in the UI.
  Stored as `{x:0, y:0.1, deletable:true}` and `{x:1, y:0.9, isWhitePoint:true}`.
- `N2 curves rgb` was not possible: the channel menu has only Grau / Rot / Grün / Blau /
  Overlay anzeigen. The colour-wheel button is "Auto RGB" and the half-filled circle is
  probably "Auto contrast".
- **`N3 max` / `N3 min`** (sliders dragged to their ends; slider limits, typed or arrow values
  were not tried):

  | adjustment | slider: min … max |
  |---|---|
  | White Balance | Temperatur 1000 … 20000 K, Farbstich −175 … 175 |
  | Tone | Verstärkung 0 … 1, Belichtung −3 … 3, Glanzlichter 0 … 1, Schatten −1 … 1, Mitteltöne 0.5 … 1.5, Schwarz −1 … 1, Weiß −1 … 1, Wiederherstellen −1 … 1, Schatten verstärken 0 … 1 |
  | Enhance | Tiefen 0 … ≈2, Lichter 0 … ≈2 (dragging reached 1.99), Kontrast 0 … 2, Sättigung 0 … 2, Farbdynamik −1 … 1 |
  | Detail | Klarheit −1 … 1, Schärfen −1 … 1, Bildrauschen 0 … 1 |
  | HSL (red) | Farbton −60 … 60, Sättigung / Luminanz / Bereich −1 … 1 |
  | Split-Farbtöne | wheel saturation 0 … 1, Luminanz −1 … 1, Balance 0 … 1 |
  | Vignette | Intensität −1 … 1, Radius 0 … 1 |

- **N-4.2** (DSC01548.ARW, Sony): `N4 sony tone` (exposure +0.6 from the image's own defaults)
  stores `baseBlackPoint: 3`, `baseWhitePoint: 0.35`, against 5 / 0.15 for the Leica M11. So the
  base values **depend on the camera** (and `decoderVersionString` is `9` instead of `9.dng`).
  `N4 sony applied` is the Sony after applying `C Voreinstellung` (a converted preset with
  base 5 / 0.15), saved again: it still has **3 / 0.35**, so Nitro keeps the image's own base
  values and ignores the preset's. (Its `blackPointDelta` is +0.13 because that preset was
  converted before the sign fix in step 15.)
- **N-6:** see the table in `sample-requests.md`.

## Nitro: N-7 `operateOnGray` (L1008408.DNG, 2026-11-23, via computer use)

Two hand-made presets, identical except for the flag: only `Curves`, master S-curve (0.25 →
0.08, 0.75 → 0.92), `N7 gray true` and `N7 gray false` in `nitro_sample_presets/` (shown in
Nitro as `gray true` / `gray false`). Each was applied with "Bearbeitungen ersetzen Modus" to
the unedited image (then *Original wiederherstellen*). Both give the same contrast, but
`gray true` is clearly more saturated (the wood turns orange, the food more colourful), as a curve
applied per RGB channel does, while `gray false` stays muted, as a brightness-only curve does.
So the UI's only mode (`true`) is the RGB curve, and the converter writes `false` only for a
Photomator luminance curve.

## Template for further samples

| preset | app | adjustment | slider (UI label) | UI value | note |
|---|---|---|---|---|---|
| | | | | | |
