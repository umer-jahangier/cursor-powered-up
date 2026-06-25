# Scroll-scrubbed frame sequence (the "video opens as you scroll" effect)

This is the effect on Apple product pages (AirPods Pro, iPhone), Sony "Be Moved", and most
of the agency sites in the reference gallery. A short clip is split into still frames; as
the user scrolls, JavaScript maps scroll progress to a frame index and draws that frame to
a canvas. The user scrubs the animation with the scrollbar instead of pressing play.

## Table of contents
1. Why frames beat a real `<video>`
2. The three rendering methods and which to pick
3. Layout: pin/sticky over a tall scroll track
4. Frame math
5. Preloading and decoding (the part everyone gets wrong)
6. GSAP ScrollTrigger implementation (recommended)
7. Raw scroll-listener implementation (no dependencies)
8. Responsive and DPR-aware frame sets
9. Performance and weight
10. Common bugs and fixes

## 1. Why frames beat a real video

Scrubbing a real `<video>` backward and to an exact frame is unreliable across browsers and
codecs: seeking is not frame-accurate, reverse playback stutters, and decoders disagree.
A numbered image sequence is predictable, scrubs in both directions perfectly, and lets you
preload and decode each frame deliberately. The cost is total weight and request count,
which you control with modern formats and HTTP/2. This is the technique to use.

## 2. The three rendering methods

- **`<canvas>` + `drawImage` (recommended).** Full control, no flicker if you preload and
  decode. Draw the current frame each rAF tick. This is what Apple and the agencies use.
- **Swapping `<img src>`.** Simplest, but decode-on-swap causes visible flashing and
  artifacts unless you carefully pre-decode. Acceptable only for tiny sequences.
- **Near-pure CSS (`animation-timeline: scroll()` + steps()).** New scroll-driven CSS can
  flip a sprite/`object-position` on scroll with little JS. Elegant and cheap where browser
  support is acceptable, but less control over loading priority. Treat as progressive
  enhancement.

Default to canvas. Use the starter in `assets/canvas-sequence-starter.html`.

## 3. Layout: pin a sticky stage over a tall track

The illusion needs the canvas to stay fixed in the viewport while the page scrolls "past"
it. Two equivalent patterns:

- **CSS sticky:** a tall wrapper (for example `height: 500vh`) contains a `position: sticky;
  top: 0; height: 100vh` stage holding the canvas. Scroll progress is the wrapper's scroll
  position over its scrollable length.
- **GSAP pin:** `ScrollTrigger` with `pin: true` and `end: "+=4000"`. Cleaner when GSAP is
  already in the project, and it gives you `scrub` for free.

The length of the track sets the scrub feel. A common mistake is mapping the sequence to
the entire page scroll; scope it to the pinned section. Frames-per-pixel = frames / track
length. Apple stretches ~65 frames over ~1200px (very tight, slight jitter on slow scroll);
a comfortable range is roughly 8 to 20 scroll pixels per frame.

## 4. Frame math

```js
// progress is 0..1 across the pinned track
const frameCount = 147;            // number of images, e.g. frame_0001..frame_0147
const index = Math.min(
  frameCount - 1,
  Math.max(0, Math.round(progress * (frameCount - 1)))
);
const src = `/frames/frame_${String(index + 1).padStart(4, "0")}.webp`;
```

Pad filenames with leading zeros so lexical and numeric order match. Keep a fixed digit
count from the start (see `scripts/extract_frames.sh`).

## 5. Preloading and decoding

Flicker and "strobing" come from drawing an image that has not finished decoding. Preload
all frames into an array and, ideally, call `img.decode()` before first use. For large
sequences, prioritize: load checkpoint frames first (every Nth) so a degraded version is
scrubbable early, then backfill. Apple does exactly this under throttling.

```js
const images = [];
let loaded = 0;
for (let i = 1; i <= frameCount; i++) {
  const img = new Image();
  img.src = `/frames/frame_${String(i).padStart(4, "0")}.webp`;
  img.onload = () => { loaded++; };
  images[i - 1] = img;
}
// draw the first frame as soon as it is ready so the canvas is never blank
images[0].onload = () => context.drawImage(images[0], 0, 0, canvas.width, canvas.height);
```

Draw inside `requestAnimationFrame`, not directly in the scroll event, so paints align to
the refresh rate and never pile up.

