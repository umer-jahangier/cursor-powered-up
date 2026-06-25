# Glass: glassmorphism (CSS) and refraction (WebGL)

"Glassy" means two unrelated things. Confirm which the user wants before building, because
the cost and implementation are completely different.

- **Flat glass UI panels** (cards, navs, overlays that blur what is behind them): CSS
  `backdrop-filter`. Cheap, accessible, works everywhere modern.
- **3D glass objects** (a logo, bottle, gem, blob that bends and tints light passing
  through it): a WebGL transmission or refraction material. Expensive, lives in a Three.js
  scene.

## 1. CSS glassmorphism

The frosted-panel look. Core recipe:

```css
.glass {
  background: rgba(255, 255, 255, 0.08);            /* faint tint */
  backdrop-filter: blur(16px) saturate(140%);       /* the frosting */
  -webkit-backdrop-filter: blur(16px) saturate(140%);
  border: 1px solid rgba(255, 255, 255, 0.18);      /* light edge */
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.25);
}
```

Make it convincing:
- Put it over a busy, colorful background (gradient mesh, image, or the WebGL canvas).
  Glass on a flat color looks like nothing.
- A subtle 1px top/left highlight border plus a soft shadow sells depth.
- A faint inner gradient or a `::before` specular streak reads as a reflection.
- Keep text contrast accessible. Frosted panels can fail WCAG contrast; darken the tint or
  add a solid scrim behind text if needed.

Performance and support:
- `backdrop-filter` is GPU-composited but not free. Limit the number of simultaneous
  blurred layers and their area; many large overlapping glass panels will drop frames,
  especially on mobile.
- Provide a fallback: in `@supports not (backdrop-filter: blur(1px))` use a more opaque
  solid background so the panel is still readable.
- Animating blur radius is costly; animate opacity/transform instead.

For a "liquid glass" feel, layer a slow-moving gradient or noise behind the panel rather
than animating the filter.

## 2. WebGL glass and refraction

For 3D objects that transmit and bend light. In R3F, drei provides two materials.

### MeshTransmissionMaterial (frosted/thick glass, epoxy, gel)

Extends `MeshPhysicalMaterial` with extra refraction sampling. Best general-purpose glass.

```jsx
import { MeshTransmissionMaterial } from "@react-three/drei";

<mesh geometry={geometry}>
  <MeshTransmissionMaterial
    samples={10}              // refraction samples; higher = smoother, slower
    thickness={1.5}          // how much light bends through volume
    roughness={0.05}         // 0 = clear, toward 1 = frosted (1.0 turns it invisible)
    ior={1.5}                // index of refraction (glass ~1.5, diamond ~2.4)
    chromaticAberration={0.06}
    anisotropy={0.3}
    distortion={0.2} distortionScale={0.3} temporalDistortion={0.1}
    transmission={1}
    backside                 // render back faces for thicker, richer glass
    color="#ffffff"          // tints everything seen through the glass
  />
</mesh>
```

Important behaviors:
- **roughness** near 1.0 scatters all light and the material reads as opaque/invisible.
  Keep it low for clear glass; raise gently for frosted.
- A **normalMap** adds textured frosting and, usefully, reduces visible pixelation of the
  transmitted background.
- **samples** is the main quality/perf dial. Start at 6 to 10; raise only if grainy.
- Glass needs an **environment map** to look like anything. Add `<Environment>`; without
  reflections, transmission looks dull and grey.
- A bright scene plus **bloom** on the highlights makes glass look premium.

Vanilla equivalent: set `transmission`, `thickness`, `ior`, `roughness`,
`clearcoat`/`clearcoatNormalMap` on `MeshPhysicalMaterial` (Three.js r129+). drei layers
extra shader sampling on top for the better look.

### MeshRefractionMaterial (gems, diamonds, sharp faceted refraction)

Ray-cast refraction with bounces, ideal for crystals and diamonds.

```jsx
import { MeshRefractionMaterial, CubeCamera } from "@react-three/drei";

<CubeCamera>
  {(envTexture) => (
    <mesh geometry={diamondGeometry}>
      <MeshRefractionMaterial
        envMap={envTexture}
        bounces={2}           // internal reflections; costly, keep low
        ior={2.4}             // diamond
        fresnel={1}
        aberrationStrength={0.02}
        fastChroma
      />
    </mesh>
  )}
</CubeCamera>
```

Pair with a `CubeCamera` if it must reflect other scene objects; otherwise pass a static
environment map. `bounces` is expensive; 1 to 2 is usually enough.

## 3. Choosing and combining

- Want a frosted card behind text: CSS glassmorphism.
- Want a glass 3D logo/product floating in the hero: `MeshTransmissionMaterial` in a small
  R3F scene with an HDRI and selective bloom.
- Want a sparkling gem/award look: `MeshRefractionMaterial`.
- Premium sites often combine: a WebGL glass hero object plus CSS glass UI chrome over it.

## 4. Performance notes for WebGL glass

- Transmission materials re-render the scene into a buffer to sample what is behind them;
  they are among the most expensive materials. Use few of them, keep `samples`/`bounces`
  modest, and cap resolution.
- They do not play well stacked (glass behind glass). Avoid many overlapping transmissive
  objects.
- On low-end devices, swap to a cheaper approximation (a `MeshPhysicalMaterial` with
  `transmission` and low samples, or even a static reflective material) behind a quality
  flag. See `references/performance-and-a11y.md`.
