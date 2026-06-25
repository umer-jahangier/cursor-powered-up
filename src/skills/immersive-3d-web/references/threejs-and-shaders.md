# Three.js, React Three Fiber, and shaders

Real-time WebGL for depth, interactivity, and effects that cannot be pre-baked. Choose
vanilla Three.js for non-React sites and maximum control; choose React Three Fiber (R3F)
for React/Next.js, where the declarative scene graph and the drei helper library save a lot
of boilerplate.

## Table of contents
1. Scene anatomy (vanilla)
2. R3F equivalent and ecosystem
3. Loading models (Draco, KTX2, meshopt)
4. Lighting and environment maps
5. Custom GLSL shaders (uniforms, time, scroll)
6. Postprocessing
7. Instancing and draw-call discipline
8. Cleanup and the render loop

## 1. Scene anatomy (vanilla)

A WebGL scene is always: renderer, scene, camera, lights, meshes, loop.

```js
import * as THREE from "three";

const canvas = document.querySelector("#gl");
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));   // cap DPR, always
renderer.setSize(innerWidth, innerHeight);
renderer.toneMapping = THREE.ACESFilmicToneMapping;       // filmic look out of the box

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(45, innerWidth / innerHeight, 0.1, 100);
camera.position.set(0, 0, 6);

const clock = new THREE.Clock();
function tick() {
  const t = clock.getElapsedTime();
  // update materials/uniforms/camera here
  renderer.render(scene, camera);
  requestAnimationFrame(tick);
}
tick();

addEventListener("resize", () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
});
```

Set `alpha: true` when you want the WebGL canvas to sit transparently over HTML content
(the common pattern for scrollytelling: a fixed full-screen canvas behind the DOM).

## 2. R3F equivalent and ecosystem

```jsx
import { Canvas, useFrame } from "@react-three/fiber";
import { Environment, OrbitControls, Float, useGLTF } from "@react-three/drei";

function Model() {
  const { scene } = useGLTF("/models/hero.glb");
  return <primitive object={scene} />;
}

export default function Scene() {
  return (
    <Canvas dpr={[1, 2]} camera={{ position: [0, 0, 6], fov: 45 }}
            gl={{ antialias: true, alpha: true }}>
      <Environment preset="studio" />     {/* image-based lighting */}
      <Float><Model /></Float>            {/* gentle idle bob/rotate */}
      <OrbitControls enablePan={false} />
    </Canvas>
  );
}
useGLTF.preload("/models/hero.glb");
```

Key libraries:
- **@react-three/drei**: `useGLTF`, `Environment`, `OrbitControls`, `Float`,
  `MeshTransmissionMaterial`, `MeshRefractionMaterial`, `Text3D`, `ScrollControls`,
  `Detailed` (LOD), `useTexture`, `Lightformer`.
- **@react-three/postprocessing**: `EffectComposer`, `Bloom`, `DepthOfField`,
  `ChromaticAberration`, `Noise`, `Vignette`.
- **leva**: live debug controls for tuning material/light params while you build.
- **maath**: easing and math helpers for smooth lerps.

Use `useFrame((state, delta) => { ... })` for per-frame updates; write to refs, never to
React state inside the loop.

## 3. Loading models (Draco, KTX2, meshopt)

Most optimized GLBs require decoders. Wire them once.

Vanilla:
```js
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { DRACOLoader } from "three/addons/loaders/DRACOLoader.js";
import { KTX2Loader } from "three/addons/loaders/KTX2Loader.js";
import { MeshoptDecoder } from "three/addons/libs/meshopt_decoder.module.js";

const draco = new DRACOLoader().setDecoderPath("/draco/");
const ktx2 = new KTX2Loader().setTranscoderPath("/basis/").detectSupport(renderer);
const loader = new GLTFLoader()
  .setDRACOLoader(draco)
  .setKTX2Loader(ktx2)
  .setMeshoptDecoder(MeshoptDecoder);
loader.load("/models/hero.glb", gltf => scene.add(gltf.scene));
```

In R3F, `useGLTF(url, "/draco/")` enables Draco; for KTX2 configure the loader via the
`extendLoader` callback or drei's `KTX2` support. See `references/asset-pipeline.md` for how
to produce these compressed files.

Lazy-load the whole 3D path so it never blocks first paint:
```js
const observer = new IntersectionObserver(([e]) => {
  if (e.isIntersecting) { import("./scene.js").then(m => m.init()); observer.disconnect(); }
});
observer.observe(document.querySelector("#gl-mount"));
```

## 4. Lighting and environment maps

