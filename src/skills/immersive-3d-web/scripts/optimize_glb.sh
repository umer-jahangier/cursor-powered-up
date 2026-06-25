#!/usr/bin/env bash
# optimize_glb.sh
# Optimize a 3D model for the web with gltf-transform: convert to GLB,
# prune/dedup, compress geometry (Draco), and compress textures (KTX2).
# A large GLB is the number one cause of slow 3D sites; run this first.
#
# Usage:
#   ./optimize_glb.sh INPUT [OUTPUT] [TEXTURE_SIZE]
#
#   INPUT         model file (.glb .gltf .fbx .obj)        (required)
#   OUTPUT        output .glb               (default: <input>.opt.glb)
#   TEXTURE_SIZE  max texture dimension     (default: 1024)
#
# Requires: Node + gltf-transform CLI
#   npm i -g @gltf-transform/cli
#
# Decoders to serve in your app (loader paths /draco/ and /basis/):
#   - Draco decoder: from three/examples/jsm/libs/draco/
#   - Basis transcoder (KTX2): from three/examples/jsm/libs/basis/

set -euo pipefail

INPUT="${1:?Usage: ./optimize_glb.sh INPUT [OUTPUT] [TEXTURE_SIZE]}"
BASE="${INPUT%.*}"
OUTPUT="${2:-${BASE}.opt.glb}"
TEX="${3:-1024}"

command -v gltf-transform >/dev/null 2>&1 || {
  echo "gltf-transform not found. Install with: npm i -g @gltf-transform/cli"; exit 1; }

TMP="$(mktemp -d)"
GLB="${TMP}/model.glb"

ext="${INPUT##*.}"
if [ "$ext" = "glb" ]; then
  cp "$INPUT" "$GLB"
else
  echo "Converting ${ext} -> glb ..."
  gltf-transform copy "$INPUT" "$GLB"
fi

echo "Reporting original ..."
gltf-transform inspect "$GLB" | sed -n '1,20p' || true

echo "Optimizing (prune, dedup, resize ${TEX}, Draco geometry, KTX2 textures) ..."
gltf-transform optimize "$GLB" "$OUTPUT" \
  --texture-compress ktx2 \
  --texture-size "$TEX" \
  --compress draco \
  --prune true \
  --dedup true || {
    echo "optimize bundle failed; running steps individually ..."
    gltf-transform prune "$GLB" "${TMP}/a.glb"
    gltf-transform dedup "${TMP}/a.glb" "${TMP}/b.glb"
    gltf-transform resize "${TMP}/b.glb" "${TMP}/c.glb" --width "$TEX" --height "$TEX"
    gltf-transform draco "${TMP}/c.glb" "${TMP}/d.glb" --method edgebreaker
    gltf-transform etc1s "${TMP}/d.glb" "$OUTPUT" --quality 200
  }

BEFORE="$(du -h "$INPUT" | cut -f1)"
AFTER="$(du -h "$OUTPUT" | cut -f1)"
echo "Done. ${INPUT} (${BEFORE}) -> ${OUTPUT} (${AFTER})"
echo "Remember to wire DRACOLoader('/draco/') and KTX2Loader('/basis/') in your app."
rm -rf "$TMP"
