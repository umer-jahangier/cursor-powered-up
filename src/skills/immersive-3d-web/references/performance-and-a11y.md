# Performance and accessibility

An immersive site that drops frames or excludes users is a failure, no matter how it looks.
This is the discipline that separates an Awwwards-grade build from a demo that melts phones.
Treat this file as a checklist to run before shipping.

## Table of contents
1. The performance budget
2. Core Web Vitals for heavy sites
3. Frame-rate killers and fixes
4. Memory and disposal
5. Mobile and low-end strategy
6. Reduced motion
7. SEO and content
8. Graceful degradation and no-WebGL fallback
9. Measurement

## 1. The performance budget

Target 60fps on a mid-tier laptop and a recent mid-range phone, not just your dev machine.
Working budgets:
- First usable paint independent of WebGL: WebGL bundle and assets load after.
- Hero 3D model: aim for a few MB after Draco + KTX2, not tens of MB.
- Scroll-frame sequence: low single-digit MB total in WebP/AVIF, not the tens of MB raw
  PNG would cost.
- Draw calls: keep them low; instance anything repeated.
- One environment map, capped pixel ratio (DPR 2 max), short postprocessing chain.

If a single effect cannot fit the budget on target hardware, cut it or pre-bake it. A clean
60fps page beats a richer 30fps one.

## 2. Core Web Vitals for heavy sites

- **LCP**: make a real, fast image the largest element: a poster, the first frame of a
  sequence, or a low-res hero. Never let a blank canvas be the LCP.
- **CLS**: reserve space for the canvas and media so nothing shifts as 3D loads. Animations
  must not move layout; animate transform/opacity only.
- **INP**: keep scroll and pointer handlers light. Do work in `requestAnimationFrame`, mark
  scroll listeners `{ passive: true }`, and never run layout-reading loops in a scroll
  callback.

## 3. Frame-rate killers and fixes

- **Too many draw calls**: merge static geometry, reuse materials/geometries, use
  `InstancedMesh` / drei `<Instances>` for repeats.
- **Uncapped pixel ratio**: `renderer.setPixelRatio(Math.min(devicePixelRatio, 2))`.
  Retina at full DPR can quadruple fragment work for no visible gain.
- **Expensive materials everywhere**: transmission/refraction materials re-sample the
  scene; use a few, with modest samples/bounces. Avoid stacking them.
- **Overlong postprocessing chains**: each pass is a full-screen draw. Keep 2 to 4 passes.
- **Big textures uncompressed in VRAM**: KTX2 them.
- **Layout thrash**: batch DOM reads then writes; cache `getBoundingClientRect` results.
- **Rendering off-screen**: pause the loop when the canvas leaves the viewport
  (IntersectionObserver); saves battery and heat.
- **LOD**: swap to lower-poly models at distance with drei `<Detailed>`; can recover 30 to
  40 percent in large scenes.

## 4. Memory and disposal

In single-page apps, undisposed GPU objects leak until the tab crashes.
- On unmount/route change: dispose geometries, materials, textures, and render targets;
  call `renderer.dispose()` and, if fully tearing down, `forceContextLoss()`.
- R3F disposes objects in its tree automatically; you still own manually created render
  targets, loaders, workers, and event listeners.
- Remove scroll/resize/pointer listeners and kill GSAP/ScrollTrigger instances on cleanup.

## 5. Mobile and low-end strategy

- Detect capability (rough heuristics: screen size, `devicePixelRatio`,
  `navigator.hardwareConcurrency`, `navigator.deviceMemory`, or a quick benchmark frame).
- Ship a **quality flag** with tiers: full (desktop), reduced (fewer particles, lower
  samples, smaller textures, simpler materials, lower DPR), and minimal/static.
- For scroll sequences, serve a shorter, lower-resolution frame set on small screens.
- Lazy-load and code-split the WebGL bundle so phones on slow networks get a usable page
  first.
- Test on a real mid-range Android, where GPUs and memory are far below a dev laptop.

## 6. Reduced motion

Honor `prefers-reduced-motion: reduce`. When it matches:
- Disable smooth-scroll inertia (use native scroll).
- Replace scrubbed/large motion with instant or short, gentle transitions.
- For a scroll video, show a static representative frame or let it play once subtly rather
  than tying it to scroll.
- Avoid parallax and large camera flights.

```js
const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
if (reduce) { /* skip Lenis, simplify timelines, show static hero */ }
```

## 7. SEO and content

WebGL is invisible to crawlers and screen readers. The page must be a real, semantic
document underneath:
- All headings, body copy, links, and navigation exist as HTML, not painted in canvas.
- Provide `alt` text for meaningful images, including the poster/first frame.
- Canvas gets an accessible label or is marked decorative as appropriate; interactive 3D
  controls need keyboard alternatives or a documented limitation.
- Use proper landmarks, focus order, and visible focus states. Smooth scroll must not break
  keyboard navigation or in-page anchors.

## 8. Graceful degradation and no-WebGL fallback

- Detect WebGL support; if absent or context creation fails, render a styled static
  version (poster image, CSS, real content) instead of a dead canvas.
- Handle `webglcontextlost` and attempt restore or fall back.
- The site must communicate its message with zero WebGL. The 3D is enhancement, not the
  payload.

## 9. Measurement

- `stats-gl` or a FPS meter during development; watch frame time, not just FPS.
- `renderer.info` for draw calls, triangles, textures, and programs.
- Chrome DevTools Performance panel for main-thread work and long tasks; Lighthouse for
  Web Vitals.
- Throttle CPU and network in DevTools to simulate real devices.
- Profile on the lowest-spec device in your target list before calling it done.