Image-based lighting from an HDRI is what makes WebGL look expensive. It drives reflections
on metal and glass and gives soft, believable light for free.

```js
import { RGBELoader } from "three/addons/loaders/RGBELoader.js";
new RGBELoader().load("/hdri/studio_1k.hdr", tex => {
  tex.mapping = THREE.EquirectangularReflectionMapping;
  scene.environment = tex;          // lights all PBR materials
  // scene.background = tex;        // optional: also show it
});
```

In R3F: `<Environment files="/hdri/studio_1k.hdr" />` or a `preset`. Build custom studio
lighting with drei `<Lightformer>` inside `<Environment>` for art-directed highlights. A 1k
or 2k HDRI is plenty for reflections; do not ship 8k. Add a single key `directionalLight`
for crisp shadows if needed, and keep shadow map sizes modest (1024 to 2048).

## 5. Custom GLSL shaders

Shaders are where the genre's signature looks live: gradient meshes, displacement on scroll,
liquid/ripple distortion, particle fields, dot-matrix and halftone passes.

Vanilla `ShaderMaterial`:
```js
const material = new THREE.ShaderMaterial({
  uniforms: {
    uTime: { value: 0 },
    uScroll: { value: 0 },
    uMouse: { value: new THREE.Vector2() },
    uTexture: { value: texture }
  },
  vertexShader: /* glsl */`
    uniform float uTime; uniform float uScroll;
    varying vec2 vUv;
    void main() {
      vUv = uv;
      vec3 p = position;
      p.z += sin(p.x * 4.0 + uTime) * 0.15 * (1.0 + uScroll); // displacement
      gl_Position = projectionMatrix * modelViewMatrix * vec4(p, 1.0);
    }`,
  fragmentShader: /* glsl */`
    uniform sampler2D uTexture; varying vec2 vUv;
    void main() { gl_FragColor = texture2D(uTexture, vUv); }`
});
// in the loop:
material.uniforms.uTime.value = clock.getElapsedTime();
```

Drive `uScroll` and `uMouse` from your scroll/pointer state to bind the shader to
interaction. In R3F, declare a material via `shaderMaterial` from drei or inline, then
update `ref.current.uniforms.uTime.value` in `useFrame`. For mapping shader planes onto DOM
images (the WebGL gallery look), see the DOM-to-WebGL sync section in
`references/scroll-and-transitions.md`.

For shader-heavy sites that do not need a full scene graph, **OGL** or **curtains.js** are
lighter than Three.js.

## 6. Postprocessing

Adds the final cinematic grade. Keep the chain short; each pass costs frames.

R3F:
```jsx
import { EffectComposer, Bloom, ChromaticAberration, Vignette, Noise } from "@react-three/postprocessing";

<EffectComposer>
  <Bloom luminanceThreshold={1} luminanceSmoothing={0.9} intensity={0.6} mipmapBlur />
  <ChromaticAberration offset={[0.0005, 0.0005]} />
  <Vignette eskil={false} offset={0.2} darkness={0.8} />
  <Noise opacity={0.02} />
</EffectComposer>
```

Bloom is **selective**: set `luminanceThreshold` to 1 and only materials whose color exceeds
the 0 to 1 range (lift `emissive`/`color` above 1, or use `emissiveIntensity > 1`) will
glow. This is how you make neon, screens, and rim light pop without washing out the scene.

## 7. Instancing and draw-call discipline

Draw calls are the usual frame-rate killer. Repeated geometry (particles, cards, grass,
stars) must be one `InstancedMesh`, not many meshes.

```js
const mesh = new THREE.InstancedMesh(geometry, material, count);
const dummy = new THREE.Object3D();
for (let i = 0; i < count; i++) {
  dummy.position.set(/* ... */); dummy.updateMatrix();
  mesh.setMatrixAt(i, dummy.matrix);
}
mesh.instanceMatrix.needsUpdate = true;
```

R3F: `<Instances>`/`<Instance>` from drei. Also: merge static geometry, reuse materials and
geometries, and use drei `<Detailed>` for level-of-detail swaps at distance (30 to 40
percent frame gains in big scenes).

## 8. Cleanup and the render loop

In single-page apps, undisposed GPU resources leak and eventually crash the tab. On unmount
dispose geometries, materials, textures, render targets, and the renderer; release the
context with `renderer.dispose()` and, if needed, `forceContextLoss()`. R3F disposes
automatically for objects in its tree, but anything you create manually (custom render
targets, loaders, event listeners) is yours to clean up. Pause the loop when the canvas is
off-screen (IntersectionObserver) to save battery and heat.
