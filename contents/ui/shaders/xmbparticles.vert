// SPDX-FileCopyrightText: 2025 Mart (https://github.com/linkev/PlayStation-3-XMB, MIT)
// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only AND MIT
//
// XMB particles — vertex shader (Qt6 ShaderEffect + GridMesh).
//
// Same per-vertex displacement as xmbwave.vert (field + ffd + soft-clipped arch), so the
// sparkle pass shares the wave's exact geometry: sparkles drawn in this mesh's uv space
// are glued to the veil by construction. Only the z-detail step is omitted (it feeds the
// wave's fresnel, which the sparkles don't use).

#version 440

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;

layout(location = 0) out vec2 vUv;

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

const float PI = 3.14159265359;

// Identical to xmbwave.vert field(): the displacement value of the demo's spline texture.
float field(float ux, float z, float flow)
{
    float rowPhase = flow * 0.25 + z * 1.7;
    float reCore = sin(rowPhase + ux * 6.2) * bandAmplitude
                 + cos(z * bandSecondaryFreq + ux * 4.8 + flow * 0.09) * bandSecondaryAmp;
    float legacy = sin((ux * PI * 1.3 + z * 0.8) - flow * travelSpeed1) * travelAmp1 * tension
                 + sin((ux * PI * 2.8 - z * 1.2) + flow * travelSpeed2) * travelAmp2
                 + perturbation * perturbationScale
                   * sin((ux * (4.0 + splineLength * 2.0) + z * 4.0 - flow * 0.6) * (spacing * 0.01));
    return reCore * rePipelineBlend + legacy * (1.0 - rePipelineBlend);
}

void main()
{
    vec2 uv = qt_MultiTexCoord0;
    float flow = time * flowSpeed * timeStep;

    vec3 p = vec3(uv.x * 2.0 - 1.0, 0.0, uv.y * 2.0 - 1.0);
    float ux = uv.x;
    float z  = p.z;

    // Widen the sparkle band: open the row fan around the veil centre-line by pSpread,
    // so the cloud floats around the ribbon while staying locked to its motion.
    float centreVal = field(ux, 0.0, flow);
    p.y = centreVal + (field(ux, z, flow) - centreVal) * pSpread;
    p.y += sin(p.x * ffdScale1X + time * flowSpeed) * ffdYAmp;

    float baseWave = cos(p.x * 2.0 - time * 0.5 * timeStep) * waveCosAmp + waveBias;
    baseWave *= (1.0 - damping);
    baseWave += tension * sin(p.x * splineLength + time * flowSpeed * timeStep * 0.25);
    float structured = perturbation * perturbationScale * (
          sin((p.x * splineLength * 6.0 + p.z * 0.5) * spacing * 0.01 + time * flowSpeed * timeStep * 0.7) * 0.5
        + sin((p.x * splineLength * 10.0 - p.z * 0.8) * spacing * 0.005 - time * flowSpeed * timeStep * 0.35) * 0.25);
    float totalWave = (baseWave + structured) * waveHeightScale;
    totalWave = waveSoftClip * tanh(totalWave / max(waveSoftClip, 1e-4));
    p.y -= totalWave;

    vUv = uv;
    gl_Position = vec4(p.x, p.y, 0.0, 1.0);
}
