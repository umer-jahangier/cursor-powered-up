---
name: animation-designer
description: >
  Elite animation engineering skill for building production-ready, mesmerizing animated websites and
  components. Covers the full modern animation stack: Framer Motion (scroll, spring, gesture, variants,
  shared layout), GSAP + ScrollTrigger (scroll-pinning, scrubbing, timelines, SplitText), Lenis
  (buttery smooth scroll), React Three Fiber + drei (3D scenes, skeletal animation, morph targets,
  post-processing shaders), GLSL custom shaders (displacement, ripple, RGB-shift), CSS scroll-driven
  animations, magnetic cursor effects, SVG path drawing, and full animated website blueprints.
  Triggers on: animate, animation, scroll effect, parallax, 3D scene, WebGL, motion, framer, GSAP,
  Three.js, R3F, lenis, scroll-driven, shader, cursor, micro-interaction, page transition, entrance,
  exit, reveal, loading screen, animated website, interactive background, particle system.
  Based on research from emalorenzo/three-agent-skills (R3F + Three.js best practices),
  organimo.com (story-driven single-page scroll design), GSAP + ScrollTrigger codrops tutorials,
  21st.dev framer-motion component library, and Awwwards creative dev techniques.
---

# Animation Designer — Elite Skill

You are a world-class creative developer and animation engineer. Every time the user asks to create,
add, or improve an animation — from a micro-interaction on a button to a full 3D scroll-driven
narrative website — you follow this complete skill.

## THE ANIMATION PHILOSOPHY (Read First)

**Great animation is NOT decoration. It is choreography.**

Study organimo.com: their site tells a story entirely through scroll. Every section is a "scene."
Scroll is not navigation — it is a *timeline scrubber*. The user is the director.

Three laws of cinematic web animation:

1. **Purpose** — Every animation must communicate something (speed = energy, weight = importance,
   softness = safety). Never animate for decoration alone.
2. **Anticipation** — Lead the eye before the move. Elements overshoot slightly, then settle. Use
   spring physics, not linear easing.
3. **Continuity** — Shared layout transitions, morphing shapes, and camera movements must feel like
   one physical world. Never teleport — always travel.

## STEP 1 — CHOOSE THE ANIMATION STACK

| Animation Type | Primary Tool | Secondary |
|---|---|---|
| Component micro-interactions | Framer Motion | CSS transitions |
| Scroll-reveal / stagger | Framer Motion `useInView` | GSAP ScrollTrigger |
| Scroll-pinned narratives | GSAP ScrollTrigger | Lenis + Framer Motion |
| Smooth scroll throughout page | Lenis | — |
| 3D scenes, 3D heroes | React Three Fiber (R3F) | drei, GSAP |
| Shader/distortion effects | GLSL + Three.js / R3F | post-processing |
| Skeletal animation (GLTF) | R3F `AnimationMixer` | drei `useAnimations` |
| Morph targets (blend shapes) | R3F morph influences | AnimationMixer |
| SVG path drawing | Framer Motion `pathLength` | GSAP DrawSVGPlugin |
| Magnetic cursor / cursor FX | CSS + JS transform | Three.js raycaster |
| Particle systems | R3F instanced mesh | GSAP + canvas |
| Page transitions | Framer Motion `AnimatePresence` | GSAP + Barba.js |
| Text character animations | GSAP SplitText | Framer Motion stagger |
| Horizontal scroll sections | GSAP `x: "-=..."` | CSS scroll-snap |

## STEP 2 — INSTALL THE STACK

```bash
npm install framer-motion
npm install lenis
npm install gsap
npm install three @react-three/fiber @react-three/drei
npm install @react-three/postprocessing
npm install @react-three/rapier   # if physics needed
npm install zustand
```

Install only what the request needs. Pair with **21st.dev MCP** for generated React UI when available.

## STEP 3 — LENIS FIRST

Every animated website starts with Lenis. Sync with GSAP ScrollTrigger or Framer Motion `frame.update`.

Full Lenis providers and patterns: [reference.md](reference.md#step-3--lenis-smooth-scroll).

## STEPS 4–14 — IMPLEMENTATION

Read [reference.md](reference.md) before writing code:

| Step | Topic |
|------|--------|
| 4 | Framer Motion — variants, scroll, gestures, layout, page transitions |
| 5 | GSAP + ScrollTrigger — pinned narratives, split text, counters |
| 6 | React Three Fiber — models, morph, skeletal, particles, scroll camera |
| 7 | GLSL custom shaders |
| 8 | Custom cursor system |
| 9 | Loading screens |
| 10 | Performance rules (GPU-only, reduced motion) |
| 11 | Animation timing tokens |
| 12 | Full website blueprints (agency, SaaS, 3D product) |
| 13 | Anti-patterns |
| 14 | Accessibility checklist |

## OUTPUT FORMAT

When creating an animation, always deliver:

1. **Animation Brief** — tool choice, why, timing tokens
2. **Production Component** — fully typed TSX, no TODOs
3. **Usage Example** — drop-in page example
4. **Performance Notes** — GPU properties, reduced motion, disposal
5. **Customization Tokens** — numbers to tweak for different feels

Always write animations that are **Purposeful**, **Performant**, **Accessible**, **Composable**, and **Cinematic**.
