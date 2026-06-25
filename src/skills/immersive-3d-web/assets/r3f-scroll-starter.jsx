/**
 * r3f-scroll-starter.jsx
 * React Three Fiber starter for an immersive scroll-driven 3D hero:
 *  - Lenis smooth scroll synced to GSAP's ticker (one clock for DOM + WebGL)
 *  - scroll progress drives the camera and a material uniform
 *  - a glass object (MeshTransmissionMaterial) lit by an HDRI environment
 *  - selective bloom (only emissive-bright things glow)
 *  - reduced-motion and lazy-mount friendly
 *
 * Install:
 *   npm i three @react-three/fiber @react-three/drei @react-three/postprocessing gsap lenis
 *
 * Notes:
 *  - Real page content lives in normal DOM around <Canvas/>; WebGL is decoration.
 *  - For a real model, replace <TorusKnot/> with a <Gltf/>; optimize the GLB first
 *    with scripts/optimize_glb.sh and wire DRACO/KTX2 loaders.
 */
import React, { useEffect, useRef, useState } from "react";
import { Canvas, useFrame } from "@react-three/fiber";
import { Environment, Float, MeshTransmissionMaterial } from "@react-three/drei";
import { EffectComposer, Bloom, ChromaticAberration, Vignette } from "@react-three/postprocessing";
import Lenis from "lenis";
import gsap from "gsap";

// Shared scroll progress (0..1). Written by Lenis, read inside useFrame.
const scrollState = { progress: 0 };

function useSmoothScroll() {
  useEffect(() => {
    const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce) return; // let the browser scroll natively

    const lenis = new Lenis({ lerp: 0.1, smoothWheel: true });
    const onScroll = ({ scroll, limit }) => {
      scrollState.progress = limit > 0 ? scroll / limit : 0;
    };
    lenis.on("scroll", onScroll);
    const tick = (time) => lenis.raf(time * 1000);
    gsap.ticker.add(tick);
    gsap.ticker.lagSmoothing(0);
    return () => {
      gsap.ticker.remove(tick);
      lenis.off("scroll", onScroll);
      lenis.destroy();
    };
  }, []);
}

function GlassHero() {
  const mesh = useRef();
  useFrame((stateThree, delta) => {
    const p = scrollState.progress;
    // idle spin plus scroll-driven rotation
    if (mesh.current) {
      mesh.current.rotation.y += delta * 0.2 + p * 0.02;
      mesh.current.rotation.x = p * Math.PI;
    }
    // scroll-driven dolly
    stateThree.camera.position.z = 6 - p * 2.5;
    stateThree.camera.lookAt(0, 0, 0);
  });

  return (
    <Float speed={1.2} rotationIntensity={0.4} floatIntensity={0.8}>
      <mesh ref={mesh}>
        <torusKnotGeometry args={[1, 0.34, 220, 32]} />
        <MeshTransmissionMaterial
          samples={8}
          thickness={1.2}
          roughness={0.05}
          ior={1.5}
          chromaticAberration={0.06}
          anisotropy={0.3}
          distortion={0.2}
          distortionScale={0.3}
          temporalDistortion={0.1}
          transmission={1}
          backside
          color="#eaf2ff"
        />
      </mesh>
    </Float>
  );
}

function Scene() {
  return (
    <>
      {/* HDRI lighting drives reflections; glass is dull without it */}
      <Environment preset="studio" />
      <ambientLight intensity={0.2} />
      {/* an emissive accent that bloom will catch */}
      <mesh position={[2.4, -1.2, -2]}>
        <sphereGeometry args={[0.4, 32, 32]} />
        <meshStandardMaterial emissive="#5b8cff" emissiveIntensity={4} color="#0a0a12" />
      </mesh>
      <GlassHero />
      <EffectComposer>
        <Bloom luminanceThreshold={1} luminanceSmoothing={0.9} intensity={0.7} mipmapBlur />
        <ChromaticAberration offset={[0.0006, 0.0006]} />
        <Vignette eskil={false} offset={0.25} darkness={0.85} />
      </EffectComposer>
    </>
  );
}

export default function ImmersiveHero() {
  useSmoothScroll();
  const [mounted, setMounted] = useState(false);

  // Lazy-mount WebGL after first paint so it never blocks LCP.
  useEffect(() => {
    const id = requestIdleCallback
      ? requestIdleCallback(() => setMounted(true))
      : setTimeout(() => setMounted(true), 200);
    return () => (requestIdleCallback ? cancelIdleCallback(id) : clearTimeout(id));
  }, []);

  return (
    <div style={{ background: "#06060a", color: "#fff" }}>
      <header style={{ minHeight: "20vh", display: "grid", placeItems: "center" }}>
        <h1 style={{ fontSize: "clamp(2rem,6vw,5rem)", letterSpacing: "-0.02em" }}>
          Real, crawlable headline
        </h1>
      </header>

      {/* Fixed full-screen canvas behind the scrolling DOM */}
      <div style={{ position: "fixed", inset: 0, zIndex: 0, pointerEvents: "none" }}>
        {mounted && (
          <Canvas
            dpr={[1, 2]}
            camera={{ position: [0, 0, 6], fov: 45 }}
            gl={{ antialias: true, alpha: true, powerPreference: "high-performance" }}
          >
            <Scene />
          </Canvas>
        )}
      </div>

      {/* Scroll track: real sections drive scrollState.progress */}
      <main style={{ position: "relative", zIndex: 1 }}>
        <section style={{ height: "120vh" }} />
        <section style={{ minHeight: "80vh", display: "grid", placeItems: "center", padding: "0 6vw" }}>
          <p style={{ maxWidth: "48ch", textAlign: "center", opacity: 0.8 }}>
            Sections of normal content scroll over the WebGL layer. The camera dollies and the
            glass turns as you move. Swap the geometry for an optimized GLB to ship a product.
          </p>
        </section>
        <section style={{ height: "120vh" }} />
      </main>
    </div>
  );
}
