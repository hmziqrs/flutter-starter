// The hmziq brand material shader: 30 procedural material modes, two layers
// mixed with a blend mode, a dark/mid/bright palette ramp, diffuse + specular
// lighting, vignette and grain.
//
// GLSL port of `@hmziq/brand-core` `src/shaders/source.ts` (WGSL) for Flutter's
// fragment shader runtime. The uniform float slots mirror the WGSL `Params`
// struct order (see `setBrandMaterialUniforms` in brand_material_program.dart):
//
//   0-3   viewport  (width, height, time, output mode)
//   4-7   mixing    (mix, blend, exposure, saturation)
//   8-11  light     (relief, lightAngle, vignette, roughness)
//   12-15 dark      (rgb, 1)
//   16-19 mid       (rgb, 1)
//   20-23 bright    (rgb, 1)
//   24-27 view      (offsetX, offsetY, zoom, compare)
//   28-31 finish    (grain, lightIntensity, maskMode, 0)
//   32-43 layer a   (shape: mode/scale/warp/detail, surface: angle/seed/density/speed, tone: contrast/balance/grain/0)
//   44-55 layer b   (same layout)
//   56-63 Flutter text-mask extension: 56 amount, 57 tintAmount, 60-62 tint rgb
//         (the WGSL struct's reserved0/reserved1 slots, unused by the web kit)
//
// Slot 0 of the sampler array carries the child snapshot for the text-mask
// mode (BrandMaterialText); the plain material modes never read it.
#version 460 core

uniform sampler2D uTexture;
uniform vec4 uViewport; // width, height, time, output
uniform vec4 uMixing;   // mix, blend, exposure, saturation
uniform vec4 uLight;    // relief, lightAngle, vignette, roughness
uniform vec4 uDark;     // palette dark rgb
uniform vec4 uMid;      // palette mid rgb
uniform vec4 uBright;   // palette bright rgb
uniform vec4 uView;     // offsetX, offsetY, zoom, compare
uniform vec4 uFinish;   // grain, lightIntensity, maskMode, 0
uniform vec4 uAShape;   // mode, scale, warp, detail
uniform vec4 uASurface; // angle, seed, density, speed
uniform vec4 uATone;    // contrast, balance, grain, 0
uniform vec4 uBShape;
uniform vec4 uBSurface;
uniform vec4 uBTone;
uniform vec4 uText0; // amount, tintAmount, 0, 0
uniform vec4 uTint;  // tint rgb

out vec4 fragColor;

const float PI = 3.14159265359;
const float TAU = 6.28318530718;

// The WGSL kit hashes lattice cells with uint bit mixing, which the SkSL
// backend (flutter test, macOS Skia) rejects — no bitwise integer ops and no
// bitcasts survive SPIRV-Cross. This is the standard sin-free float lattice
// hash instead: same [0, 1) contract, same fbm/ridged/cells structure, so the
// materials read the same while individual pixels differ from the web render.
float hash11(vec2 p) {
  vec3 p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
  vec3 p3 = fract(vec3(p.x, p.y, p.x) * vec3(0.1031, 0.1030, 0.0973));
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.xx + p3.yz) * p3.zy);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 q = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
  return mix(
    mix(hash11(i), hash11(i + vec2(1.0, 0.0)), q.x),
    mix(hash11(i + vec2(0.0, 1.0)), hash11(i + vec2(1.0, 1.0)), q.x),
    q.y
  );
}

vec2 rotate(vec2 p, float a) {
  return vec2(cos(a) * p.x - sin(a) * p.y, sin(a) * p.x + cos(a) * p.y);
}

float fbm(vec2 p0, int octaves) {
  vec2 p = p0;
  float sum = 0.0;
  float amp = 0.5;
  float norm = 0.0;
  for (int i = 0; i < 6; i++) {
    if (i >= octaves) { break; }
    sum += noise(p) * amp;
    norm += amp;
    p = rotate(p, 0.53) * 2.07 + vec2(13.7, 3.2);
    amp *= 0.49;
  }
  return sum / norm;
}

float ridged(vec2 p0, int octaves) {
  vec2 p = p0;
  float sum = 0.0;
  float amp = 0.5;
  float norm = 0.0;
  for (int i = 0; i < 5; i++) {
    if (i >= octaves) { break; }
    sum += (1.0 - abs(noise(p) * 2.0 - 1.0)) * amp;
    norm += amp;
    p = rotate(p, 0.37) * 2.14 + vec2(7.1, 3.7);
    amp *= 0.5;
  }
  return sum / norm;
}

