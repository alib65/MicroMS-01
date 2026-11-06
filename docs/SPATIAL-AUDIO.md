# Spatial audio

MicroMS-01 uses ordinary stock SuperCollider audio buses, so spatial signals can be patched, transformed, exported, and monitored with no external spatialization plugins.

## Signal types and coordinates

| Jack | Bus width | Meaning |
|---|---:|---|
| Mono / CV / gate | 1 | Audio or octave-based control signal |
| Stereo | 2 | Left, right |
| Ring | 32 | Up to 32 speaker feeds; only the selected 4/8/16/24/32 are active |
| AmbiX | 4 | First-order ACN channel order **W, Y, Z, X**, **SN3D** normalization |

Zero azimuth faces front; positive angles move toward the listener's left. Speaker index `j` has azimuth `2πj/N`. The first hardware output is front. In software the bus index starts at zero; audio interfaces generally label that output “1”. This is a uniformly spaced horizontal ring, not an arbitrary speaker-layout/VBAP or 5.1/7.1 film channel mapping.

## ORBIT

A wraparound cosine window assigns gains to adjacent loudspeakers. The gain vector is divided by its Euclidean norm, so the sum of squared gains equals one. WIDTH increases the number of participating speakers; ROTATION is revolutions per second and may be negative. AZIMUTH CV is an audio-rate input scaled by CV DEPTH in degrees. SPEED CV adds to the rotation rate.

Ring channels above N are zero. Change the ring size in the toolbar. Physical output mode is available only when configured hardware outputs are at least N.

## AmbiX encoding

For a mono sample `s`, azimuth `a` and elevation `e`, FIELD writes:

```
W = s
Y = s × sin(a) × cos(e)
Z = s × sin(e)
X = s × cos(a) × cos(e)
```

Azimuth CV uses one signal unit per 180 degrees. The ROTATE knob adds a rotation. Ring encoding sums each active speaker feed using its horizontal direction, with Z equal to zero. Mono and ring inputs may be combined. Converting speaker feeds to Ambisonics is an encoding of those feeds as virtual sources; the original underlying soundfield cannot generally be recovered uniquely.

The basic horizontal decoder produces `(W + 2Y sin(a) + 2X cos(a)) / N` per speaker, with optional yaw. This is a first-order basic decoder, without max-rE/energy optimization or arbitrary 3D loudspeaker calibration. Z is retained in raw AmbiX exports but cannot be reproduced by this horizontal decoder.

SN3D W has unity gain. The stereo fold and headphone renderer include 0.5 output scaling to control correlated channel sums. The final hardware monitor applies level, DC removal and a 0.94 peak limiter. Selected-output recordings capture the signal before that monitor processing; turn module levels down when feeding external software expecting normalized floating-point audio.

## Headphones and stereo

EAR renders each speaker direction with up to 0.65 ms of interaural time difference, a frequency-dependent low-pass head shadow, far-ear attenuation and a small optional room response. Yaw rotates the listening direction. This analytic model is deliberately described as a preview: it contains no measured HRTF dataset, pinna/elevation filtering, individualized anatomy or sensor-based head tracking. Front/back and elevation localization are limited.

The monitor's headphone mode uses the same analytic direction model without EAR's optional room response. Its stereo mode uses left/right equal-power panning of virtual speakers. Neither is acoustically identical to real speakers. Use headphones for the headphone renderer; use loudspeakers for physical speaker mode.

## Routing and export examples

```
VCO → VCF → VCA → ORBIT → OUTS (RING)
                        ↘ FIELD ENCODE → FIELD DECODE → EAR → OUTS (STEREO)
```

To hear only the second chain, disconnect OUTS RING and AMBIX, then patch EAR to OUTS STEREO. If OUTS has both RING and AMBIX connected, the direct RING is used during normal listening. Raw AmbiX output uses only the AMBIX input.

For a DAW or external Ambisonic renderer, select FIELD ENCODE, choose REC: SELECTED OUT and record. Import the four channels as ACN/SN3D; they are not conventional quad loudspeaker feeds. For speaker-file exports, select ORBIT and record its first output. The file has N channels in the ring order above. Neither export requires N physical audio outputs.

For an actual installation, configure the audio interface's supported outputs in AUDIO SETUP while POWER is off. Speaker gain, delay alignment, room correction, arbitrary speaker placement and physical output reassignment are outside this release. Configure those in the interface or an external loudspeaker processor.

Reference: [SuperCollider multichannel expansion](https://docs.supercollider.online/Guides/Multichannel-Expansion.html), [PanAz](https://docs.supercollider.online/Classes/PanAz.html). MicroMS uses its own normalized ring gain calculation to allow the active speaker count to change without recompiling the graph.
