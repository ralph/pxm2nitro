#!/usr/bin/env python3
"""Reference decoder for Photomator / Pixelmator Pro `.adjustments` packages.

Usage:
    python3 -I decode_photomator.py <package.adjustments | Adjustments.library> [--raw] [--all]

Prints, per preset, the enabled adjustment blocks with version containers unwrapped.
--raw   print the full decoded ColorAdjustmentData (ICC blobs elided)
--all   include disabled blocks
"""
import json, os, plistlib, sys

def unwrap(x):
    """Remove both version-container styles recursively."""
    if isinstance(x, list):
        if len(x) == 2 and isinstance(x[0], int) and isinstance(x[1], dict):
            return unwrap(x[1])
        return [unwrap(i) for i in x]
    if isinstance(x, dict):
        if set(x) == {"version", "versionSpecifiContainer"}:
            return unwrap(x["versionSpecifiContainer"])
        return {k: ("<ICC %d chars>" % len(v) if k == "icc" else unwrap(v)) for k, v in x.items()}
    return x

def load_package(path):
    order = []
    for c in sorted(os.listdir(os.path.join(path, "collections"))):
        col = plistlib.load(open(os.path.join(path, "collections", c), "rb"))
        order += [(col.get("name"), pid) for pid in col.get("presets-list", [])]
    for coll, pid in order:
        f = os.path.join(path, "presets", pid + ".plist")
        if os.path.exists(f):
            yield coll, plistlib.load(open(f, "rb"))

def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    raw, show_all = "--raw" in sys.argv, "--all" in sys.argv
    for coll, preset in load_package(args[0]):
        print("=== %s / %s  (%s)" % (coll, preset["name"], preset["id"]))
        for prop in preset.get("properties", []):
            v = prop["value"]
            if prop["key"] != "ColorAdjustmentData":
                print("  other property:", prop["key"], type(v).__name__)
                continue
            root_version = json.loads(v)[0]
            data = unwrap(json.loads(v))
            if raw:
                print(json.dumps(data, indent=1, sort_keys=True))
                continue
            print("  root v%d  intensity(in)=%s" % (root_version, data.get("in")))
            for k, blk in sorted(data.items()):
                if isinstance(blk, dict) and "E" in blk and (show_all or blk["E"] in (1, True)):
                    body = {kk: vv for kk, vv in blk.items() if kk not in ("E", "V")}
                    print("  %-3s %s" % (k, json.dumps(body, separators=(",", ":"))))

if __name__ == "__main__":
    main()