vec3 cells(vec2 p) {
  vec2 base = floor(p);
  vec2 f = fract(p);
  float first = 9.0;
  float second = 9.0;
  float identity = 0.0;
  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      vec2 g = vec2(float(x), float(y));
      vec2 rnd = hash22(base + g);
      float d = length(g + rnd - f);
      if (d < first) {
        second = first;
        first = d;
        identity = rnd.x;
      } else if (d < second) {
        second = d;
      }
    }
  }
  return vec3(first, second - first, identity);
}

vec4 cell_point(vec2 p) {
  vec2 base = floor(p);
  vec2 f = fract(p);
  vec4 result = vec4(0.0, 0.0, 0.0, 9.0);
  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      vec2 g = vec2(float(x), float(y));
      vec2 rnd = hash22(base + g);
      vec2 delta = f - g - rnd;
      float dist = length(delta);
      if (dist < result.w) {
        result = vec4(delta, rnd.x, dist);
      }
    }
  }
  return result;
}

vec2 strokes(vec2 p, float spread, float width, float aa) {
  vec2 base = floor(p);
  vec2 f = fract(p);
  float core = 0.0;
  float edge = 0.0;
  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      vec2 g = vec2(float(x), float(y));
      vec2 rnd = hash22(base + g + vec2(83.0, 127.0));
      float angle = (rnd.x - 0.5) * spread;
      vec2 v = rotate(f - g - rnd, -angle);
      float len = 0.13 + rnd.y * 0.43;
      float wobble = sin(v.x * 4.0 + rnd.x * TAU) * 0.009 * spread;
      float tip = max(abs(v.x) - len, 0.0);
      float d = length(vec2(tip, v.y + wobble));
      float d2 = length(vec2(tip, v.y + wobble - width * 2.8));
      float fade = 0.5 + 0.5 * rnd.y;
      core = max(core, (1.0 - smoothstep(width, width + aa, d)) * fade);
      edge = max(edge, (1.0 - smoothstep(width * 0.5, width + aa, d2)) * fade);
    }
  }
  return vec2(core, edge);
}

