#!/usr/bin/env bash
# extract_frames.sh
# Turn a video into a numbered, web-optimized frame sequence for a
# scroll-scrubbed animation (the "video opens as you scroll" effect).
#
# Usage:
#   ./extract_frames.sh INPUT [OUTDIR] [FPS] [HEIGHT] [FORMAT] [QUALITY]
#
#   INPUT    source video (mp4, mov, webm, ...)            (required)
#   OUTDIR   output directory for frames        (default: ./frames)
#   FPS      frames per second to extract        (default: 24)
#   HEIGHT   output height in px, width auto      (default: 1080)
#   FORMAT   webp | avif | png                    (default: webp)
#   QUALITY  encoder quality 0-100               (default: 80)
#
# Notes:
#   - 12 to 24 fps is plenty for scrubbed motion. More frames = more weight.
#   - WebP is ~80-90% smaller than PNG for these frames; AVIF smaller still.
#   - Black bars are auto-detected and cropped.
#   - Frame names are zero-padded (frame_0001.webp ...) so order is stable.
#   - After this, run crop_sequence.py to trim uniform transparent padding.

set -euo pipefail

INPUT="${1:?Usage: ./extract_frames.sh INPUT [OUTDIR] [FPS] [HEIGHT] [FORMAT] [QUALITY]}"
OUTDIR="${2:-./frames}"
FPS="${3:-24}"
HEIGHT="${4:-1080}"
FORMAT="${5:-webp}"
QUALITY="${6:-80}"

command -v ffmpeg >/dev/null 2>&1 || { echo "ffmpeg not found. Install it first."; exit 1; }
mkdir -p "$OUTDIR"

echo "Detecting crop (black bars)..."
CROP="$(ffmpeg -i "$INPUT" -vframes 30 -vf cropdetect -f null - 2>&1 \
  | grep -m1 -oP 'crop=\K[0-9:]+' || true)"

if [ -n "${CROP:-}" ]; then
  VF="crop=${CROP},fps=${FPS},scale=-2:${HEIGHT}:flags=lanczos"
  echo "Using crop=${CROP}"
else
  VF="fps=${FPS},scale=-2:${HEIGHT}:flags=lanczos"
  echo "No crop detected; continuing without crop."
fi

OUTPATH="${OUTDIR}/frame_%04d.${FORMAT}"
echo "Extracting ${FPS} fps at ${HEIGHT}px as ${FORMAT} (q=${QUALITY}) ..."

case "$FORMAT" in
  webp) ffmpeg -y -i "$INPUT" -vf "$VF" -c:v libwebp -quality "$QUALITY" -compression_level 6 "$OUTPATH" ;;
  avif) ffmpeg -y -i "$INPUT" -vf "$VF" -c:v libaom-av1 -crf $((63 - QUALITY * 63 / 100)) -still-picture 1 "$OUTPATH" ;;
  png)  ffmpeg -y -i "$INPUT" -vf "$VF" "$OUTPATH" ;;
  *)    echo "Unknown FORMAT '$FORMAT' (use webp | avif | png)"; exit 1 ;;
esac

COUNT="$(find "$OUTDIR" -maxdepth 1 -name "frame_*.${FORMAT}" | wc -l | tr -d ' ')"
SIZE="$(du -sh "$OUTDIR" | cut -f1)"
echo "Done. ${COUNT} frames in ${OUTDIR} (${SIZE} total)."
echo "frameCount = ${COUNT}  -> use in your scroll mapping."
echo "Tip: export a smaller set (e.g. HEIGHT=720) for mobile."
