---
name: immersive-3d-web
description: >
  Build highly interactive, immersive 3D websites: scroll-driven storytelling, glassy /
  glassmorphic UI, WebGL and Three.js scenes, custom GLSL shaders, and the "scroll-scrubbed
  video" effect where a clip is split into image frames that advance frame-by-frame as the
  user scrolls (Apple AirPods Pro style). Use whenever the user wants a 3D website, an
  immersive or "wow factor" landing page, scroll-based 3D animation, a frame-by-frame scroll
  video, parallax or scrollytelling, WebGL shader effects, glass / refraction / liquid
  materials, page transitions, or Awwwards-style creative sites, or references sites like
  trionn.com, obys.agency, organimo.com, aorum.io, nymphaicosmetics.com, fanalis.in, or
  icare-game.world. Also use for turning a video into a scroll sequence, sourcing and optimizing 3D assets (glTF / GLB / Draco / KTX2), or wiring smooth scroll
  (Lenis) with GSAP ScrollTrigger. Trigger even when the user only says "make my site feel
  premium / 3D / cinematic / interactive" without naming the technique.
---

# Immersive 3D Web

Author production-grade immersive websites. This is the genre behind award sites such as
trionn.com and the Obys experiments: smooth inertia scroll, real WebGL depth, glass and
refraction, custom shaders, scroll-scrubbed image sequences, and choreographed page
transitions, all held to a strict performance budget so the experience stays at 60fps and
degrades gracefully on weak hardware.

This file is the router. It decides the approach, names the stack, and lays out the
workflow. Deep technical detail and copy-paste code live in `references/`, `scripts/`, and
`assets/`. Read the reference for the technique in play before writing code; each one
encodes failure modes that are easy to hit blind.

## Step 0: classify the request

Pick the approach before touching code. Most "immersive" requests fall into one of three
buckets, and they have very different cost and risk profiles.

| Signal in the request | Approach | Primary tooling | Start here |
|---|---|---|---|
| "Video that plays as I scroll", "frames open on scroll", product reveal, AirPods style | Scroll-scrubbed frame sequence | Canvas 2D + GSAP ScrollTrigger, frames as WebP/AVIF | `references/scroll-frame-sequence.md` |
| "3D model I can see/rotate", scene with depth, particles, glass objects, shader art | Real-time WebGL scene | Three.js or React Three Fiber + drei + postprocessing | `references/threejs-and-shaders.md` |
| "Whole site feels alive", agency/Awwwards vibe, sections morph, camera flies on scroll | Hybrid scrollytelling | Lenis + GSAP + a persistent WebGL canvas behind the DOM | `references/scroll-and-transitions.md` |

Rules of thumb:

- A pre-baked animation that only needs to scrub forward and back on scroll is almost
  always cheaper, smoother, and more reliable as a frame sequence than as live 3D. Reach
  for real 3D only when the user needs interactivity (rotate, hover, configure), genuine
  depth/parallax, or effects that cannot be pre-rendered.
- "Glassy" is two different things. Flat UI panels behind content use CSS
  `backdrop-filter` (cheap). 3D objects that bend light use a WebGL transmission/refraction
  material (expensive). Confirm which one. See `references/glass-and-materials.md`.
- If the user named a reference site, study its anatomy first via
  `references/reference-gallery.md` and replicate the technique, not the assets.

When the brief is vague ("make it premium"), do not over-ask. Propose one concrete
direction with a named technique and one fallback, then build.

## The canonical stack

This is the modern, battle-tested toolkit for this genre. Prefer it unless the user has a
fixed stack.

- Rendering: **Three.js** (vanilla) or **React Three Fiber (R3F)** for React/Next.js
  projects. R3F pairs with **@react-three/drei** (helpers: loaders, controls,
  `MeshTransmissionMaterial`, `Environment`, `Float`, `Text3D`) and
  **@react-three/postprocessing** (bloom, DOF, chromatic aberration, vignette, noise).
- Motion: **GSAP** + **ScrollTrigger** is the backbone for scroll-bound timelines and
  scrubbing. **GSAP ScrollSmoother** or **Lenis** provides inertia smooth scroll. Use one
  smoother only, never two.
- Smooth scroll: **Lenis** (`@studio-freight/lenis`, now `lenis`) is the default for
  vanilla and React. Sync its `raf` to GSAP's ticker so DOM and WebGL move on the same
  clock (see `references/scroll-and-transitions.md`).
- Page transitions (multi-page): **Barba.js**, or the native **View Transitions API**
  where browser support is acceptable.
- Lightweight WebGL alternative: **OGL** or **curtains.js** when the project only needs a
  few shader planes mapped to DOM images and Three.js is overkill.
- Declarative 3D editor: **Spline** when the client wants to art-direct without code; it
  exports a runtime or a GLB.
- Shaders: raw **GLSL** for vertex/fragment effects. In R3F, wire uniforms via
  `useFrame`; in vanilla via `material.uniforms.uTime.value = clock`.
- Build: **Vite** for vanilla, **Next.js** for React. Lazy-load the WebGL bundle so it
  never blocks first paint.
- Emerging: a **WebGPU** renderer path exists in current Three.js. Treat it as
  progressive enhancement with a WebGL fallback, not the default, in 2026.

Install reference for a fresh R3F project:
```bash
npm create vite@latest my-site -- --template react
npm i three @react-three/fiber @react-three/drei @react-three/postprocessing
npm i gsap lenis
```

## The end-to-end workflow

Follow these phases in order. Each maps to a reference and, where useful, a script.