## 6. GSAP ScrollTrigger implementation (recommended)

```js
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
gsap.registerPlugin(ScrollTrigger);

const canvas = document.querySelector("#seq");
const ctx = canvas.getContext("2d");
const frameCount = 147;
const images = [];
const state = { frame: 0 };

const url = i => `/frames/frame_${String(i + 1).padStart(4, "0")}.webp`;
for (let i = 0; i < frameCount; i++) { const im = new Image(); im.src = url(i); images[i] = im; }

function render() {
  const img = images[state.frame];
  if (!img || !img.complete) return;
  // cover-fit the frame to the canvas
  const r = Math.max(canvas.width / img.width, canvas.height / img.height);
  const w = img.width * r, h = img.height * r;
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.drawImage(img, (canvas.width - w) / 2, (canvas.height - h) / 2, w, h);
}

function resize() {
  const dpr = Math.min(window.devicePixelRatio, 2);
  canvas.width = innerWidth * dpr;
  canvas.height = innerHeight * dpr;
  render();
}
addEventListener("resize", () => { clearTimeout(window._t); window._t = setTimeout(resize, 150); });
resize();
images[0].onload = render;

gsap.to(state, {
  frame: frameCount - 1,
  snap: "frame",
  ease: "none",
  scrollTrigger: {
    trigger: "#seq-section",
    start: "top top",
    end: "+=4000",     // track length; tune for scrub feel
    pin: true,
    scrub: 1           // 1 adds a little inertia; true = locked to scroll
  },
  onUpdate: render
});
```

This is the production pattern: GSAP owns the scroll mapping, you only draw.

## 7. Raw scroll-listener implementation (no dependencies)

```js
const html = document.documentElement;
function onScroll() {
  const max = html.scrollHeight - innerHeight;
  const progress = max > 0 ? html.scrollTop / max : 0;   // scope this to your section in practice
  const frame = Math.round(progress * (frameCount - 1));
  if (frame !== state.frame) { state.frame = frame; requestAnimationFrame(render); }
}
addEventListener("scroll", onScroll, { passive: true });
```

Use `{ passive: true }` so scrolling stays smooth, and gate redraws on a changed index.

## 8. Responsive and DPR-aware frame sets

One frame size cannot serve a phone and a 4K monitor well. Export two or three sequences
(for example 720p, 1080p, 1440p) and pick a set at load based on viewport and
`devicePixelRatio`. Cap the canvas backing store at DPR 2; beyond that the extra pixels
cost a lot and buy nothing. On small screens consider a shorter, lower-fps sequence to cut
weight.

## 9. Performance and weight

- **Format.** WebP is roughly 80 to 90 percent smaller than PNG for these frames; AVIF is
  smaller still. Convert always. A famous example: 65 AirPods PNGs weighed 15.2MB; the same
  frames as WebP land near 1.7MB.
- **Frame count.** Do not extract every frame of a 30/60fps clip. 12 to 24 fps is plenty
  for scrubbed motion; fewer frames means less weight and only minor stepping.
- **Transport.** Serve over HTTP/2 or HTTP/3 so dozens of frame requests multiplex. On
  HTTP/1.1 the parallel-request cap will bottleneck loading.
- **Trim padding.** Exported frames often carry transparent margins. Crop a single uniform
  bounding box across the whole set (`scripts/crop_sequence.py`) so frames register and
  files shrink.
- **LCP.** Make the first frame (or a poster) a real, fast-loading image so the canvas is
  never blank during load.

## 10. Common bugs and fixes

- **Strobing/flashing between frames:** you are drawing undecoded images. Preload into an
  array; optionally `await img.decode()`. Draw in rAF, not the scroll handler.
- **Scrub runs over the whole page:** you mapped progress to document scroll. Scope it to
  the pinned section (ScrollTrigger `trigger`/`end`, or sticky-wrapper math).
- **Frames out of order:** filename padding mismatch. Zero-pad to a fixed width.
- **Jitter on slow scroll:** too few frames over too long a track. Add frames or shorten
  the track. A small `scrub` value (0.5 to 1) smooths it.
- **Blurry on retina:** set canvas backing store to `cssSize * dpr` and draw to that, with
  CSS size in px. Cap dpr at 2.
- **Janky on mobile:** lighter frame set, fewer frames, and confirm scroll listeners are
  passive and debounced on resize.
