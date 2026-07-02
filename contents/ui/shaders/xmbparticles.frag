// SPDX-FileCopyrightText: 2025 Mart (https://github.com/linkev/PlayStation-3-XMB, MIT)
// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only AND MIT
//
// XMB particles — fragment shader (fullscreen ShaderEffect, additive).
//
// Additive twinkling sparkle field that FOLLOWS the wave veil instead of sitting in a
// fixed symmetric horizontal band. waveCenter() reproduces the wave's centre-line
// (the same displacement math as xmbwave.vert, evaluated at z=0, dominant terms), so the
// sparkle cloud hugs the curving veil and undulates in sync with the flow over time.
// Constant cost (fixed 3x3 hash neighbourhood per pixel), white, additive.

#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float pFlowSpeed;
    float pOpacity;
    float pSizeBase;
    float pSizeVar;
    float pDensity;
    // wave centre-line (dominant displacement terms, shared with the wave shader)
    float flowSpeed;
    float timeStep;
    float rePipelineBlend;
    float bandAmplitude;
    float waveCosAmp;
    float waveBias;
    float waveHeightScale;
    float waveSoftClip;
    float tension;
    float splineLength;
    float ffdScale1X;
    float ffdYAmp;
};

vec2 hash22(vec2 p)
{
    float n = dot(p, vec2(127.1, 311.7));
    return fract(sin(vec2(n, n + 1.0)) * 43758.5453123);
}

// Wave veil centre-line (clip-y) at width-coord ux. Mirrors xmbwave.vert screen-Y at
// z=0 using the visually dominant terms (primary band + ffd wobble + soft-clipped arch).
float waveCenter(float ux, float t)
{
    float flow = t * flowSpeed * timeStep;
    float sx = ux * 2.0 - 1.0;

    float h = sin(flow * 0.25 + ux * 6.2) * bandAmplitude * rePipelineBlend;
    h += sin(sx * ffdScale1X + t * flowSpeed) * ffdYAmp;

    float baseWave = cos(sx * 2.0 - t * 0.5 * timeStep) * waveCosAmp + waveBias;
    baseWave += tension * sin(sx * splineLength + t * flowSpeed * timeStep * 0.25);
    float totalWave = waveSoftClip * tanh((baseWave * waveHeightScale) / max(waveSoftClip, 1e-4));

    return h - totalWave;
}

void main()
{
    vec2 uv = qt_TexCoord0;
    float pt = time * pFlowSpeed;

    vec2 cells = vec2(46.0, 26.0) * clamp(pDensity, 0.05, 4.0);
    vec2 gp = uv * cells;
    float spark = 0.0;
    for (int oy = -1; oy <= 1; ++oy) {
        for (int ox = -1; ox <= 1; ++ox) {
            vec2 cell = floor(gp) + vec2(float(ox), float(oy));
            vec2 rnd = hash22(cell);
            vec2 pos = cell + vec2(fract(rnd.x + pt * (rnd.x - 0.5) * 0.15),
                                   rnd.y + 0.012 * sin(pt * (rnd.y + 1.5) + rnd.x * 100.0));
            float d = length((gp - pos) * vec2(1.0, cells.x / cells.y));
            float size = (pSizeBase + rnd.y * pSizeVar) * 0.012;
            float dot1 = smoothstep(size, 0.0, d);
            float tw = 0.5 + 0.5 * sin(pt * (1.0 + rnd.x * 2.0) + rnd.y * 6.2831);
            spark += dot1 * tw * tw;
        }
    }

    // Follow the veil: concentrate the cloud around the wave centre-line (which curves
    // along x and moves with the flow), not a fixed screen-centre band.
    float veilUv = 0.5 - 0.5 * waveCenter(uv.x, time);   // clip-y -> y-down uv
    float band = smoothstep(0.20, 0.0, abs(uv.y - veilUv));

    // The opacity slider drives a non-linear brightness gain (0..1 -> 0..~3), boosted at
    // the top end, so at maximum the sparkles stay bright and visible even over light
    // presets (e.g. June) where additive white barely lifts a light background.
    float op = pOpacity * (1.0 + 2.0 * pOpacity);
    float a = clamp(spark * band * op, 0.0, 1.0);
    fragColor = vec4(vec3(a), a) * qt_Opacity;
}
