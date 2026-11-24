# pxm2nitro

Converts Photomator / Pixelmator Pro adjustment presets (`.adjustments` packages) into
[Nitro](https://www.gentlemencoders.com/nitro/) presets (`.nitropreset`).

The format documentation and the Photomator → Nitro mapping live in [`docs/`](docs/README.md).

## What gets converted

Every preset is converted on its own. Whatever cannot be carried over exactly is listed per
preset (in the CLI output and in the app) as *approximated*, *uncalibrated* or *skipped*, and
the rest of the preset is still written. The preset intensity scales every converted value
toward neutral, and all values are clamped to Nitro's slider ranges (with a note when a value
is cut).

### Carried over exactly

| Photomator | Nitro |
|---|---|
| Curves: RGB, red, green, blue | Curves: master, red, green, blue (all points, including end points off 0/1); an RGB curve uses Nitro's per-channel mode |
| Curves: luminance (when RGB is unchanged) | Curves master in Nitro's brightness-only mode |
| Levels: black and white input per channel | Levels (same rule for RGB and luminance) |
| Channel Mixer | Channel Mixer, row by row |
| Light: exposure | Tone exposure (100 % = 1 EV, measured) |
| Light: black point | Tone Black (sign reversed; measured) |
| Color: saturation | Enhance saturation (raising measured; lowering 1:1, so −100 % stays grey) |

### Approximated

Converted with a measured scale, but Nitro's tone curve has a different shape, so the result
is close rather than equal (reported as *approximated*):

| Photomator | Nitro | Difference |
|---|---|---|
| Light: highlights (recovering) | Tone highlights | Nitro also darkens the midtones |
| Light: shadows | Tone shadows | Nitro reaches further into the midtones |
| Light: brightness | Tone midtones | Nitro lifts the shadows more |
| Light: contrast | Enhance contrast | Nitro also darkens and adds saturation |
| Levels gray, quarter and output handles | — | dropped; Nitro's Levels only has black and white input |

Converted with a placeholder scale that is not calibrated yet (reported as *uncalibrated*;
see [`docs/mapping.md`](docs/mapping.md) §3.1 for the measurements so far):

| Photomator | Nitro | Status |
|---|---|---|
| Light: clarity | Detail clarity | rough factor; Nitro's clarity is a weaker, local effect (its +1 ≈ Photomator +30 %) |
| Color: vibrance | Enhance vibrancy | no single factor fits: Nitro boosts muted colours more and strong ones less |
| Selective Color: hue, saturation, brightness | HSL per colour (Nitro's extra light blue gets the mean of cyan and blue) | not measured; the hue did not match on the test image |
| Sharpen: intensity | Detail sharpening | not measured |
| Vignette: strength (darkening or brightening) | Vignette intensity | not measured |
| Black & White: filter colour | Black & White channel weights | not measured |

### Dropped parts of converted adjustments

Reported as *skipped*, the rest of the adjustment is converted:

- Light: raised highlights (Nitro can only recover highlights) and texture
- Curves: the parametric sliders; the luminance curve when the RGB curve is also edited
- Color: hue (Nitro has no global hue shift)
- Sharpen: radius
- Vignette: softness and black point (Nitro's radius stays at its default)
- Black & White: toning, its own intensity, and the filter's luminance and saturation
- Preset properties outside the colour adjustments, such as a crop

### Not converted

Skipped with the reason:

| Photomator | Why |
|---|---|
| Fade | Nitro has no Fade |
| White Balance | Photomator stores a relative shift, Nitro absolute Kelvin |
| Color Balance | Nitro's Split Toning has no midtones wheel |
| Selective Clarity, Replace Color, Remove Color, Color Monochrome, Sepia, Invert | Nitro has no such adjustment |
| Grain | Nitro has no grain control |
| LUT | not converted yet |

## Build & run

Requires Swift 6 (Xcode 16 or newer) on macOS 14+.

```bash
swift build
swift test
swift run pxm2nitro --help
```

The package has three products:

- `PXM2NitroKit`: the conversion library
- `PXM2NitroUI`: the app's state and SwiftUI screens, shared by all platforms
- `pxm2nitro`: the command-line tool

## Mac app

Open `App/PXM2Nitro.xcodeproj` in Xcode and run the `PXM2Nitro` scheme. Drop
`.adjustments` files onto the window (or click to pick them), check what carries over, then
choose an output folder.

The app target only holds the `@main` entry point; everything else lives in `PXM2NitroUI`,
which also builds for iOS. To add an iPad/iPhone app later, add iOS as a supported
destination of the `PXM2Nitro` target (or a second target using the same `PXM2NitroUI`
product). The project uses synchronized folders, so new files in `App/PXM2Nitro/` need no
project edits.

## Installing converted presets

Nitro saves presets in:
`~/Library/Group Containers/group.com.gentlemencoders.nitro/Library/Application Support/My Preset`

`pxm2nitro` writes to a folder you choose. Copy the generated `.nitropreset` files into the
folder above and restart Nitro, which reads presets only at launch.
