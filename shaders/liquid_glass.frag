#version 460 core

// Liquid glass capsule, drawn as a paint shader (works on Skia, Impeller and
// web). The content below the capsule comes in as an image; the shader shows
// it 1:1 in the flat centre and bends it inwards in the bezel ring, following
// https://kube.io/blog/liquid-glass-css-svg/ (convex bezel, displacement only
// near the edge, falling smoothly to 0 where the flat part starts).

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;       // capsule size (logical px)
uniform vec4 uImageRect;  // where the content image sits, capsule-local
uniform float uBezel;     // width of the curved rim (px)
uniform float uDepth;     // max displacement at the very edge (px)
uniform vec4 uTrack;      // track colour (premultiplied) behind the content

uniform sampler2D uContent;

out vec4 fragColor;

float sdStadium(vec2 p, vec2 halfSize) {
  float r = halfSize.y;
  vec2 q = abs(p) - vec2(halfSize.x - r, 0.0);
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

vec4 contentAt(vec2 p) {
  vec2 uv = (p - uImageRect.xy) / uImageRect.zw;
  vec4 c = vec4(0.0);
  if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
    c = texture(uContent, uv);
  }
  return c + uTrack * (1.0 - c.a);
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 halfSize = uSize * 0.5;
  vec2 local = p - halfSize;

  float d = -sdStadium(local, halfSize); // distance inside the edge
  float x = clamp(d / uBezel, 0.0, 1.0);

  // Outward normal from the distance field.
  vec2 e = vec2(0.5, 0.0);
  vec2 n = vec2(
    sdStadium(local + e.xy, halfSize) - sdStadium(local - e.xy, halfSize),
    sdStadium(local + e.yx, halfSize) - sdStadium(local - e.yx, halfSize));
  float nl = length(n);
  n = nl > 0.0001 ? n / nl : vec2(0.0);

  // Strongest at the edge, 0 with zero slope where the bezel ends. The
  // caller keeps 2 * uDepth < uBezel, so the image never folds over (which
  // would show parts twice).
  float bend = (1.0 - x) * (1.0 - x);

  // Convex glass pulls the image from further inside.
  fragColor = contentAt(p - n * uDepth * bend);
}
