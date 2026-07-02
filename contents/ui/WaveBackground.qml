// SPDX-FileCopyrightText: 2025 Mart (https://github.com/linkev/PlayStation-3-XMB, MIT)
// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only AND MIT
//
// Native Qt6 port of linkev/PlayStation-3-XMB. Three ShaderEffect layers drawn in
// order: gradient, wave mesh, particles. The wave is displaced per-vertex on a
// GridMesh rather than per-pixel to keep the GPU cost down.
import QtQuick

Item {
    id: root

    property real time: 0
    property bool animating: true

    // colorMonth: 0 = Automatic (current month), 1..12 = forced month, 13 = Custom RGB.
    property int colorMonth: 0
    property real colorR: 37
    property real colorG: 89
    property real colorB: 179
    property real gradientTopMul: 0.09
    property real gradientBotMul: 0.62

    // PS3 XMB monthly presets: { angle deg, s: start RGB, e: end RGB }.
    readonly property var monthPresets: ({
        1:  { angle: 90.25,  s: [197, 197, 197], e: [201, 201, 201] },
        2:  { angle: 67,     s: [203, 158, 13],  e: [219, 214, 41] },
        3:  { angle: 106,    s: [142, 190, 40],  e: [104, 168, 22] },
        4:  { angle: 136.75, s: [216, 182, 182], e: [231, 66, 117] },
        5:  { angle: 1.5,    s: [19, 108, 19],   e: [24, 156, 24] },
        6:  { angle: 148.75, s: [198, 120, 238], e: [103, 77, 161] },
        7:  { angle: 26.5,   s: [0, 167, 146],   e: [10, 240, 239] },
        8:  { angle: 62.5,   s: [0, 0, 95],      e: [33, 217, 255] },
        9:  { angle: 148.5,  s: [146, 44, 155],  e: [217, 98, 236] },
        10: { angle: 128.5,  s: [227, 151, 15],  e: [224, 187, 2] },
        11: { angle: 90,     s: [115, 68, 20],   e: [154, 118, 47] },
        12: { angle: 170.5,  s: [236, 68, 45],   e: [214, 63, 43] }
    })

    // Refreshed hourly so Automatic mode stays correct if the app runs for days.
    property int _curMonth: (new Date()).getMonth() + 1
    Timer { interval: 3600000; running: true; repeat: true; onTriggered: root._curMonth = (new Date()).getMonth() + 1 }

    // Start/end colours plus direction and smoothstep range for the gradient shader.
    function _gradient() {
        if (root.colorMonth === 13) {
            var cr = root.colorR / 255, cg = root.colorG / 255, cb = root.colorB / 255
            return {
                start: Qt.vector4d(cr * root.gradientTopMul, cg * root.gradientTopMul, cb * root.gradientTopMul * 1.2, 1.0),
                end:   Qt.vector4d(cr * root.gradientBotMul, cg * root.gradientBotMul, cb * root.gradientBotMul, 1.0),
                dir:   Qt.vector4d(0, 1, 0, 0), tMin: 0.0, tSpan: 1.0
            }
        }
        var mm = (root.colorMonth === 0) ? root._curMonth : root.colorMonth
        var p = root.monthPresets[mm]
        var rad = p.angle * Math.PI / 180.0
        var dx = Math.cos(rad), dy = Math.sin(rad)
        var lo = Math.min(0, dx, dy, dx + dy)
        var hi = Math.max(0, dx, dy, dx + dy)
        return {
            start: Qt.vector4d(p.s[0] / 255, p.s[1] / 255, p.s[2] / 255, 1.0),
            end:   Qt.vector4d(p.e[0] / 255, p.e[1] / 255, p.e[2] / 255, 1.0),
            dir:   Qt.vector4d(dx, dy, 0, 0), tMin: lo, tSpan: Math.max(1e-6, hi - lo)
        }
    }
    readonly property var gradientSpec: _gradient()
    readonly property vector4d colorStart: gradientSpec.start
    readonly property vector4d colorEnd: gradientSpec.end
    readonly property vector4d gdir: gradientSpec.dir
    readonly property real tMin: gradientSpec.tMin
    readonly property real tSpan: gradientSpec.tSpan

    // Wave dynamics; defaults match the demo's spline settings.
    property real flowSpeed: 0.18
    property real timeStep: 1.0
    property real rePipelineBlend: 0.45
    property real bandAmplitude: 0.200
    property real bandSecondaryFreq: 7.0
    property real bandSecondaryAmp: 0.025
    property real tension: 0.12
    property real splineLength: 0.306001
    property real spacing: 407.658
    property real perturbation: 0.0998587
    property real perturbationScale: 0.07
    property real travelSpeed1: 0.25
    property real travelAmp1: 0.014
    property real travelSpeed2: 0.15
    property real travelAmp2: 0.008
    property real waveCosAmp: 0.09
    property real waveBias: -0.1
    property real waveHeightScale: 0.5
    property real waveSoftClip: 0.22
    property real damping: 0.0001
    property real ffdScale1X: 5.67726
    property real ffdScale2Z: 2.88782
    property real ffdYAmp: 0.05
    property real ffdZAmp: 0.06
    property real zDetailScale: 0.08

    property real fresnelPower: 4.0
    property real fresnelScale: 0.5
    property real waveOpacity: 0.7
    property real brightness: 0.98
    property int  rowCount: 200

    property bool particlesEnabled: true
    property real pFlowSpeed: 0.8
    property real pOpacity: 0.9
    property real pSizeBase: 1.0
    property real pSizeVar: 1.5
    property real pDensity: 1.0

    FrameAnimation {
        running: root.animating && root.visible
        onTriggered: root.time += frameTime
    }

    // Layer 1: background gradient.
    ShaderEffect {
        anchors.fill: parent
        blending: false
        fragmentShader: "shaders/xmbgradient.frag.qsb"
        property real tMin: root.tMin
        property real tSpan: root.tSpan
        property vector4d colorStart: root.colorStart
        property vector4d colorEnd: root.colorEnd
        property vector4d gdir: root.gdir
    }

    // Layer 2: the displaced wave mesh.
    ShaderEffect {
        anchors.fill: parent
        blending: true
        cullMode: ShaderEffect.NoCulling
        mesh: GridMesh { resolution: Qt.size(96, Math.max(8, root.rowCount)) }
        vertexShader: "shaders/xmbwave.vert.qsb"
        fragmentShader: "shaders/xmbwave.frag.qsb"

        // Render into a 4x MSAA layer so the fold edges aren't stair-stepped.
        layer.enabled: true
        layer.samples: 4
        layer.smooth: true

        property real time: root.time
        property real flowSpeed: root.flowSpeed
        property real timeStep: root.timeStep
        property real rePipelineBlend: root.rePipelineBlend
        property real bandAmplitude: root.bandAmplitude
        property real bandSecondaryFreq: root.bandSecondaryFreq
        property real bandSecondaryAmp: root.bandSecondaryAmp
        property real tension: root.tension
        property real splineLength: root.splineLength
        property real spacing: root.spacing
        property real perturbation: root.perturbation
        property real perturbationScale: root.perturbationScale
        property real travelSpeed1: root.travelSpeed1
        property real travelAmp1: root.travelAmp1
        property real travelSpeed2: root.travelSpeed2
        property real travelAmp2: root.travelAmp2
        property real waveCosAmp: root.waveCosAmp
        property real waveBias: root.waveBias
        property real waveHeightScale: root.waveHeightScale
        property real waveSoftClip: root.waveSoftClip
        property real damping: root.damping
        property real ffdScale1X: root.ffdScale1X
        property real ffdScale2Z: root.ffdScale2Z
        property real ffdYAmp: root.ffdYAmp
        property real ffdZAmp: root.ffdZAmp
        property real zDetailScale: root.zDetailScale
        property real fresnelPower: root.fresnelPower
        property real fresnelScale: root.fresnelScale
        property real waveOpacity: root.waveOpacity
        property real brightness: root.brightness
    }

    // Layer 3: additive sparkles.
    ShaderEffect {
        anchors.fill: parent
        visible: root.particlesEnabled
        blending: true
        fragmentShader: "shaders/xmbparticles.frag.qsb"
        property real time: root.time
        property real pFlowSpeed: root.pFlowSpeed
        property real pOpacity: root.pOpacity
        property real pSizeBase: root.pSizeBase
        property real pSizeVar: root.pSizeVar
        property real pDensity: root.pDensity
        // Wave centre-line params, shared so sparkles follow the veil.
        property real flowSpeed: root.flowSpeed
        property real timeStep: root.timeStep
        property real rePipelineBlend: root.rePipelineBlend
        property real bandAmplitude: root.bandAmplitude
        property real waveCosAmp: root.waveCosAmp
        property real waveBias: root.waveBias
        property real waveHeightScale: root.waveHeightScale
        property real waveSoftClip: root.waveSoftClip
        property real tension: root.tension
        property real splineLength: root.splineLength
        property real ffdScale1X: root.ffdScale1X
        property real ffdYAmp: root.ffdYAmp
    }
}
