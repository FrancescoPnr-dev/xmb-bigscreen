#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Francesco Panarese
# SPDX-License-Identifier: GPL-3.0-only
# Bake the XMB wave shaders into .qsb for Qt6 ShaderEffect.
#
# Qt6 ShaderEffect cannot load a raw .vert/.frag — it needs baked .qsb. Re-run this after
# EVERY shader edit, otherwise your changes will NOT show. The baked .qsb files are
# committed and shipped (a Plasma plasmoid installs by copying files; no build step).
#
# Requires qsb from Qt6 (qtshadertools). On Arch it is /usr/lib/qt6/bin/qsb.
set -euo pipefail
cd "$(dirname "$0")"

QSB="${QSB:-$(command -v qsb || echo /usr/lib/qt6/bin/qsb)}"
if [ ! -x "$QSB" ]; then
    echo "error: qsb not found (set QSB=/path/to/qsb)" >&2
    exit 1
fi

TARGETS="--glsl 100es,120,150 --hlsl 50 --msl 12"

bake() {  # bake <source>
    echo "  $1 -> $1.qsb"
    "$QSB" $TARGETS -o "$1.qsb" "$1"
}

echo "Baking XMB shaders using $QSB"
bake xmbwave.vert        # wave mesh vertex displacement (spline.js waveProg vertex)
bake xmbwave.frag        # wave fresnel              (spline.js waveProg fragment)
bake xmbgradient.frag    # background gradient       (spline.js bgProg)
bake xmbparticles.frag   # additive sparkles
echo "OK"
