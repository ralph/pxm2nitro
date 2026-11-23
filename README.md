# pxm2nitro

Converts Photomator / Pixelmator Pro adjustment presets (`.adjustments` packages) into
[Nitro](https://www.gentlemencoders.com/nitro/) presets (`.nitropreset`).

The format documentation and the Photomator → Nitro mapping live in [`docs/`](docs/README.md).

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
