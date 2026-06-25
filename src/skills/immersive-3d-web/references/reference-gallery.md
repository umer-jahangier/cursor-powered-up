# Reference gallery: reading and reverse-engineering immersive sites

The named sites (trionn.com, obys.agency and experiment.obys.agency, organimo.com, aorum.io,
ciaoenergy.com, nymphaicosmetics.com, fanalis.in, icare-game.world) belong to one genre:
creative-agency / Awwwards-style immersive WebGL scrollytelling. They look bespoke, but they
are assembled from the same small toolbox this skill covers. The skill is to identify which
techniques a site uses and rebuild those, never to copy its assets or code.

## 1. How to reverse-engineer any site (do this first)

Open the target and work through this checklist:

1. **Detect the stack.** Use the Wappalyzer extension and view source. Look in the network
   tab and bundle for `three`, `@react-three`, `gsap`, `ScrollTrigger`, `lenis`,
   `locomotive-scroll`, `barba`, `ogl`, or `curtains`. A `<canvas>` that DevTools cannot
   inspect into means WebGL is doing the visuals.
2. **Find the scroll system.** Does scrolling have inertia/easing (smooth-scroll library) or
   is it native? Does a section stay fixed while content moves (pinning)? Does the page snap
   to sections?
3. **Spot the frame sequence.** In the network tab, a burst of sequentially named images
   (`frame_0001.webp`, `0002`, ...) or many small image requests during a hero animation
   means a scroll-scrubbed sequence (see `references/scroll-frame-sequence.md`). A single
   `.mp4` that scrubs means a video approach.
4. **Spot real 3D.** A `.glb`/`.gltf` request, a `.hdr`/`.exr` environment, or
   `/draco/`,`/basis/` decoder files means a live Three.js/R3F scene. Reflective, refracting,
   light-bending surfaces are transmission/refraction materials
   (`references/glass-and-materials.md`).
5. **Read the materials and post.** Glow on bright elements = selective bloom. Color fringing
   on edges = chromatic aberration. Soft blur with depth = depth of field. Grain = noise pass.
6. **Read the transitions.** No white flash between pages and elements that travel across
   navigation = Barba or View Transitions with a persistent canvas.
7. **Read the art direction.** Note palette, type pairing, motion personality (snappy vs
   floaty), cursor treatment, and the single hero moment the page is built around. This is
   what actually makes it feel premium; reproduce the discipline, not the literal design.

Record findings as a short build list mapped to this skill's references, then build.

## 2. Technique read on the named sites (genre map)

These are characterizations of the techniques the genre uses so you can replicate the
feeling. Confirm any specific site's current stack with the checklist above before quoting it
to a client; live sites change.

- **trionn.com**: the flagship agency-portfolio look. Expect smooth inertia scroll, a
  persistent WebGL layer, image-to-WebGL plane reveals with shader distortion, hover and
  cursor micro-interactions, and choreographed page transitions. Rebuild with Lenis + GSAP
  ScrollTrigger + Three.js/OGL planes synced to DOM (`references/scroll-and-transitions.md`,
  section 5) plus custom GLSL reveal shaders.
- **experiment.obys.agency / obys.agency**: experimental WebGL playground energy: heavy
  shader work, distortion, typographic motion, and bold transitions. Rebuild with custom GLSL
  (`references/threejs-and-shaders.md`, section 5), strong smooth-scroll, and postprocessing.
- **organimo.com**: organic, soft, product-led 3D. Expect a hero 3D object or blob with
  glass/soft materials, gentle float, and scroll-driven camera. Rebuild with R3F + drei
  `<Float>` + environment lighting + transmission material.
- **aorum.io**: refined product/brand 3D with reflective or glassy hero geometry and
  restrained motion. Transmission/refraction material on a clean GLB, HDRI lighting, subtle
  bloom.
- **ciaoenergy.com**: brand storytelling with scroll-bound sections, parallax, and likely a
  scroll-scrubbed or shader-driven hero. Lenis + ScrollTrigger pinned sections + a hero
  sequence or WebGL scene.
- **nymphaicosmetics.com**: cosmetics/product immersive: glassy bottle or liquid look,
  rich color, scroll reveals. Transmission material + gradient/liquid shaders + glass UI
  chrome.
- **fanalis.in**: agency/portfolio immersive with smooth scroll, reveals, and transitions;
  same toolbox as trionn.
- **icare-game.world**: playful, game-like 3D world with stronger interactivity. Real-time
  R3F scene with interaction, instanced elements, and scroll/pointer-driven camera.

The throughline: smooth scroll + a persistent WebGL layer + custom shaders or a scroll
sequence + glass/refraction + selective post + choreographed transitions, all on a strict
performance budget. Every one of those maps to a reference in this skill.

## 3. Where to find more references and learn the patterns

- **Awwwards**, **FWA**, **Codrops** (especially Codrops tutorials, which reverse-engineer
  these exact techniques with source), **Three.js Journey**, and the **pmndrs** docs
  (R3F, drei, react-postprocessing) for the React side.
- **Codepen** and the **GSAP** forums for scroll-sequence and ScrollTrigger recipes.
- When a client sends an inspiration site, run the checklist in section 1 and translate it
  into a build list before estimating or starting.

## 4. Ethics

Replicate techniques, learn from structure, and match a brief's level of polish. Do not copy
another site's proprietary assets, copyrighted imagery, fonts you are not licensed for, or
lift code wholesale. Keep a `CREDITS.md` for every third-party asset and honor its license
(`references/asset-pipeline.md`, section 2).
