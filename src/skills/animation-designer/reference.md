# Animation Designer — Reference

Complete implementation patterns for Steps 3–14. Read when building animations.

## STEP 3 — LENIS SMOOTH SCROLL

```tsx
'use client'
import Lenis from 'lenis'
import { useEffect } from 'react'
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'

gsap.registerPlugin(ScrollTrigger)

export function SmoothScrollProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    const lenis = new Lenis({
      duration: 1.2,
      easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
      smoothWheel: true,
    })
    lenis.on('scroll', ScrollTrigger.update)
    gsap.ticker.add((time) => { lenis.raf(time * 1000) })
    gsap.ticker.lagSmoothing(0)
    return () => {
      lenis.destroy()
      gsap.ticker.remove((time) => { lenis.raf(time * 1000) })
    }
  }, [])
  return <>{children}</>
}
```

Framer Motion + Lenis: sync `lenis.raf(time.now())` via `frame.update` from `framer-motion`.

## STEP 4 — FRAMER MOTION

Use variants (`fadeUp`, `staggerContainer`), spring presets (`snappy`, `layout`, `scroll`), `useScroll` + `useTransform` + `useSpring` for parallax, `useInView` for reveals, `AnimatePresence` + `LayoutGroup` for page/card transitions, magnetic buttons via `useMotionValue` + `useSpring`.

**Rules:** GPU-only (`x`, `y`, `scale`, `opacity`, `filter` sparingly). Always `useReducedMotion()`.

## STEP 5 — GSAP + SCROLLTRIGGER

```tsx
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'

gsap.registerPlugin(ScrollTrigger)

export function useGSAPAnimation(callback: () => gsap.core.Timeline | void) {
  useEffect(() => {
    const ctx = gsap.context(callback)
    return () => ctx.revert()
  }, [])
}
```

Use for: scroll-pinned sections (`pin: true`, `scrub`), horizontal narratives, split-text reveals, animated counters. Always `gsap.context()` + `revert()` on unmount.

## STEP 6 — REACT THREE FIBER

**Never:** `setState` in `useFrame`. **Always:** mutate `ref.current`, use `delta`, `useGLTF.preload()`, `Suspense`, `dpr={[1,2]}`, instancedMesh for particles.

Stack: `@react-three/fiber`, `@react-three/drei`, `@react-three/postprocessing`. Scroll-driven camera via GSAP + `camera.position.lerp()` in `useFrame`.

## STEP 7 — GLSL SHADERS

Custom `shaderMaterial` for distortion planes, RGB shift, dissolve. Uniforms: `uTime`, `uMouse`, `uDistortion`, `uProgress`.

## STEP 8 — CUSTOM CURSOR

Replace native cursor on desktop only. `useMotionValue` + dual springs (cursor + trail). States: `default`, `hover`, `drag`, `text`. Hide on touch/`prefers-reduced-motion`.

## STEP 9 — LOADING SCREENS

Number counter preloader with `AnimatePresence` exit (`y: '-100%'`). Max 5s timeout. Preload 3D assets before reveal.

## STEP 10 — PERFORMANCE

Animate only: `transform`, `opacity`. Never: `width`, `height`, `top`, `left`. Include `prefers-reduced-motion` CSS + `useReducedMotion`. Pause loops when `document.hidden`.

## STEP 11 — TIMING TOKENS

```ts
export const TIMING = {
  micro: 0.12,
  component: 0.28,
  reveal: 0.65,
  page: 0.45,
  narrative: 1.2,
} as const

export const EASING = {
  expo: [0.16, 1, 0.3, 1] as const,
  expoIn: [0.7, 0, 0.84, 0] as const,
  smooth: [0.45, 0, 0.15, 1] as const,
  back: [0.34, 1.56, 0.64, 1] as const,
} as const
```

## STEP 12 — BLUEPRINTS

**A — Creative agency:** Lenis + GSAP ScrollTrigger narrative + R3F hero particles + SplitText + magnetic CTA.

**B — SaaS landing:** Framer Motion stagger + feature horizontal scroll + AnimatePresence pricing toggle.

**C — 3D product:** Full R3F canvas + scroll camera + morph targets + Html hotspots.

## STEP 13 — ANTI-PATTERNS

| Anti-Pattern | Fix |
|---|---|
| setState in useFrame | Mutate refs |
| Animating width/height | scale + clip |
| No reduced motion | useReducedMotion + CSS |
| All 3 libs at once | Pick Framer OR GSAP primary |
| No Lenis | Always Lenis on animated sites |
| Linear easing everywhere | expo / spring |

## STEP 14 — ACCESSIBILITY

- `useReducedMotion` in every animated component
- `@media (prefers-reduced-motion: reduce)` in globals
- No flash >3Hz; focus visible after transitions
- Custom cursor hidden on mobile
- Loading screen max 5s

## Pairing with cursor-powered-up

- **21st.dev MCP** — generate React UI components; add `framer-motion` per project
- **ui-ux-pro-max skill** — palettes, typography, layout before animating
- **animation-designer** (this skill) — motion layer on top
