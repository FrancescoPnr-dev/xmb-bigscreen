#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Francesco Panarese
# SPDX-License-Identifier: GPL-3.0-only
"""
Generator for the dashboard's ambient background loop (contents/sounds/ambient-loop.wav).

This is a DEVELOPMENT tool only: the plasmoid loads just the resulting .wav at
runtime, so this script is never imported, executed, or shipped when the widget is
installed (Plasma packages only metadata.json + contents/). Keep it here so the sound
stays reproducible and diff-able.

Design notes
------------
All original synthesis (no third-party/Sony samples). The 26 s loop is seamless by
construction: pad partials are integer Hz (whole cycles over the loop), LFO periods
divide the loop length, transient events are placed circularly, and the reverb is a
circular convolution — so the wrap point matches within < 0.4 %.

Structure: ethereal low pad + two grave piano notes with a light wind between them ->
a lower, longer, quieter third note alone (pad ducked) -> a 7 s stronger-wind interlude
with warm low strings -> pad eases back in for the loop wrap.

Requirements: python3 + numpy.

Regenerate (run from the repo root):
    python3 tools/gen-ambient.py
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

L=26.0; n=int(sr*L); t=np.arange(n)/sr

# ---------- ethereal pad bed, weighted low (seamless: integer Hz, LFO periods divide L) ----------
# lower/darker register for an "aura eterea"; a soft 55 Hz sub anchors it.
voices=[(55,0.16,12,.5,.5),(110,0.22,12,.0,.5),(165,0.13,6,.3,.8),(220,0.15,12,.5,.0),
 (221,0.09,6,.1,.6),(277,0.11,4,.2,.7),(330,0.09,6,.7,.2),(331,0.06,3,.0,.5),
 (415,0.05,4,.4,.9),(440,0.05,12,.3,.8),(494,0.035,3,.5,.0),(659,0.02,3,.6,.2)]
def pad(side):
    s=np.zeros(n)
    for f,a,P,pl,pr in voices:
        ph=pl if side=='L' else pr; depth=0.5 if f<500 else 0.65
        s+=a*((1-depth)+depth*0.5*(1+np.cos(2*np.pi*t/P+2*np.pi*ph)))*np.sin(2*np.pi*f*t)
    return s*(0.82+0.18*np.cos(2*np.pi*t/26.0))     # slow breathing swell (period | L)
padL,padR=pad('L'),pad('R')

# The ethereal bed ducks out for the long low third note and the wind interlude, then
# eases back in before the loop wraps (gate is 1.0 at both t=0 and t=L, so the loop
# stays seamless).
fo0,fo1=11.0,12.2; fi0,fi1=24.0,26.0
padGate=np.ones(n)
mo=(t>=fo0)&(t<fo1); padGate[mo]=0.5+0.5*np.cos(np.pi*(t[mo]-fo0)/(fo1-fo0))
padGate[(t>=fo1)&(t<fi0)]=0.0
mi=(t>=fi0); padGate[mi]=0.5-0.5*np.cos(np.pi*np.clip((t[mi]-fi0)/(fi1-fi0),0,1))
padL*=padGate; padR*=padGate

# ---------- soft EP/music-box "piano" keys, longer and more spacious ----------
def key(freq,dur=3.6,amp=1.0,sustain=0.95):
    m=int(sr*dur); tt=np.arange(m)/sr
    B=0.0007; parts=[(1,1.0,1.0),(2,0.55,1.35),(3,0.30,1.8),(4,0.16,2.4),(5,0.09,3.2),(6.01,0.06,3.6)]
    dec=1.0/sustain                                 # larger sustain => held longer
    s=np.zeros(m)
    for k,a,dm in parts:
        s+=a*np.exp(-tt*dec*dm)*np.sin(2*np.pi*freq*k*np.sqrt(1+B*k*k)*tt)
    s*= (1-np.exp(-tt/0.0025))                       # soft pluck attack
    return amp*s

# Two grave notes: E3 -> C#3, far apart, with a long silence between them filled by
# a light breath of wind.
notes=[(2.0,165,.9),(9.0,139,.95)]
keysL=np.zeros(n); keysR=np.zeros(n)
for ts,f,a in notes:
    s=key(f,amp=a)
    st=int(ts*sr); idx=(st+np.arange(len(s)))%n      # circular wrap => seamless
    panR=0.5+0.35*((f%200)/200-0.5)
    np.add.at(keysL, idx, s*(1-panR)*1.5); np.add.at(keysR, idx, s*panR*1.5)

# ---------- third note: lower, quieter, held far longer, alone (pad/wind ducked) ----------
low=key(110,dur=7.4,amp=1.0,sustain=2.6)             # A2, slow long release
st=int(12.5*sr); idx=(st+np.arange(len(low)))%n
np.add.at(keysL, idx, low*0.85); np.add.at(keysR, idx, low*0.85)  # lower volume

# ---------- light breath of wind between the two notes ----------
# airy band-limited noise, a single soft gust centred in the gap, panning slowly.
g=np.random.default_rng(41)
raw=g.standard_normal(n)
lp=np.convolve(raw,np.ones(70)/70,mode='same')
air=lp-np.convolve(lp,np.ones(500)/500,mode='same')  # airy mid band
air/= (air.std()+1e-9)
tc=5.5; width=1.9
gust=np.exp(-((t-tc)/width)**2)*(0.75+0.25*np.sin(2*np.pi*t/3.0))  # period 3 | L => seamless
windA=0.07*air*gust
panL=0.5+0.25*np.cos(2*np.pi*t/6.0)                  # slow stereo drift, period 6 | L
windL=windA*panL; windR=windA*(1-panL)

# ---------- interlude (~7 s) after the third note: stronger wind + light strings ----------
# Fills 17.8 .. 24.8, then fades as the pad returns; all zero at the loop wrap.
g2=np.random.default_rng(97)
raw2=g2.standard_normal(n)
lp2=np.convolve(raw2,np.ones(55)/55,mode='same')
air2=lp2-np.convolve(lp2,np.ones(400)/400,mode='same')
air2/= (air2.std()+1e-9)
ia,ib=17.8,24.8                                       # 7-second wind bed
seg=(t>=ia)&(t<=ib)
w2env=np.zeros(n); w2env[seg]=0.5-0.5*np.cos(2*np.pi*(t[seg]-ia)/(ib-ia))  # 0 at both ends
wind2A=0.16*air2*w2env                                # louder than the mid gust
pan2=0.5+0.3*np.cos(2*np.pi*(t-ia)/2.5)
wind2L=wind2A*pan2; wind2R=wind2A*(1-pan2)

# Light harmonious strings over the wind: a warm low-mid bowed chord (A2-E3-A3-C#4),
# gentle ensemble detune + vibrato, swelling in and out with the same wind window.
# Deliberately low (no acute harmonics) so it accompanies rather than cuts through.
strL=np.zeros(n); strR=np.zeros(n)
chord=[110,165,220,277]                               # A2, E3, A3, C#4 — warm register
for i,f in enumerate(chord):
    vib=1+0.004*np.sin(2*np.pi*(4.8+0.3*i)*t+i)        # gentle bow vibrato
    s=np.zeros(n)
    for det in (0.997,1.003):                          # two-layer ensemble detune
        ph=2*np.pi*np.cumsum(f*det*vib)/sr
        for k in range(1,8):
            s+=(1.0/k**1.4)*np.sin(k*ph)               # steep rolloff => soft, not acute
    s/=(np.abs(s).max()+1e-9)
    pan=0.5+0.28*np.sin(i*1.3)                          # spread the voices
    strL+=s*(1-pan); strR+=s*pan
sm=max(np.abs(strL).max(),np.abs(strR).max())+1e-9
strL=0.26*w2env*strL/sm; strR=0.26*w2env*strR/sm       # swell with the wind window

# ---------- mix bed + keys, then seamless reverb via circular convolution ----------
def ir(decay,seed):
    m=int(sr*decay); g=np.random.default_rng(seed)
    h=g.standard_normal(m)*np.exp(-np.linspace(0,1,m)*3.4)
    h=np.convolve(h,np.ones(90)/90,mode='same'); return h/np.sqrt((h**2).sum())
def creverb(x,h): return np.fft.irfft(np.fft.rfft(x,n)*np.fft.rfft(h,n),n)
dryL=0.6*padL+keysL+windL+wind2L+strL; dryR=0.6*padR+keysR+windR+wind2R+strR
wetL=creverb(dryL,ir(2.6,11)); wetR=creverb(dryR,ir(2.7,23))    # longer, more heavenly tail
def m(d,w): w=w/(np.abs(w).max()+1e-9)*np.abs(d).max(); return 0.58*d+0.66*w
Lc,Rc=m(dryL,wetL),m(dryR,wetR)
pk=max(np.abs(Lc).max(),np.abs(Rc).max()); Lc*=0.34/pk; Rc*=0.34/pk
write_wav("contents/sounds/ambient-loop.wav", np.stack([Lc,Rc],1))
