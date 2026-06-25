#!/usr/bin/env python3
"""crop_sequence.py

Trim a single, uniform bounding box across an entire image sequence so every
frame registers (aligns) perfectly and files shrink. Exported frames often carry
transparent or solid-color padding that differs slightly per frame; cropping each
frame independently would make the animation jitter. This computes one box that
fits the content of every frame, then crops them all identically.

Usage:
    python3 crop_sequence.py INDIR [OUTDIR] [--pad N] [--bg auto|alpha|RRGGBB] [--thresh T]

    INDIR    folder of frames (frame_0001.webp ...)            (required)
    OUTDIR   output folder                     (default: INDIR + "_cropped")
    --pad    extra pixels to keep around content              (default: 0)
    --bg     how to detect background:
                alpha   use the alpha channel (default for RGBA)
                auto    sample the top-left pixel as background color
                RRGGBB  explicit hex background color
    --thresh difference threshold 0-255 for "is background"   (default: 10)

Requires: Pillow  ->  pip install --break-system-packages pillow
"""
import argparse
import os
import sys
from PIL import Image, ImageChops


def content_bbox(im, mode, thresh):
    if mode == "alpha" and im.mode in ("RGBA", "LA"):
        alpha = im.getchannel("A")
        # bbox of anything not fully transparent
        return alpha.point(lambda a: 255 if a > thresh else 0).getbbox()
    # color-difference path
    rgb = im.convert("RGB")
    if mode == "auto":
        bg = rgb.getpixel((0, 0))
    else:
        bg = tuple(int(mode[i:i + 2], 16) for i in (0, 2, 4))
    bg_img = Image.new("RGB", rgb.size, bg)
    diff = ImageChops.difference(rgb, bg_img).convert("L")
    return diff.point(lambda d: 255 if d > thresh else 0).getbbox()


def union(a, b):
    if a is None:
        return b
    if b is None:
        return a
    return (min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3]))


def main():
    p = argparse.ArgumentParser()
    p.add_argument("indir")
    p.add_argument("outdir", nargs="?")
    p.add_argument("--pad", type=int, default=0)
    p.add_argument("--bg", default="alpha")
    p.add_argument("--thresh", type=int, default=10)
    args = p.parse_args()

    indir = args.indir
    outdir = args.outdir or (indir.rstrip("/\\") + "_cropped")
    os.makedirs(outdir, exist_ok=True)

    exts = (".png", ".webp", ".jpg", ".jpeg", ".avif")
    files = sorted(f for f in os.listdir(indir) if f.lower().endswith(exts))
    if not files:
        sys.exit("No images found in " + indir)

    print("Pass 1: computing union content box across {} frames ...".format(len(files)))
    box = None
    size = None
    for f in files:
        with Image.open(os.path.join(indir, f)) as im:
            size = im.size
            box = union(box, content_bbox(im, args.bg, args.thresh))
    if box is None:
        sys.exit("Could not detect content; check --bg/--thresh.")

    x0, y0, x1, y1 = box
    if args.pad:
        x0 = max(0, x0 - args.pad); y0 = max(0, y0 - args.pad)
        x1 = min(size[0], x1 + args.pad); y1 = min(size[1], y1 + args.pad)
    box = (x0, y0, x1, y1)
    print("Crop box: {}  ({}x{} -> {}x{})".format(
        box, size[0], size[1], x1 - x0, y1 - y0))

    print("Pass 2: cropping ...")
    for f in files:
        with Image.open(os.path.join(indir, f)) as im:
            im.crop(box).save(os.path.join(outdir, f))
    print("Done. Cropped frames in {}".format(outdir))


if __name__ == "__main__":
    main()
