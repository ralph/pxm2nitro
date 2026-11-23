#!/usr/bin/env python3
"""Measure how much an adjustment changes an editor's preview, from screenshots.

Usage:
    python3 -I screenshot_response.py <base.jpg> <label>=<adjusted.jpg> [...]

Each image is a capture of the same preview region (same app, same zoom), once without
and once with the adjustment. For the pixels whose linear luminance lies between 0.02 and
0.35 in the base capture (and is not near white in the adjusted one), the script prints the
median change in log2 luminance (displayed stops), plus the mean luminance and saturation
before and after. Comparing these numbers between Photomator and Nitro at several slider
values gives the scale factor (`docs/mapping.md` §3.1).

Needs only numpy; images are decoded with macOS `sips`.
"""
import os, struct, subprocess, sys, tempfile

import numpy as np


def load(path):
    """RGB in [0, 1], decoded through `sips` to an uncompressed BMP."""
    fd, tmp = tempfile.mkstemp(suffix=".bmp")
    os.close(fd)
    try:
        subprocess.run(["sips", "-s", "format", "bmp", path, "--out", tmp], check=True, capture_output=True)
        data = open(tmp, "rb").read()
    finally:
        os.remove(tmp)
    offset = struct.unpack_from("<I", data, 10)[0]
    width, height = struct.unpack_from("<ii", data, 18)
    channels = struct.unpack_from("<H", data, 28)[0] // 8
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
    for spec in specs:
        label, path = spec.split("=", 1)
        adjusted = load(path)
        adjusted_l = luminance(adjusted)
        mask = (base_l > 0.02) & (base_l < 0.35) & (adjusted_l < 0.9)
        stops = np.median(np.log2(adjusted_l[mask] / base_l[mask]))
        print(f"{label}: {stops:+.3f} stops  mean L {base_l.mean():.3f} -> {adjusted_l.mean():.3f}  "
              f"saturation {saturation(base).mean():.3f} -> {saturation(adjusted).mean():.3f}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    main(*sys.argv[1:])
