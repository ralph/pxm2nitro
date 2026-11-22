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

The package has two products:

- `PXM2NitroKit`: the conversion library (reused later by a SwiftUI app)
- `pxm2nitro`: the command-line tool

## Installing converted presets

Nitro saves presets in:
`~/Library/Group Containers/group.com.gentlemencoders.nitro/Library/Application Support/My Preset`

`pxm2nitro` writes to a folder you choose. Copy the generated `.nitropreset` files into the
folder above and restart Nitro, which reads presets only at launch.
