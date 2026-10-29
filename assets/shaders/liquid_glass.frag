// The liquid glass shader: a displacement-map refraction over the backdrop,
// standing in for the web kit's SVG feDisplacementMap liquid glass. Pixels
// near the rounded edge displace along the surface normal (strongest at the
// rim, zero at the center), with an optional per-channel spread for a
// chromatic fringe — the web filter carries none, so the brand default is
// dispersion 0 — and a thin bright rim highlight.
//
// Direction note: the web map samples outward past the rim (its R/G ramp
// reads beyond the element). Here the backdrop snapshot clamps at its
// bounds, so the sample pulls inward (`p - n * bend`) — still displacement
// along the rounded-rect normal, but magnifying at the rim instead of
// minifying. Flipping the sign is a one-character change once a snapshot
// with margins is verified on an Impeller device.
//
// Written for ImageFilter.shader (dart:ui), which the engine only supports
// on Impeller. The engine contract: the first float uniform is a vec2 the
// engine sets to the bound texture's size, and the first sampler2D is bound
// to the filter input (the backdrop snapshot). Dart side, see
// liquid_glass_program.dart; the widget guards with
// ImageFilter.isShaderFilterSupported and falls back to the solid glass card
// elsewhere (flutter test, Skia).
#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;         // engine-set: texture size (first float uniform)
uniform vec4 uLens;         // radius px, edge width px, refraction px, dispersion px
uniform float uHighlight;   // rim highlight strength, 0..1

uniform sampler2D uBackdrop; // engine-set: the filter input

out vec4 fragColor;

// Signed distance to the rounded rect of halfSize at radius: negative inside.
float rrectSdf(vec2 p, vec2 halfSize, float radius) {
  vec2 q = abs(p) - halfSize + radius;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

// Numerical gradient of the SDF: the outward surface normal.
vec2 sdfNormal(vec2 p, vec2 halfSize, float radius) {
  const float e = 0.5;
  float dx =
      rrectSdf(p + vec2(e, 0.0), halfSize, radius) - rrectSdf(p - vec2(e, 0.0), halfSize, radius);
  float dy =
      rrectSdf(p + vec2(0.0, e), halfSize, radius) - rrectSdf(p - vec2(0.0, e), halfSize, radius);
  return normalize(vec2(dx, dy) + vec2(1e-6));
}

vec3 sampleBackdrop(vec2 p) {
  vec2 uv = p / uSize;
#ifdef IMPELLER_TARGET_OPENGLES
  // Reverse y axis for the OpenGL backend, per the engine contract.
  uv.y = 1.0 - uv.y;
#endif
  return texture(uBackdrop, clamp(uv, vec2(0.0), vec2(1.0))).rgb;
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 halfSize = uSize * 0.5;
  float radius = max(uLens.x, 0.0);
  float d = rrectSdf(p, halfSize, radius);
  if (d > 0.0) {
    // Outside the pane: the widget's clip draws nothing here anyway.
    fragColor = vec4(0.0);
    return;
  }
  vec2 n = sdfNormal(p, halfSize, radius);
  float edgeWidth = max(uLens.y, 1.0);
  // 0 deep inside, 1 at the very edge; bend quadratically like a lens rim.
  float t = clamp(1.0 + d / edgeWidth, 0.0, 1.0);
  float bend = t * t;
  float refraction = max(uLens.z, 0.0);
  float dispersion = max(uLens.w, 0.0);
  vec3 rgb = vec3(
    sampleBackdrop(p - n * (refraction + dispersion) * bend).r,
    sampleBackdrop(p - n * refraction * bend).g,
    sampleBackdrop(p - n * max(refraction - dispersion, 0.0) * bend).b
  );
  // Thin bright rim just inside the border, like the kit's inner highlight.
  float rim = exp(-d * d / 1.2) * uHighlight;
  fragColor = vec4(rgb + rim, 1.0);
}
