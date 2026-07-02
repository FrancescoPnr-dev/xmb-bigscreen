#!/bin/sh
# SPDX-FileCopyrightText: 2026 Francesco Panarese
# SPDX-License-Identifier: GPL-3.0-only
# Builds the .plasmoid for the KDE Store: metadata, contents and licences only.
set -e
cd "$(dirname "$0")/.."

ver=$(grep -o '"Version": *"[^"]*"' metadata.json | cut -d'"' -f4)
out="xmb-dashboard-$ver.plasmoid"
rm -f "$out"
zip -rq "$out" metadata.json contents/ LICENSES/
echo "$out"
