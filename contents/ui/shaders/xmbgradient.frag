// SPDX-FileCopyrightText: 2025 Mart (https://github.com/linkev/PlayStation-3-XMB, MIT)
// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only AND MIT
//
// XMB background gradient — fragment shader (fullscreen ShaderEffect).
//
// 1:1 translation of linkev/PlayStation-3-XMB spline.js `bgProg` fragment: a smoothstep gradient along
// uDir between two colours over a [tMin, tMin+tSpan] range. Endpoints/dir/range are
// computed CPU-side in QML (resolveBackgroundGradient). One cheap pass, no loops.

#version 440

layout(location = 0) in vec2 qt_TexCoord0;   // y-down, == demo vUvYDown
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float tMin;
    float tSpan;
    vec4 colorStart;   // .rgb
    vec4 colorEnd;     // .rgb
    vec4 gdir;         // .xy
};

void main()
{
    float t = dot(qt_TexCoord0, gdir.xy);
    float u = clamp((t - tMin) / max(tSpan, 1e-6), 0.0, 1.0);
    float g = u * u * (3.0 - 2.0 * u);
    fragColor = vec4(mix(colorStart.rgb, colorEnd.rgb, g), 1.0) * qt_Opacity;
}
