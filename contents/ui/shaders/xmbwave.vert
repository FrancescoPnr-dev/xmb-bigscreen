// SPDX-FileCopyrightText: 2025 Mart (https://github.com/linkev/PlayStation-3-XMB, MIT)
// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only AND MIT
//
// XMB wave — vertex shader (Qt6 ShaderEffect + GridMesh).
//
// 1:1 translation of linkev/PlayStation-3-XMB spline.js `waveProg` VERTEX shader. The demo renders a
// 100x100 grid (GL_TRIANGLE_STRIP) whose screen-Y is the wave displacement; here the
// same grid is a Qt Quick GridMesh and this shader is the same per-vertex displacement.
// This is the GPU-efficient method: the wave is computed per VERTEX (~10k), not per
// screen pixel.
//
// The demo samples its displacement from a per-frame CPU-generated 256x64 R32F texture
// (spline-reverse.js writeDisplacementTexture: a sum of sine bands smoothed by a cubic
// B-spline). A per-frame float texture can't be uploaded from pure QML, so we evaluate
// the SAME field analytically in field() below — identical values (analytic eval is
// already smooth, so the B-spline reconstruction is unnecessary), no per-pixel cost. The
// negligible "reKernel" pseudo-random wander (gain 0.04 * blend 0.45 ≈ 1.8%) is omitted.

#version 440

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;

layout(location = 0) out vec3 vPos;   // displaced position -> fragment fresnel (demo vPos)

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
    float splineLength;     // demo 'length'
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
    float ffdScale2Z;
    float ffdYAmp;
    float ffdZAmp;
    float zDetailScale;
    float fresnelPower;
    float fresnelScale;
    float waveOpacity;
    float brightness;
};

const float PI = 3.14159265359;

// Displacement field == the value baked into the demo's spline texture at (ux, z).
// (spline-reverse.js writeDisplacementTexture control-point formula; cp blended reCore/legacy.)
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
    // GridMesh gives qt_MultiTexCoord0 in [0,1]^2. Demo: aPos in [-1,1]^2, uv=(aPos+1)/2.
    vec2 uv = qt_MultiTexCoord0;
    float flow = time * flowSpeed * timeStep;

    vec3 p = vec3(uv.x * 2.0 - 1.0, 0.0, uv.y * 2.0 - 1.0);   // p = (aPos.x, 0, aPos.y)
    float ux = uv.x;
    float z  = p.z;

    // p.y = texture(uSplineTex, uv).r
    p.y = field(ux, z, flow);

    // free-form deformation (spline.js): ffd1.x = p.x*ffdScale1X (+0), ffd2.z = p.z*ffdScale2Z (+0)
    p.y += sin(p.x * ffdScale1X + time * flowSpeed) * ffdYAmp;
    p.z += cos(p.z * ffdScale2Z + time * flowSpeed) * ffdZAmp;

    // soft-clipped overall sweep (the slow arch)
    float baseWave = cos(p.x * 2.0 - time * 0.5 * timeStep) * waveCosAmp + waveBias;
    baseWave *= (1.0 - damping);
    baseWave += tension * sin(p.x * splineLength + time * flowSpeed * timeStep * 0.25);
    float structured = perturbation * perturbationScale * (
          sin((p.x * splineLength * 6.0 + p.z * 0.5) * spacing * 0.01 + time * flowSpeed * timeStep * 0.7) * 0.5
        + sin((p.x * splineLength * 10.0 - p.z * 0.8) * spacing * 0.005 - time * flowSpeed * timeStep * 0.35) * 0.25);
    float totalWave = (baseWave + structured) * waveHeightScale;
    totalWave = waveSoftClip * tanh(totalWave / max(waveSoftClip, 1e-4));
    p.y -= totalWave;

    // depth detail (scrolling) — spline.js: p.z -= texture(uSplineTex, uv2).r * zDetailScale
    float uv2x = fract(uv.x - time * flowSpeed * 0.04 * timeStep);
    p.z -= field(uv2x, z, flow) * zDetailScale;

    vPos = p;
    // demo: gl_Position = vec4(p, 1.0) (clip space directly; screen-Y is the displacement)
    gl_Position = vec4(p.x, p.y, 0.0, 1.0);
}
