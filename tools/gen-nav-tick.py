#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Francesco Panarese
# SPDX-License-Identifier: GPL-3.0-only
"""
Generator for the navigation click (contents/sounds/nav-tick.wav).

Development tool only: the plasmoid loads just the resulting .wav at runtime, so this
script is never imported or shipped when the widget is installed (Plasma packages only
metadata.json + contents/). Kept here so the sound stays reproducible and diff-able.

The click is deliberately dry and rapid with NO tonal/harmonic content: a short
band-limited noise snap that decays almost instantly (~1.2 ms). Original synthesis.

Requirements: python3 + numpy.

Regenerate (run from the repo root):
    python3 tools/gen-nav-tick.py
Then reinstall/reload:
    kpackagetool6 --type Plasma/Applet --upgrade .
    systemctl --user restart plasma-plasmashell.service
"""
import numpy as np, wave
sr=44100
def write_wav(path,data):
    data=np.clip(data,-1,1); pcm=np.int16(data*32767)
    ch=1 if pcm.ndim==1 else pcm.shape[1]
    with wave.open(path,"w") as w:
        w.setnchannels(ch); w.setsampwidth(2); w.setframerate(sr); w.writeframes(pcm.tobytes())
    print("wrote",path,pcm.shape)

# Navigation click: a dry, rapid click with NO tonal/harmonic content — just a short
# band-limited noise snap that decays almost instantly.
def click():
    dur=0.035; m=int(sr*dur); tt=np.arange(m)/sr
    g=np.random.default_rng(3)
    nb=g.standard_normal(m)
    nb=nb-np.convolve(nb,np.ones(40)/40,mode='same')   # highpass: kill low rumble
    nb=np.convolve(nb,np.ones(3)/3,mode='same')        # tame the harshest fizz
    env=np.exp(-tt/0.0012)                              # ~1.2 ms decay => very dry/snappy
    out=nb*env
    out/= (np.abs(out).max()+1e-9)
    out*=0.55
    out[-int(sr*0.004):]*=np.linspace(1,0,int(sr*0.004))
    return out
write_wav("contents/sounds/nav-tick.wav", click())
