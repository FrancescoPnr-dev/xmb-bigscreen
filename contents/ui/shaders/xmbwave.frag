// SPDX-FileCopyrightText: 2025 Mart (https://github.com/linkev/PlayStation-3-XMB, MIT)
// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only AND MIT
//
// XMB wave — fragment shader (Qt6 ShaderEffect + GridMesh).
//
// 1:1 translation of linkev/PlayStation-3-XMB spline.js `waveProg` FRAGMENT shader: reconstruct the
// surface normal from the screen-space derivatives of the displaced position and take a
// fresnel term, so the translucent silver sheet lights up along its grazing folds. Output
// is premultiplied white * alpha (Qt composites premultiplied; equivalent to the demo's
// SRC_ALPHA / ONE_MINUS_SRC_ALPHA white-over-gradient blend).

#version 440

layout(location = 0) in vec3 vPos;
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
    float ffdScale2Z;
    float ffdYAmp;
    float ffdZAmp;
    float zDetailScale;
    float fresnelPower;
    float fresnelScale;
    float waveOpacity;
    float brightness;
};

void main()
{
    vec3 dx = dFdx(vPos);
    vec3 dy = dFdy(vPos);
    vec3 N = normalize(cross(dx, dy));
    float F = fresnelScale * pow(max(0.0, 1.0 + dot(vec3(0.0, 0.0, -1.0), N)), fresnelPower);
    float a = clamp(F * waveOpacity * brightness, 0.0, 1.0);
    // premultiplied white (demo: oColor = vec4(vec3(1.0), F*opacity*brightness), straight alpha)
    fragColor = vec4(vec3(a), a) * qt_Opacity;
}
