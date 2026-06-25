# Asset pipeline: sourcing, creating, converting, optimizing

Where to get the graphics and 3D artifacts these sites are built from, how to make your own,
and how to convert and compress everything for the web. Unoptimized assets are the number
one reason immersive sites feel slow, so this stage is not optional.

## Table of contents
1. Where to source 3D models, HDRIs, textures
2. Licensing checklist
3. Creating and editing assets
4. Video to scroll-frame sequence
5. 3D model optimization (glTF / GLB)
6. HDRI and texture prep
7. Modern image formats
8. Delivery

## 1. Where to source assets

3D models:
- **Sketchfab**: largest searchable library with a live 3D preview so you can inspect
  topology before downloading. Mixed licenses, many GLB/glTF downloads. Check each license.
- **Poly Haven**: CC0 (no attribution, any use), consistently production-grade models,
  textures, and HDRIs. The safest default for commercial work.
- **Poly Pizza**: clean low-poly models (the Google Poly archive), ideal for lightweight
  WebGL.
- **Quaternius**: free game-ready low-poly packs, CC0.
- **Fab (Epic)**, **TurboSquid**, **CGTrader**: marketplaces with free sections; quality
  varies, watch formats and licenses.
- **Quixel Megascans / Quixel Bridge**: photoreal scanned assets and materials.
- **Smithsonian Open Access**, **NASA 3D**, museum scans: real artifacts, CC0/mixed.

HDRIs (for lighting and reflections):
- **Poly Haven** (formerly HDRI Haven): CC0, up to 16k, the standard. Use the 1k or 2k.
- **ambientCG**: CC0 HDRIs and PBR materials.

Textures / PBR materials:
- **ambientCG**, **3dtextures.me**, **Texture Ninja** (public domain / CC0),
  **textures.com** (limited free), **Polligon**, **Texturelabs**.

Characters and animation:
- **Mixamo** (Adobe): free rigged characters, auto-rigger, and a large free animation
  library; export FBX, then convert to GLB.

Curated meta-directories: **3dassets.one** and the community **3d-resources** hub aggregate
many of the above with license filters.

## 2. Licensing checklist

Always verify before shipping to a client:
- **CC0 / public domain**: any use, no attribution. Safest (Poly Haven, ambientCG,
  Quaternius, Poly Pizza).
- **CC-BY**: free but requires crediting the author. Keep a credits file.
- **CC-NC**: non-commercial only. Do not use in client/commercial work.
- **Marketplace / royalty-free**: read the specific EULA; some forbid redistribution or
  require a per-seat/per-project license.
- Keep a `CREDITS.md` listing every asset, its source URL, author, and license. This
  protects the client and is standard professional practice.

## 3. Creating and editing assets

- **Blender** (free): model, sculpt, UV, bake, and export GLB. The default DCC for web 3D.
  Bake lighting/AO into textures when you want a rich look without runtime cost.
- **Spline**: browser-based 3D editor for non-coders/designers; exports a web runtime or a
  GLB. Good when a client wants to art-direct the scene.
- **Cinema 4D / After Effects**: render a 3D animation to an image sequence for the
  scroll-scrub technique (this is how many "Apple-style" sequences are produced). C4D Lite
  ships free inside After Effects.
- **Procedural/gradient art**: generate gradient meshes, noise fields, and shader art in
  code (GLSL) rather than shipping large images.
- **AI generation**: text-to-3D tools exist but verify license and clean up topology in
  Blender before use.

For the scroll-sequence approach, you do not need a 3D model at all if you have a video or a
pre-rendered animation: split it into frames (next section).

## 4. Video to scroll-frame sequence

Use `scripts/extract_frames.sh` (ffmpeg). Core commands:

```bash
# extract at 24 fps, scale to 1080p height, zero-padded names
ffmpeg -i input.mp4 -vf "fps=24,scale=-1:1080" frames/frame_%04d.png

# auto-detect and crop black bars first
crop=$(ffmpeg -i input.mp4 -vframes 10 -vf cropdetect -f null - 2>&1 | grep -m1 -oP 'crop=\K[0-9:]+')
ffmpeg -i input.mp4 -vf "crop=$crop,fps=24,scale=-1:1080" frames/frame_%04d.png

# convert the PNG sequence to WebP (smaller; AVIF smaller still)
for f in frames/*.png; do ffmpeg -i "$f" -quality 80 "${f%.png}.webp"; done
```

Then run `scripts/crop_sequence.py` to trim a single uniform bounding box across all frames
so they register and shrink further. Guidance:
- 12 to 24 fps is enough for scrubbed motion; do not extract every frame.
- Export 2 to 3 resolutions for responsive serving.
- See `references/scroll-frame-sequence.md` for how the frames are wired to scroll.

## 5. 3D model optimization (glTF / GLB)

GLB (binary glTF) is the web delivery format. Convert anything else first, then optimize
with **gltf-transform** (see `scripts/optimize_glb.sh`).

```bash
npm i -g @gltf-transform/cli

# convert to GLB
gltf-transform copy model.fbx model.glb

# full pipeline: prune unused, dedup, Draco geometry, KTX2 textures
gltf-transform optimize model.glb out.glb --texture-compress ktx2 --compress draco

# or step by step for control
gltf-transform prune model.glb a.glb
gltf-transform dedup a.glb b.glb
gltf-transform resize b.glb c.glb --width 1024 --height 1024
gltf-transform draco c.glb d.glb --method edgebreaker
gltf-transform uastc d.glb e.glb --slots "{normalTexture}" --level 4
gltf-transform etc1s e.glb final.glb --quality 200
```

What each does and why:
- **Draco**: compresses geometry 90 to 95 percent. Decoding happens in a Web Worker so it
  does not block the main thread. Requires the Draco decoder served at `/draco/`.
- **Meshopt** (`gltf-transform meshopt`): alternative geometry compression that also handles
  morph targets and keyframe animation; pairs with the meshopt decoder.
- **KTX2 / Basis Universal**: GPU texture format that stays compressed in VRAM. A 200KB PNG
  can occupy 20MB+ of VRAM uncompressed; KTX2 cuts memory roughly 10x. Two codecs:
  - **UASTC**: higher quality/larger. Use for normal maps and hero textures.
  - **ETC1S**: smaller/lower quality. Use for diffuse and secondary textures.
  Requires the Basis transcoder served at `/basis/`.
- **resize**: cap texture dimensions (1024 or 2048 is usually plenty for web).
- **prune/dedup**: remove unused nodes/materials and duplicate data.

Rule: a 50MB GLB will destroy load time no matter how good the rendering code is. Optimize
first.

## 6. HDRI and texture prep

- Downscale HDRIs to 1k or 2k for reflections; 16k is for offline renders, never the web.
- Keep one environment map for the whole scene; it lights all PBR materials.
- Compress regular textures to WebP/AVIF, or KTX2 when bundled in a GLB.
- Generate mipmaps (loaders do this) and use power-of-two sizes where it matters.

## 7. Modern image formats

- **WebP**: roughly 25 to 35 percent smaller than JPEG, far smaller than PNG for UI and
  frames; near-universal support. Default for 2D images and frame sequences.
- **AVIF**: smaller again at similar quality; excellent for hero images and frames where
  support is acceptable. Offer WebP fallback.
- **KTX2**: for GPU textures inside 3D models (not for `<img>`).
- Use `<picture>` with AVIF then WebP then JPEG sources for resilient delivery.

## 8. Delivery

- Serve frames and assets over **HTTP/2 or HTTP/3** so many requests multiplex; HTTP/1.1
  will bottleneck a frame sequence.
- **Preload** the hero model and first frame: `<link rel="preload" as="fetch"
  href="/model.glb" crossorigin>`.
- Host Draco and Basis decoders locally under `/draco/` and `/basis/` and set the loader
  paths; do not rely on a third-party CDN for these in production.
- Cache aggressively with hashed filenames.