vec3 material(vec2 pos, vec4 shape, vec4 surface, vec4 tone) {
  int mode = int(shape.x + 0.5);
  int detail = int(clamp(shape.w, 2.0, 6.0));
  float seed = surface.y;
  float density = surface.z;
  float time = uViewport.z * surface.w;
  vec2 p = rotate(pos * shape.y, surface.x) + vec2(seed * 0.173, seed * 0.397) + vec2(time * 0.035, time * 0.021);
  float distortion = shape.z;
  vec2 warp = vec2(fbm(p * 0.62 + vec2(5.2, 1.3), 3), fbm(p * 0.62 + vec2(1.1, 9.2), 3)) - 0.5;
  vec2 q = p + warp * distortion * 2.7;
  float height = 0.5;
  float t = 0.5;
  float metal = 0.3;
  switch (mode) {
    case 0: { // cast iron pitting
      vec2 local = p + warp * distortion * 0.65;
      float coarseField = fbm(local * 2.5, detail);
      float micro = fbm(p * 27.0 + warp * 0.2, 3);
      float spread = smoothstep(0.35, 0.64, coarseField + 0.10 * (micro - 0.5));
      vec3 pits = cells(p * (18.0 + density * 17.0));
      float pock = 1.0 - smoothstep(0.07, 0.24, pits.x);
      float crust = ridged(p * 10.5, 4);
      height = 0.30 + spread * 0.16 + crust * 0.065 - pock * 0.026;
      t = 0.17 + spread * 0.67 + (micro - 0.5) * 0.30 - pock * 0.11;
      metal = mix(0.4, 0.025, spread);
    } break;
    case 1: { // brushed metal bands
      float bands = fbm(vec2(q.x * 0.17, q.y * (3.0 + density * 3.0)), detail);
      float brush = noise(vec2(q.x * 0.75, q.y * (160.0 + density * 90.0)));
      float hair = noise(vec2(q.x * 4.0, q.y * 610.0));
      float reflection = pow(0.5 + 0.5 * sin(q.y * 2.2 + fbm(q * 0.45, 3) * 5.0), 3.0);
      height = 0.3 + bands * 0.35 + brush * 0.065;
      t = 0.12 + bands * 0.36 + reflection * 0.5 + (brush - 0.5) * 0.13 + (hair - 0.5) * 0.05;
      metal = 0.95;
    } break;
    case 2: { // folded foil
      vec2 w = vec2(fbm(q * 0.55, detail), fbm(q * 0.55 + 13.0, detail));
      float fold = sin(q.y * (3.0 + density * 2.0) + w.x * 9.0 + w.y * 4.0);
      float crease = pow(1.0 - abs(fold), 6.0);
      height = 0.34 + fold * 0.19 + ridged(q * 2.0, 4) * 0.27;
      t = 0.18 + (fold * 0.5 + 0.5) * 0.38 + crease * 0.27 + fbm(q * 6.0, 3) * 0.18;
      metal = 1.0;
    } break;
    case 3: { // mineral cracks
      vec3 c = cells(q * (2.5 + density * 2.5));
      float crack = smoothstep(0.01, 0.08, c.y);
      float speck = fbm(q * 38.0, detail);
      height = crack * (0.36 + c.z * 0.3) + speck * 0.12;
      t = 0.09 + crack * (0.2 + c.z * 0.45) + (speck - 0.5) * 0.21;
      metal = 0.42 + 0.35 * c.z;
    } break;
    case 4: { // sediment strata
      float strata = q.y * (6.0 + density * 5.0) + fbm(q * 0.65, detail) * 7.0;
      float band = 0.5 + 0.5 * sin(strata * TAU);
      float silt = fbm(q * 24.0, 3);
      float narrow = pow(band, 14.0);
      height = 0.35 + band * 0.15 + fbm(q * 1.9, detail) * 0.24;
      t = 0.18 + band * 0.32 + narrow * 0.18 + (silt - 0.5) * 0.15;
      metal = 0.18;
    } break;
    case 5: { // woven weave
      float phase = q.x * (15.0 + density * 19.0) + sin(q.y * 2.0) * distortion;
      float a = sin(phase + fbm(q * 0.4, detail) * 4.0);
      float b = sin(q.y * (16.3 + density * 17.0) + q.x * 1.7 + cos(q.x * 1.3) * distortion);
      float weave = a * b;
      float envelope = 0.5 + 0.5 * sin(q.x * 1.3 + q.y * 0.7 + weave * 2.0);
      height = 0.48 + weave * 0.11;
      t = 0.18 + envelope * 0.48 + weave * 0.16;
      metal = 0.65;
    } break;
    case 6: { // mica cell edges
      vec3 c = cells(q * (2.0 + density * 2.0));
      vec3 d = cells(rotate(q, -0.3) * (3.1 + density * 1.0) + vec2(11.0, 7.0));
      float a = pow(1.0 - clamp(c.y * 3.8, 0.0, 1.0), 8.0);
      float b = pow(1.0 - clamp(d.y * 4.0, 0.0, 1.0), 10.0);
      height = fbm(q * 1.3, detail) * 0.6 + c.x * 0.18;
      t = 0.10 + fbm(q * 0.7, 3) * 0.24 + a * 0.58 + b * 0.28;
      metal = 0.8;
    } break;
    case 7: { // silk fibers
      float flow = fbm(q * 0.8, detail) * 4.5 + fbm(q * 2.2, 3) * 0.9;
      float phase = q.y * (22.0 + density * 25.0) + flow * (1.0 + distortion * 0.4);
      float fiber = pow(0.5 + 0.5 * sin(phase), 8.0);
      float shoulder = 0.5 + 0.5 * sin(phase + 0.7);
      float broad = fbm(q * 0.45, 3);
      height = 0.32 + shoulder * 0.08 + broad * 0.28;
      t = 0.1 + broad * 0.3 + fiber * (0.25 + broad * 0.3);
      metal = 0.75;
    } break;
    case 8: { // fine grain dust
      float coarse = fbm(q * 4.0, detail);
      float dust = hash11(q * (300.0 + density * 180.0));
      float clumps = noise(q * 85.0);
      height = 0.35 + coarse * 0.2 + clumps * 0.045;
      t = 0.2 + coarse * 0.44 + (dust - 0.5) * 0.19 + (clumps - 0.5) * 0.14;
      metal = 0.02;
    } break;
    case 9: { // oxide sweep beams
      float bend = p.y * (1.0 + p.x * 0.018) + fbm(p * 0.32, 3) * distortion * 0.5;
      float bands = fbm(vec2(p.x * 0.12, bend * (7.0 + density * 5.0)), detail);
      float beams = pow(bands, 4.0) * 2.5;
      float streak = pow(noise(vec2(p.x * 0.11, bend * (44.0 + density * 25.0))), 16.0);
      float wash = fbm(vec2(p.x * 0.25, bend * 1.3), 3);
      height = 0.4 + bands * 0.2;
      t = 0.12 + wash * 0.43 + beams * 0.7 + streak * 0.34;
      metal = 0.58;
    } break;
    case 10: { // porous ceramic
      vec3 pore = cells(q * (3.0 + density * 3.0));
      vec3 micro = cells(q * (19.0 + density * 6.0) + 17.0);
      float body = smoothstep(0.08, 0.65, pore.x);
      float rim = exp(-pow((pore.x - 0.51) * 8.0, 2.0));
      float pin = (1.0 - smoothstep(0.06, 0.18, micro.x)) * 0.1;
      float chalk = fbm(q * 34.0, detail);
      height = 0.24 + body * 0.35 + rim * 0.025 - pin * 0.35;
      t = 0.18 + body * 0.56 + rim * 0.15 - pin + (chalk - 0.5) * 0.1;
      metal = 0.05;
    } break;
    case 11: { // hammered dents
      vec3 c = cells(q * (5.0 + density * 4.0));
      vec3 d = cells(rotate(q, 0.8) * (7.0 + density * 2.0) + 31.0);
      float dimples = pow(clamp(c.x, 0.0, 1.0), 0.65);
      float fine = fbm(q * 30.0, detail);
      height = 0.3 + dimples * 0.21 + d.x * 0.055 + (fine - 0.5) * 0.025;
      t = 0.18 + dimples * 0.30 + c.z * 0.17 + fbm(q * 0.9, 3) * 0.20;
      metal = 0.98;
    } break;
    case 12: { // ink diffusion
      vec2 advect = vec2(fbm(q * 0.9, detail), fbm(q * 0.9 + vec2(9.0, 7.0), detail));
      vec2 flow = q + advect * (1.4 + distortion * 2.0);
      float ink = fbm(flow * (1.7 + density), detail);
      float eddy = fbm(flow * 4.0 + advect * 3.0, detail);
      float body = smoothstep(0.24, 0.73, ink + (eddy - 0.5) * 0.18);
      float feather = pow(1.0 - abs(eddy * 2.0 - 1.0), 7.0);
      height = 0.38 + body * 0.08;
      t = 0.10 + body * 0.79 + (feather - 0.5) * 0.09;
      metal = 0.02;
    } break;
    case 13: { // frost needles
      vec2 crystal = q * (1.2 + density * 0.55);
      float a = ridged(vec2(crystal.x * 14.0, crystal.y * 1.4), detail);
      vec2 turned = rotate(crystal, 1.0472);
      float b = ridged(vec2(turned.x * 18.0, turned.y * 1.6), detail);
      vec2 turned2 = rotate(crystal, -1.0472);
      float c = ridged(vec2(turned2.x * 11.0, turned2.y * 1.2), detail);
      float needles = pow(clamp(max(a, max(b, c)), 0.0, 1.0), 7.0);
      float cloud = fbm(q * 1.3, detail);
      height = 0.28 + cloud * 0.16 + needles * 0.055;
      t = 0.1 + cloud * 0.35 + needles * 1.3;
      metal = 0.6;
    } break;
    case 14: { // terrazzo chips
      vec3 stone = cells((p + warp * distortion * 0.35) * (5.0 + density * 4.0));
      vec3 tiny = cells(q * (27.0 + density * 9.0) + 73.0);
      float chip = smoothstep(0.065, 0.10, stone.y) * smoothstep(0.18, 0.28, stone.z);
      float grit = smoothstep(0.14, 0.20, tiny.y) * smoothstep(0.6, 0.7, tiny.z);
      float dust = fbm(p * 65.0, detail);
      height = 0.40 + chip * 0.012 + grit * 0.003 + (dust - 0.5) * 0.007;
      t = mix(0.87, 0.08 + stone.z * 0.49, chip) - grit * 0.28 + (dust - 0.5) * 0.07;
      metal = 0.12 + chip * 0.25;
    } break;
    case 15: { // liquid chrome swells
      vec2 flow = vec2(fbm(q * 0.55, detail), fbm(q * 0.55 + vec2(3.0, 19.0), detail));
      vec2 liquid = q + flow * (1.0 + distortion * 2.4);
      float swell = fbm(liquid * (0.9 + density * 0.6), detail);
      float curvature = sin(swell * 13.0 + liquid.y * 0.7);
      float reflection = pow(0.5 + 0.5 * cos(swell * 18.0 + liquid.x * 0.4), 9.0);
      height = 0.3 + swell * 0.4 + curvature * 0.07;
      t = 0.1 + (curvature * 0.5 + 0.5) * 0.44 + reflection * 0.50;
      metal = 1.0;
    } break;
    case 16: { // wind-carved dunes
      float flow = fbm(q * 0.55, detail);
      float phase = q.y * (3.0 + density * 3.0) + flow * (4.0 + distortion * 2.0);
      float wave = 0.5 + 0.5 * sin(phase);
      float dune = pow(wave, 2.4);
      float ripples = sin(phase * 11.0 + fbm(q * 2.0, 3) * 3.0) * 0.5 + 0.5;
      float dust = hash11(p * 700.0);
      height = 0.3 + dune * 0.24 + ripples * 0.009;
      t = 0.22 + dune * 0.49 + (ripples - 0.5) * 0.12 + (dust - 0.5) * 0.07;
      metal = 0.025;
    } break;
    case 17: { // halftone dots
      float freq = 15.0 + density * 17.0;
      vec2 grid = rotate(p, 0.7854) * freq;
      vec2 cell = floor(grid);
      vec2 center = rotate((cell + 0.5) / freq, -0.7854);
      float field = fbm(center * 1.6 + warp * distortion * 1.2, detail);
      float radius = 0.09 + smoothstep(0.25, 0.75, field) * 0.57;
      float edge = max(0.015, freq * 3.0 / uViewport.y);
      float dots = 1.0 - smoothstep(radius - edge, radius + edge, length(fract(grid) - 0.5));
      float paper = fbm(p * 45.0, 3);
      height = 0.4 + dots * 0.005;
      t = 0.06 + dots * 0.86 + (paper - 0.5) * 0.045;
      metal = 0.0;
    } break;
    case 18: { // endgrain wood
      vec2 center = hash22(vec2(seed, seed + 13.0)) * 2.4 - 1.2;
      vec2 wood = rotate(pos * shape.y, surface.x) - center;
      float radial = length(wood * vec2(1.0, 1.12) + warp * distortion * 0.9);
      float growth = radial * (6.0 + density * 6.0) + fbm(wood * 2.0 + seed * 0.11, detail) * distortion * 2.0;
      float latewood = pow(0.5 + 0.5 * sin(growth * TAU), 12.0);
      float fibers = fbm(vec2(radial * 85.0, atan(wood.y, wood.x) * 12.0), detail);
      float vessels = pow(noise(wood * 110.0), 12.0);
      height = 0.38 + latewood * 0.035 + fibers * 0.025;
      t = 0.7 - latewood * 0.4 + (fibers - 0.5) * 0.22 - vessels * 0.19;
      metal = 0.02;
    } break;
    case 19: { // plain woven linen
      vec2 cloth = (p + warp * distortion * 0.18) * (12.0 + density * 12.0);
      vec2 cell = floor(cloth);
      vec2 f = fract(cloth);
      // mod matches the WGSL `(i32 & 1) == 0` parity for negative cells too.
      bool over = mod(cell.x + cell.y, 2.0) == 0.0;
      float across = over ? f.y : f.x;
      float along = over ? f.x : f.y;
      float yarn = pow(max(0.0, cos((across - 0.5) * PI)), 0.6);
      float bend = 0.72 + 0.28 * sin(along * PI);
      float filament = sin(across * TAU * 8.0 + noise(p * 5.0) * 2.0);
      float slub = fbm(p * 14.0, detail);
      height = 0.3 + yarn * bend * 0.085 + filament * 0.002;
      t = 0.18 + yarn * bend * 0.46 + (slub - 0.5) * 0.22 + filament * 0.045;
      metal = 0.015;
    } break;
    case 20: { // carbon twill
      vec2 cloth = rotate(p + warp * distortion * 0.1, 0.7854) * (8.0 + density * 8.0);
      vec2 cell = floor(cloth);
      vec2 f = fract(cloth);
      // mod 4 matches the WGSL `(i32 & 3) < 2` twill rule for negatives.
      bool over = mod(cell.x - cell.y, 4.0) < 2.0;
      float across = over ? f.y : f.x;
      float along = over ? f.x : f.y;
      float bundle = pow(max(0.0, sin(across * PI)), 0.42);
      float filaments = 0.5 + 0.5 * sin(across * TAU * 10.0);
      float reflection = pow(0.5 + 0.5 * sin(p.x * 0.85 + p.y * 0.55 + (over ? 1.4 : 0.0)), 4.0);
      float resin = fbm(q * 3.0, detail);
      height = 0.35 + bundle * 0.035 + sin(along * PI) * 0.006 + filaments * 0.0007;
      t = 0.08 + bundle * 0.22 + reflection * bundle * 0.36 + filaments * 0.065 + (resin - 0.5) * 0.07;
      metal = 0.92;
    } break;
    case 21: { // pebbled leather
      vec2 local = p + warp * distortion * 0.3;
      vec3 c = cells(local * (13.0 + density * 10.0));
      float dome = smoothstep(0.0, 0.21, c.y);
      float pores = pow(noise(q * 170.0), 8.0);
      float wrinkles = ridged(local * 1.9, detail);
      height = 0.38 + dome * 0.035 + wrinkles * 0.025 - pores * 0.006;
      t = 0.18 + dome * 0.26 + wrinkles * 0.16 + c.z * 0.1 - pores * 0.12;
      metal = 0.09;
    } break;
    case 22: { // creased paper
      vec2 paper = p + warp * distortion * 0.35;
      float folds = 0.0;
      float crease = 1.0;
      for (int i = 0; i < 6; i++) {
        vec2 rnd = hash22(vec2(float(i) + seed, 41.0));
        vec2 axis = vec2(cos(rnd.x * TAU), sin(rnd.x * TAU));
        float phase = dot(paper, axis) * (0.7 + rnd.y * 2.7) * (0.7 + density * 0.3) + rnd.x * 11.0;
        float fold = abs(fract(phase) - 0.5);
        folds += fold * (0.14 + 0.08 * rnd.x);
        crease = min(crease, fold);
      }
      float pulp = fbm(p * 45.0, detail);
      height = 0.2 + folds + (pulp - 0.5) * 0.002;
      t = 0.67 + (folds - 0.28) * 0.2 - exp(-crease * 170.0) * 0.03 + (pulp - 0.5) * 0.045;
      metal = 0.01;
    } break;
    case 23: { // scratched enamel
      float freq = 4.0 + density * 4.0;
      vec2 marks = strokes(p * freq, 0.25 + distortion * 2.0, 0.0025, max(0.001, freq * 3.0 / uViewport.y));
      float orangePeel = fbm(q * 23.0, detail);
      float reflection = pow(0.5 + 0.5 * sin(p.y * 1.7 + fbm(q * 0.8, 3) * 3.0), 5.0);
      height = 0.4 + (orangePeel - 0.5) * 0.009 - marks.x * 0.013;
      t = 0.12 + reflection * 0.18 + (orangePeel - 0.5) * 0.12 + marks.x * 0.32 + marks.y * 0.34;
      metal = 0.72;
    } break;
    case 24: { // mica flakes facets
      vec4 c = cell_point(q * (11.0 + density * 8.0));
      vec2 tilt = vec2(cos(c.z * TAU), sin(c.z * TAU));
      float facet = dot(c.xy, tilt);
      float gleam = pow(0.5 + 0.5 * sin(c.z * TAU + p.x * 0.23 + p.y * 0.1), 15.0);
      vec3 small = cells(q * (39.0 + density * 17.0) + 53.0);
      float grit = fbm(q * 63.0, detail);
      height = 0.39 + facet * 0.018 + small.z * 0.002;
      t = 0.08 + c.z * 0.18 + gleam * 0.70 + facet * 0.15 + (grit - 0.5) * 0.12;
      metal = 0.95;
    } break;
    case 25: { // lava fissures
      vec3 rock = cells(q * (1.8 + density * 1.9));
      float fracture = 1.0 - smoothstep(0.012, 0.07, rock.y);
      float crust = ridged(q * 13.0, detail);
      float rope = pow(0.5 + 0.5 * sin(q.x * 19.0 + fbm(q * 3.0, 3) * 16.0), 6.0);
      float ash = fbm(q * 49.0, 3);
      height = 0.35 + crust * 0.075 + rope * 0.012 - fracture * 0.07;
      t = 0.16 + crust * 0.23 + ash * 0.12 + rope * 0.04 + fracture * (0.60 + rock.z * 0.24);
      metal = 0.18;
    } break;
    case 26: { // condensation droplets
      float freq = 4.0 + density * 3.0;
      vec4 c = cell_point((p + warp * distortion * 0.22) * freq);
      float radius = 0.11 + c.z * 0.25;
      float r = c.w / radius;
      float coverage = (1.0 - smoothstep(0.91, 1.0, r)) * smoothstep(0.2, 0.27, c.z);
      float dome = sqrt(max(0.0, 1.0 - r * r)) * coverage;
      float rim = exp(-pow((r - 0.86) * 17.0, 2.0)) * coverage;
      vec2 off = c.xy / radius + vec2(0.29, 0.31);
      float highlight = exp(-dot(off, off) * 58.0) * coverage;
      float backdrop = fbm(q * 1.1 + c.xy * dome * 1.3, detail);
      height = 0.38 + dome * 0.13;
      t = 0.20 + backdrop * 0.25 - dome * 0.11 + rim * 0.17 + highlight * 0.67;
      metal = 0.78;
    } break;
    case 27: { // interference film
      vec2 flow = vec2(fbm(q * 0.55, detail), fbm(q * 0.55 + vec2(21.0, 6.0), detail));
      float film = fbm(q * 0.82 + flow * (2.0 + distortion * 2.1), detail);
      float thickness = film * (7.0 + density * 7.0);
      float fringe = sin(thickness * 3.0) * 0.26 + sin(thickness * 6.7 + 0.6) * 0.15 + cos(thickness * 11.0) * 0.06;
      height = 0.33 + film * 0.19;
      t = 0.5 + fringe;
      metal = 0.84;
    } break;
    case 28: { // embossed labyrinth ridges
      vec2 v = q * (9.0 + density * 5.0);
      float field = sin(v.x + cos(v.y * 0.72)) + cos(v.y + sin(v.x * 0.63));
      float ridge = exp(-pow(field * 2.9, 2.0));
      float fine = fbm(q * 38.0, detail);
      height = 0.33 + ridge * 0.10 + (fine - 0.5) * 0.003;
      t = 0.12 + ridge * 0.65 + (fine - 0.5) * 0.08;
      metal = 0.6;
    } break;
    case 29: { // fibrous paper
      float freq = 8.0 + density * 5.0;
      vec2 fibers = strokes(q * freq, 6.0, 0.004, max(0.001, freq * 3.0 / uViewport.y));
      vec2 fine = strokes(rotate(p, 0.83) * freq * 2.4, 4.5, 0.004, max(0.001, freq * 7.2 / uViewport.y));
      float pulp = fbm(q * 5.0, detail);
      height = 0.4 + (pulp - 0.5) * 0.02 + fibers.x * 0.003 - fine.x * 0.002;
      t = 0.57 + (pulp - 0.5) * 0.48 + fibers.x * 0.19 - fine.x * 0.20;
      metal = 0.015;
    } break;
    default: {
      height = 0.5;
      t = 0.5;
      metal = 0.0;
    }
  }
  float grain = (hash11(p * 540.0) - 0.5) * tone.z * 0.28;
  t = (t - 0.5) * tone.x + 0.5 + tone.y + grain;
  return vec3(height, clamp(t, 0.0, 1.0), metal);
}

