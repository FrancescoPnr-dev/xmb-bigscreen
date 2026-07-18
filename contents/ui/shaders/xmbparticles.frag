// SPDX-FileCopyrightText: 2025 Mart (https://github.com/linkev/PlayStation-3-XMB, MIT)
// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only AND MIT
//
// XMB particles — fragment shader (runs on the wave's displaced GridMesh, additive).
//
// The vertex stage (xmbparticles.vert) displaces this pass's grid exactly like the wave
// mesh, so uv space here IS the veil surface: sparkles laid out in uv cells ride the
// undulation and the folds with zero approximation. Screen-space derivatives turn the
// cell-space distances into pixels, so dots stay round however the ribbon bends.
// Constant cost (fixed 3x3 hash neighbourhood per fragment), white, additive.

#version 440

layout(location = 0) in vec2 vUv;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float flowSpeed;
    float timeStep;
    float rePipelineBlend;
    float bandAmplitude;
    float bandSecondaryFreq;
    float bandSecondaryAmp;
    float tension;
    float splineLength;
    float spacing;
    float perturbation;
    float perturbationScale;
    float travelSpeed1;
    float travelAmp1;
    float travelSpeed2;
    float travelAmp2;
    float waveCosAmp;
    float waveBias;
    float waveHeightScale;
    float waveSoftClip;
    float damping;
    float ffdScale1X;
    float ffdYAmp;
    float pFlowSpeed;
    float pOpacity;
    float pSizeBase;
    float pSizeVar;
    float pDensity;
    float pSpread;
};

vec2 hash22(vec2 p)
{
    float n = dot(p, vec2(127.1, 311.7));
    return fract(sin(vec2(n, n + 1.0)) * 43758.5453123);
}

void main()
{
    vec2 uv = vUv;
    float pt = time * pFlowSpeed;

    vec2 cells = vec2(46.0, 12.0) * clamp(pDensity, 0.05, 4.0);
    vec2 gp = uv * cells;

    // Local cell->pixel scale; capping the dot radius to ~one cell keeps dots inside
    // the 3x3 neighbourhood, so they compress with the ribbon instead of clipping.
    vec2 cpp = max(vec2(length(vec2(dFdx(gp.x), dFdy(gp.x))),
                        length(vec2(dFdx(gp.y), dFdy(gp.y)))), vec2(1e-6));
    float maxRadius = 0.8 / max(cpp.x, cpp.y);

    float spark = 0.0;
    for (int oy = -1; oy <= 1; ++oy) {
        for (int ox = -1; ox <= 1; ++ox) {
            vec2 cell = floor(gp) + vec2(float(ox), float(oy));
            vec2 rnd = hash22(cell);

            // Depth cue per row: far rows (top) are smaller, dimmer and slower; near
            // rows are bigger, brighter and drift faster, for a parallax feel.
            float depth = clamp((cell.y + 0.5) / cells.y, 0.0, 1.0);
            float dSize  = mix(0.55, 1.6, depth);
            float dGlow  = mix(0.35, 1.0, depth);
            float dDrift = mix(0.55, 1.45, depth);

            vec2 pos = cell + vec2(fract(rnd.x + pt * dDrift * (rnd.x - 0.5) * 0.15),
                                   rnd.y + 0.10 * sin(pt * (rnd.y + 1.5) + rnd.x * 100.0));
            float d = length((gp - pos) / cpp);
            float size = min((pSizeBase + rnd.y * pSizeVar) * 1.6 * dSize, maxRadius);
            float dot1 = smoothstep(size, 0.0, d);
            float tw = 0.5 + 0.5 * sin(pt * (1.0 + rnd.x * 2.0) + rnd.y * 6.2831);
            spark += dot1 * tw * tw * dGlow;
        }
    }

    // Soften the ribbon's cut top/bottom rows so the cloud has no hard edge.
    float edge = smoothstep(0.0, 0.18, uv.y) * smoothstep(1.0, 0.82, uv.y);

    // The opacity slider drives a non-linear brightness gain (0..1 -> 0..~3), boosted at
    // the top end, so at maximum the sparkles stay bright and visible even over light
    // presets (e.g. June) where additive white barely lifts a light background.
    float op = pOpacity * (1.0 + 2.0 * pOpacity);
    float a = clamp(spark * edge * op, 0.0, 1.0);
    fragColor = vec4(vec3(a), a) * qt_Opacity;
}
