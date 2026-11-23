#!/usr/bin/env python3
"""Measure how much an adjustment changes an editor's preview, from screenshots.

Usage:
    python3 -I screenshot_response.py <base.jpg> <label>=<adjusted.jpg> [...]

Each image is a capture of the same preview region (same app, same zoom), once without
and once with the adjustment. For the pixels whose linear luminance lies between 0.02 and
0.35 in the base capture (and is neither black nor near white in any adjusted one; the same
pixels are used for every label), the script prints the
median change in log2 luminance (displayed stops), plus the mean luminance and saturation
before and after. Comparing these numbers between Photomator and Nitro at several slider
values gives the scale factor (`docs/mapping.md` §3.1).

Needs only numpy; images are decoded with macOS `sips`.
"""
import os, struct, subprocess, sys, tempfile

import numpy as np

SRGB_PROFILE = "/System/Library/ColorSync/Profiles/sRGB Profile.icc"


def load(path):
    """RGB in [0, 1], decoded through `sips` to an uncompressed BMP."""
    fd, tmp = tempfile.mkstemp(suffix=".bmp")
    os.close(fd)
    try:
        # Screenshots are tagged Display P3; match to sRGB so the sRGB luminance formula holds.
        subprocess.run(["sips", "-m", SRGB_PROFILE, "-s", "format", "bmp", path, "--out", tmp],
                       check=True, capture_output=True)
        with open(tmp, "rb") as f:
            data = f.read()
    finally:
        os.remove(tmp)
    offset = struct.unpack_from("<I", data, 10)[0]
    width, height = struct.unpack_from("<ii", data, 18)
    bits = struct.unpack_from("<H", data, 28)[0]
    if bits not in (24, 32):
        sys.exit(f"{path}: unsupported {bits}-bit BMP from sips")
    channels = bits // 8
    stride = (width * channels + 3) & ~3
    rows = np.frombuffer(data, np.uint8, count=stride * abs(height), offset=offset)
    pixels = rows.reshape(abs(height), stride)[:, :width * channels].reshape(abs(height), width, channels)
    rgb = pixels[:, :, [2, 1, 0]].astype(np.float64) / 255
    return rgb[::-1] if height > 0 else rgb


def luminance(rgb):
    linear = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    return linear @ [0.2126, 0.7152, 0.0722]


def saturation(rgb):
    high, low = rgb.max(-1), rgb.min(-1)
    return np.where(high > 0, (high - low) / np.maximum(high, 1e-6), 0)


def main(base_path, *specs):
    base = load(base_path)
    base_l = luminance(base)
    captures = []
    for spec in specs:
        label, path = spec.split("=", 1)
        adjusted = load(path)
        if adjusted.shape != base.shape:
            sys.exit(f"{path}: size {adjusted.shape[1]}x{adjusted.shape[0]} differs from base "
                     f"{base.shape[1]}x{base.shape[0]}")
        captures.append((label, adjusted, luminance(adjusted)))
    # One pixel set for all labels: midtones in the base that stay unclipped (and non-black) in
    # every capture. A per-capture mask would drop the brightest midtones only at high values
    # and bias those medians low.
    mask = (base_l > 0.02) & (base_l < 0.35)
    for _, _, adjusted_l in captures:
        mask &= (adjusted_l > 0) & (adjusted_l < 0.9)
    if not mask.any():
        sys.exit("no midtone pixels (base luminance 0.02-0.35) stay unclipped in all captures")
    print(f"{mask.sum()} pixels ({mask.mean():.1%} of the region)")
    for label, adjusted, adjusted_l in captures:
        stops = np.median(np.log2(adjusted_l[mask] / base_l[mask]))
        print(f"{label}: {stops:+.3f} stops  mean L {base_l.mean():.3f} -> {adjusted_l.mean():.3f}  "
              f"saturation {saturation(base).mean():.3f} -> {saturation(adjusted).mean():.3f}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    main(*sys.argv[1:])