float blend(float a, float b, int mode) {
  switch (mode) {
    case 1:
      return a * b;
    case 2:
      return 1.0 - (1.0 - a) * (1.0 - b);
    case 3:
      return a > 0.5 ? 1.0 - 2.0 * (1.0 - a) * (1.0 - b) : 2.0 * a * b;
    case 4:
      return (1.0 - 2.0 * b) * a * a + 2.0 * b * a;
    case 5:
      return abs(a - b);
    default:
      return b;
  }
}

vec3 ramp(float t0) {
  float t = clamp(t0, 0.0, 1.0);
  vec3 lower = mix(uDark.rgb, uMid.rgb, smoothstep(0.03, 0.63, t));
  return mix(lower, uBright.rgb, smoothstep(0.57, 1.0, t));
}

// The mixed height field (layer a blended with layer b) at one position —
// the same channel the web kit differentiates: height mixes the two layers'
// raw heights directly; only the tone channel goes through the blend mode.
// The SkSL runtime target has no dFdx/dFdy, so the surface normal below comes
// from pixel-scaled forward differences of this field — the same per-pixel
// difference the web kit gets from its screen-space derivatives.
float heightField(vec2 pos) {
  float h = material(pos, uAShape, uASurface, uATone).x;
  if (uMixing.x > 0.0001) {
    float bh = material(pos, uBShape, uBSurface, uBTone).x;
    h = mix(h, bh, uMixing.x);
  }
  return h;
}

