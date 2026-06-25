# Smooth scroll, ScrollTrigger, and page transitions

The motion system. This is what makes a site feel "alive on scroll": inertial smooth
scrolling, timelines bound to scroll progress, pinned scenes, parallax, DOM elements synced
to WebGL planes, and choreographed transitions between pages.

## Table of contents
1. One scroll authority
2. Lenis + GSAP on a single clock
3. ScrollTrigger essentials: scrub, pin, snap
4. Parallax and reveals
5. Syncing DOM elements to WebGL planes
6. Driving a 3D scene from scroll
7. Page transitions (Barba, View Transitions)
8. Pitfalls

## 1. One scroll authority

Never run two smooth-scroll systems at once. Pick **GSAP ScrollSmoother** (if you have a
GSAP membership/Club plugin) or **Lenis** (free, default). Everything else (ScrollTrigger,
WebGL camera, parallax) reads from that one source. Competing systems cause stutter, drift,
and fighting inertia.

## 2. Lenis + GSAP on a single clock

The critical detail: drive Lenis from GSAP's ticker so DOM animation, ScrollTrigger, and
the WebGL render loop all advance on the same frame. Do not call `requestAnimationFrame`
separately for Lenis and for Three.js.

```js
import Lenis from "lenis";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
gsap.registerPlugin(ScrollTrigger);

const lenis = new Lenis({ lerp: 0.1, smoothWheel: true });

// Lenis tells ScrollTrigger when scroll changes
lenis.on("scroll", ScrollTrigger.update);

// GSAP ticker drives Lenis (one rAF for everything)
gsap.ticker.add((time) => lenis.raf(time * 1000));
gsap.ticker.lagSmoothing(0);
```

For your Three.js loop, either render inside the same ticker callback or read
`lenis.scroll`/a normalized progress value inside `useFrame`. In React, wrap Lenis in a
provider or use `lenis/react`'s `<ReactLenis root>` and the `useLenis` hook.

Respect reduced motion: if `matchMedia("(prefers-reduced-motion: reduce)")` matches, skip
smooth scroll (let the browser scroll natively) and shorten or disable scrubbed animations.

## 3. ScrollTrigger essentials

```js
// scrub: bind a timeline to scroll position (the core scrollytelling move)
gsap.timeline({
  scrollTrigger: {
    trigger: ".hero",
    start: "top top",
    end: "+=1500",
    scrub: 1,        // number = smoothing; true = locked to scroll
    pin: true,       // hold the section while its timeline plays
    anticipatePin: 1 // avoids a pin jump on fast scroll
  }
})
.to(".hero .title", { autoAlpha: 0, scale: 0.5, filter: "blur(20px)" })
.to(camera.position, { z: 12, ease: "power1.inOut" }, "<"); // run with previous tween
```

- **scrub** turns an animation into a scrubber: progress follows the scrollbar.
- **pin** freezes a section so a sequence reads as one scene instead of scrolling away.
- **snap** (`snap: 1 / (sections - 1)`) clicks the page to section boundaries.
- Use function-based `start`/`end` (`() => "top top"`) so values recompute on resize, and
  call `ScrollTrigger.refresh()` after layout changes or font/image loads.

## 4. Parallax and reveals

```js
// layered parallax: backgrounds move slower than foreground
gsap.to(".bg", { yPercent: -20, ease: "none",
  scrollTrigger: { trigger: ".section", scrub: true } });

// reveal on enter
gsap.from(".card", { y: 60, autoAlpha: 0, stagger: 0.1,
  scrollTrigger: { trigger: ".grid", start: "top 80%" } });
```

Animate transform and opacity only; they are GPU-composited and do not trigger layout.
Avoid animating top/left/width/height on scroll.

## 5. Syncing DOM elements to WebGL planes

The "WebGL gallery" look (images that warp/reveal with a shader while still behaving like
normal HTML) works by drawing a Three.js plane exactly over each DOM image. Keep the HTML
`<img>` for layout, accessibility, and SEO; hide it visually and mirror its rect in WebGL.

```js
function syncPlaneToDom(mesh, el, camera, sizes) {
  const rect = el.getBoundingClientRect();
  // convert pixel rect to world units at the plane's depth, then:
  mesh.scale.set(rect.width, rect.height, 1);
  mesh.position.x = rect.left - sizes.w / 2 + rect.width / 2;
  mesh.position.y = -(rect.top - sizes.h / 2 + rect.height / 2);
}
```

Recompute each frame from the smooth-scroll value so planes track the page. Trigger the
reveal shader's `uProgress` uniform with a ScrollTrigger when the element enters the
viewport. This is the pattern in many Codrops/agency builds (GSAP + Three.js + a smooth
scroll source).

## 6. Driving a 3D scene from scroll

Two clean approaches:

- **drei `ScrollControls`** (R3F): wraps the page scroll and exposes `useScroll()` with a
  normalized `offset` and per-range helpers, ideal for self-contained R3F experiences.
- **External ScrollTrigger** driving an array of progress values, read in `useFrame`/the
  loop. Spread each section's "shot" as a keyframe and pick the camera/animation state from
  the active section index. This keeps DOM and 3D in lockstep and is easy to author
  section-by-section.

Pattern: build the whole camera flight as a single paused animation (camera positions,
look-at targets, model morph times) and set its `time`/progress from scroll. The scene
becomes a film you scrub.

## 7. Page transitions

For multi-page immersive sites the navigation itself should be choreographed (no white
flash, elements can travel between pages).

- **Barba.js**: intercepts navigation, keeps the WebGL canvas alive across pages, and lets
  you run enter/leave timelines. Combine with GSAP for the transition and persist the
  Three.js context so the scene does not rebuild on every route.
- **View Transitions API**: native, minimal code (`document.startViewTransition`), great
  for same-document and increasingly cross-document transitions. Use where browser support
  is acceptable; provide an instant fallback otherwise.
- In Next.js, keep a single persistent `<Canvas>` above the router so the 3D scene survives
  route changes and only its contents animate.

## 8. Pitfalls

- **Two rAF loops** (Lenis and Three.js separately): visible micro-stutter. Unify on the
  GSAP ticker.
- **ScrollTrigger positions wrong after load:** images/fonts changed layout. Call
  `ScrollTrigger.refresh()` once everything is loaded, and use function-based start/end.
- **Pin jump on fast scroll:** add `anticipatePin: 1`.
- **Layout thrash:** reading `getBoundingClientRect` and writing styles in the same frame
  for many elements. Batch reads then writes, or cache rects and update on resize/scroll
  only.
- **Smooth scroll vs anchor links/focus:** intercept hash links to use
  `lenis.scrollTo(target)`, and make sure keyboard focus still scrolls the page.
- **Reduced motion ignored:** always branch on `prefers-reduced-motion` and ship a calm
  version.
