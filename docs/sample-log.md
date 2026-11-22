# Sample log

UI values **as displayed** for the request presets (see [sample-requests.md](sample-requests.md)).
Decimal commas in the UI are written as dots here.

## Nitro: `N0 defaults` and `N1 all` (L1008408.DNG, Nitro 2026.09.01, created via computer use on 2026-11-22)

### Observations while creating them

- **Nothing to save without edits:** with no adjustment changed, *Sichern…* only shows an alert.
- **Enabled-but-neutral adjustments are not saved:** the save dialog lists only adjustments
  whose values differ from neutral. Enabling Tone/Enhance/Levels/Curves/HSL/… at defaults
  doesn't count; Black & White and Vignette do (they change the image even at default values).
- **Save dialog defaults:** it has one switch per changed adjustment. **Tone, Enhance and
  Detail are switched OFF by default**, LUT/Levels/Curves/RAW/WB/B&W/CA/Vignette/Split are ON.
  HSL did not appear in the list for `N1 all` (❓ check the file).
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

## Template for further samples

| preset | app | adjustment | slider (UI label) | UI value | note |
|---|---|---|---|---|---|
| | | | | | |