void main() {
  vec2 frag = gl_FragCoord.xy;
  vec2 screen = frag / uViewport.xy;
  vec2 p = (frag - uViewport.xy * 0.5) / uViewport.y * 3.0 / max(uView.z, 0.1) + uView.xy;
  vec3 a = material(p, uAShape, uASurface, uATone);
  vec3 field = a;
  if (uMixing.x > 0.0001) {
    vec3 b = material(p, uBShape, uBSurface, uBTone);
    field = vec3(
      mix(a.x, b.x, uMixing.x),
      mix(a.y, blend(a.y, b.y, int(uMixing.y + 0.5)), uMixing.x),
      mix(a.z, b.z, uMixing.x)
    );
  }
  if (uView.w >= 0.0 && screen.x < uView.w) {
    field = a;
  }
  // One pixel of p-space; the difference across it stands in for dpdx/dpdy,
  // scaled the same way the web kit scales its screen-space derivatives.
  float px = 3.0 / (uViewport.y * max(uView.z, 0.1));
  vec2 gradient = vec2(
    heightField(p + vec2(px, 0.0)) - field.x,
    heightField(p + vec2(0.0, px)) - field.x
  ) * (uViewport.y / 3.0);
  vec3 normal = normalize(vec3(-gradient * uLight.x, 1.0));
  if (uViewport.w > 0.5 && uViewport.w < 1.5) {
    fragColor = vec4(vec3(clamp(field.x, 0.0, 1.0)), 1.0);
    return;
  }
  if (uViewport.w > 1.5 && uViewport.w < 2.5) {
    fragColor = vec4(normal * 0.5 + 0.5, 1.0);
    return;
  }
  if (uViewport.w > 2.5) {
    fragColor = vec4(vec3(field.y), 1.0);
    return;
  }
  vec3 light = normalize(vec3(cos(uLight.y) * 0.65, sin(uLight.y) * 0.65, 0.8));
  float diffuse = max(0.0, dot(normal, light));
  vec3 halfVector = normalize(light + vec3(0.0, 0.0, 1.0));
  float shininess = mix(100.0, 5.0, uLight.w);
  float spec = pow(max(0.0, dot(normal, halfVector)), shininess) * field.z * (1.0 - uLight.w * 0.72);
  vec3 color = ramp(field.y);
  color *= mix(1.0, 0.48 + diffuse * 0.72, uFinish.y);
  color += uBright.rgb * spec * uFinish.y * 0.55;
  float radial = length((screen - 0.5) * vec2(1.0, 0.8));
  color *= 1.0 - uLight.z * smoothstep(0.15, 0.75, radial);
  float grain = (hash11((p + vec2(91.4, 5.1)) * 520.0) - 0.5) * uFinish.x * 0.16;
  color += vec3(grain);
  float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
  color = mix(vec3(luminance), color, uMixing.w) * exp2(uMixing.z);
  if (uFinish.z > 0.5) {
    // Text-mask mode (BrandMaterialText): the child snapshot in uTexture is a
    // solid-color text raster; its alpha gates the material. Output is
    // premultiplied. Amount blends toward the flat tint color; tintAmount
    // tints the material itself toward the tint.
    float coverage = texture(uTexture, screen).a;
    vec3 flatColor = mix(uBright.rgb, uTint.rgb, uText0.y);
    vec3 matColor = mix(color, uTint.rgb, uText0.y);
    vec3 ink = mix(flatColor, matColor, uText0.x);
    fragColor = vec4(ink * coverage, coverage);
    return;
  }
  fragColor = vec4(clamp(color, vec3(0.0), vec3(1.0)), 1.0);
}