**1. Direction and reference teardown.** Confirm the approach from Step 0. If a reference
site was given, open `references/reference-gallery.md` and record the specific techniques
to copy (scroll behavior, materials, transitions, color/typography mood). Decide the
art-direction: palette, type, motion personality (snappy vs floaty), and the one "hero
moment" the whole page builds toward.

**2. Source and prepare assets.** Use `references/asset-pipeline.md` for where to get
models, HDRIs, and textures (Poly Haven, Sketchfab, Poly Pizza, Quaternius, Mixamo,
ambientCG, Quixel, Spline) and the licensing checklist. Then optimize ruthlessly:
  - 3D models: run `scripts/optimize_glb.sh` (gltf-transform: prune, dedup, draco, KTX2).
  - Scroll video: run `scripts/extract_frames.sh` to split the clip into a numbered WebP
    or AVIF sequence, then `scripts/crop_sequence.py` to trim uniform transparent padding
    so every frame aligns.
  - HDRIs: downsize to the smallest resolution that still reads (1k-2k is plenty for
    reflections); convert to `.hdr` or compressed env maps.

**3. Scaffold scene and scroll.** Stand up the canvas and the smooth-scroll loop on one
clock. For real 3D start from `assets/r3f-scroll-starter.jsx`. For a frame sequence start
from `assets/canvas-sequence-starter.html`. Verify the empty scene holds 60fps before
adding content.

**4. Choreograph motion.** Build a single master GSAP timeline (or a small set of
ScrollTriggers) that drives camera, materials, and DOM together. Pin the hero section so
the sequence reads as a scene, not a jump. Keep scroll handlers off the main work: write
to refs/uniforms in `useFrame`/`onUpdate`, never trigger layout in a scroll callback.

**5. Materials and post.** Apply glass/refraction, lighting from the HDRI environment, and
a restrained postprocessing chain (selective bloom by lifting emissive colors above 1, a
touch of chromatic aberration, subtle film grain). See `references/glass-and-materials.md`
and `references/threejs-and-shaders.md`. More passes is not more premium; restraint is.

**6. Performance and accessibility pass.** This is mandatory, not optional. Hold the
budget in `references/performance-and-a11y.md`: dispose GPU resources on unmount, cap pixel
ratio, instance repeated geometry, lazy-load below the fold, respect
`prefers-reduced-motion`, keep real content in the DOM for SEO and screen readers, and ship
a non-WebGL fallback. Test on a mid-tier phone, not just the dev machine.

**7. Ship.** Serve frames and assets over HTTP/2+, preload the first frame and the hero
model, and set a low-res poster as the LCP element so the page never shows blank canvas.

## Hard rules (these protect the experience)

- **60fps or it is broken.** A janky immersive site is worse than a clean static one. If a
  technique cannot hold frame rate on target hardware, cut it or pre-bake it.
- **Never block first paint with WebGL.** The 3D bundle and assets load after a usable
  page exists. Show a poster/first-frame immediately.
- **Content lives in real DOM.** WebGL is decoration over an accessible, crawlable page.
  Headings, copy, and links must exist as HTML.
- **One scroll authority.** Either ScrollSmoother or Lenis drives scrolling, and GSAP and
  WebGL read from it. Competing scroll systems cause stutter and drift.
- **Optimize assets before wiring them.** An unoptimized 50MB GLB or a folder of full-size
  PNG frames will sink the page no matter how good the code is.
- **Always provide reduced-motion and no-WebGL paths.** Some users need them; some devices
  force them.

## Reference index

- `references/scroll-frame-sequence.md` — the scroll-scrubbed video/frame technique end to
  end: canvas vs video vs CSS, frame math, preloading, GSAP scrub, sticky/pin layout,
  responsive frame sets, and the common bugs (strobing, full-page scrub, jitter).
- `references/threejs-and-shaders.md` — Three.js and R3F scene setup, loaders, lighting,
  environment maps, custom GLSL (uniforms, time, scroll), instancing, and the drei/post
  helpers.
- `references/scroll-and-transitions.md` — Lenis + GSAP ScrollTrigger sync, pinning,
  scrub, parallax, syncing DOM elements to WebGL planes, and page transitions (Barba /
  View Transitions).
- `references/glass-and-materials.md` — CSS glassmorphism vs WebGL glass: backdrop-filter
  recipes, `MeshTransmissionMaterial` and `MeshRefractionMaterial`, IOR/thickness/
  chromatic aberration, frosted normals, and selective bloom.
- `references/asset-pipeline.md` — sourcing graphics and 3D assets (with licenses),
  ffmpeg frame extraction, gltf-transform optimization, KTX2/Draco/meshopt, HDRI prep,
  and modern image formats.
- `references/performance-and-a11y.md` — the performance budget, Core Web Vitals for
  heavy sites, memory/dispose discipline, mobile strategy, reduced-motion, SEO, and
  graceful degradation.
- `references/reference-gallery.md` — how to reverse-engineer any immersive site, plus a
  technique-by-technique read on the named reference sites.

## Scripts and assets

- `scripts/extract_frames.sh` — video to numbered WebP/AVIF frame sequence (fps, scale,
  crop-detect, sequential naming).
- `scripts/optimize_glb.sh` — full gltf-transform optimization pipeline for a GLB.
- `scripts/crop_sequence.py` — trim a uniform bounding box across an image sequence so
  frames register perfectly (Pillow).
- `assets/canvas-sequence-starter.html` — drop-in vanilla canvas scroll sequence with
  preloading and GSAP scrub.
- `assets/r3f-scroll-starter.jsx` — R3F scene with Lenis smooth scroll, scroll-driven
  camera, a glass object, environment lighting, and selective bloom.
