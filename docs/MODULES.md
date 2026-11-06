# MicroMS-01 module guide

Ali Balighi © 2026 - Alibalighi.com

81 selectable module designs use 42 original digital DSP families. Variations share the family's engine; they are not replicas of product circuits, firmware, panel artwork, exact feature sets or proprietary algorithms. The rack uses varied panel widths, screw mounts, knob groups, faders and jack banks inspired by Eurorack hardware.

Reference catalogs: [Intellijel](https://intellijel.com/) and [Sweetwater Eurorack & Modular Synthesizers](https://www.sweetwater.com/shop/keyboards-synthesizers/eurorack-modular-synthesizers/). Specific panel references: [Metropolix](https://intellijel.com/shop/eurorack/metropolix/), [Quadrax](https://intellijel.com/shop/eurorack/quadrax/) and [Quad VCA](https://intellijel.com/shop/eurorack/quad-vca/). Hardware names identify design references and imply no affiliation.

The Sweetwater link is a category covering many manufacturers, not a fixed list of modules. This release covers synthesis, control, effects, mixing, utilities and interface functions; it does not reproduce every product sold there. The table gives the exact implemented scope.

| Module | Engine | Hardware reference / role | Digital behavior |
|---|---|---|---|
| AMPS / VCA | vca | Amps | Four VCAs and a summed output. Unpatched CV is normalized to one; patching CV replaces that normalization. |
| ATL / VOICE | voice | Atlantix / Cascadia | Complete dual-detuned oscillator, low-pass filter, envelope and VCA voice. |
| ATLX / OSC EXPANDER | vco | Atlx / Atlx 1U | Band-limited saw and pulse oscillator; sine, triangle and sub outputs. Pitch uses one octave per signal unit. |
| ATT / 1U | attenuverter | Att 1U | Bipolar attenuators with shared DC offset and sum. |
| AUDIO / INPUT | input | Audio I/O / MEMS Mic / Stomp / Line In / Stereo I/O / XY I/O | Audio interface input. Enable input channels in AUDIO SETUP before POWER. Channel numbers begin at zero. |
| AUX / MIX 1U | mixer | Aux Mix 1U | Four-channel mono sum and stereo spread mix. |
| BIF / FOLDER | folder | Bifold | Symmetric wavefolding with DC bias and wet/dry mix. |
| CASC / SYNTH VOICE | voice | Cascadia | Complete dual-detuned oscillator, low-pass filter, envelope and VCA voice. |
| CVX / MIDI 1U | midi | CVx 1U / uMIDI Jacks 1U / MIDI Jacks 1U | Connect all MIDI sources using MIDI CONNECT. Monophonic last-note priority, velocity, pitch bend, sustain and CC1. Channel zero means omni. |
| DIGI / REVERB 1U | reverb | Digiverb 1U | Stereo algorithmic room reverb using the stock FreeVerb network. |
| DIV / CLOCK | divider | Gx (clock utilities) | Resettable clock divider with four simultaneous outputs. |
| DIX / VCO | vco | Dixie II+ / VCO 1U | Band-limited saw and pulse oscillator; sine, triangle and sub outputs. Pitch uses one octave per signal unit. |
| DUAL / VCA 1U | vca | Dual VCA 1U | Four VCAs and a summed output. Unpatched CV is normalized to one; patching CV replaces that normalization. |
| DUATT / 1U | attenuverter | Duatt 1U | Bipolar attenuators with shared DC offset and sum. |
| EAR / BINAURAL | binaural |  | Analytic headphone rendering with interaural time differences and frequency-dependent head shadow. Approximates spatial cues; not a measured or personalized HRTF. |
| FEEDBACK / DELAY | feedback |  | Explicit one-block feedback boundary. Patch cycles must pass through this module. Return is DC-filtered, saturated and gain-limited. |
| FIELD / AMBI DECODE | ambidecode |  | Basic first-order horizontal ring decoder with yaw rotation. Z is not reproduced by horizontal rings; use the separate FOA output to preserve height. |
| FIELD / AMBI ENCODE | ambisonic |  | Encode speaker feeds into first-order AmbiX (ACN W,Y,Z,X; SN3D). Mono input can be positioned in 3D with azimuth CV and elevation. Ring encoding cannot reconstruct a unique original soundfield. |
| FLUR / RANDOM | noise | Flurry / Noise Tools 1U | White/pink noise, clocked sample and hold, and smoothed randomness. |
| FSR / TOUCH 1U | xy | FSR 1U | Drag the vector pad to control X/Y. Orbit blends in circular modulation; audio input is multiplied by X. |
| GRAIN / SAMPLER | sampler | Multigrain | Load an audio file using SAMPLE. Mono sample playback and stereo granular clouds. A generated texture is available before loading a file. |
| GX / GATE EXPANDER | gates | Gx | Four independent sixteen-step trigger patterns. Click cells to program each lane. |
| JELLY / MIX | mixer | Jellymix | Four-channel mono sum and stereo spread mix. |
| LOGIC / OR AND | logic | OR / Plog | Boolean logic for gates or thresholded CV. |
| MEMS / MIC IN | input | MEMS Mic / MEMS Mic 1U | Audio interface input. Enable input channels in AUDIO SETUP before POWER. Channel numbers begin at zero. |
| METRO / SEQ 8 | sequencer | Metropolix / Metropolix Solo | Eight editable pitch steps in EDO degrees. Drag the eight faders; right-click a step to toggle its gate. |
| METRO / SOLO | sequencer | Metropolix Solo | Eight editable pitch steps in EDO degrees. Drag the eight faders; right-click a step to toggle its gate. |
| MICRO / VCA | vca | uVCA | Four VCAs and a summed output. Unpatched CV is normalized to one; patching CV replaces that normalization. |
| MICRO / VCF | filter | uVCF | Resonant low-, band- and high-pass outputs with saturating drive. |
| MIDI / CV | midi | MIDI 1U / uMIDI / CVx | Connect all MIDI sources using MIDI CONNECT. Monophonic last-note priority, velocity, pitch bend, sustain and CC1. Channel zero means omni. |
| MIX / FOUR | mixer | Mixup / Unity Mixer / Stereo Mixer 1U / Aux Mix 1U / Jellymix | Four-channel mono sum and stereo spread mix. |
| MIXUP / SUM | mixer | Mixup | Four-channel mono sum and stereo spread mix. |
| MORPH / DUAL VCF | dualfilter | Morgasmatron | Independent resonant low/high filtering and a mixed output. |
| MULT / BUFFER | mult | Buff Mult / Mult / Switched Mult / USB Extender / Octalink | One signal duplicated to four outputs. Digital outputs may also fan out directly. |
| MULT / PASSIVE | mult | Mult / Mult 1U | One signal duplicated to four outputs. Digital outputs may also fan out directly. |
| MULTI / FX 1U | delay | Multi-FX 1U (delay mode) | Filtered stereo feedback delay. Changes to time produce tape-style pitch shifts. |
| MUTA / XFADE | crossfade | Mutamix | Equal-power crossfade between two sources. |
| NOISE / TOOLS 1U | noise | Noise Tools 1U | White/pink noise, clocked sample and hold, and smoothed randomness. |
| OCTA / LINK | mult | Octalink 1U / USB Extender | One signal duplicated to four outputs. Digital outputs may also fan out directly. |
| ORBIT / MULTICHANNEL | spatial |  | Constant-power horizontal speaker-ring panner for 4, 8, 16, 24 or 32 active channels. Angle zero is front, positive is left. Toolbar selects ring size. |
| OUTS / MONITOR | monitor | Outs / Headphones / Stereo Line Out / Line Out | Final limiter, metering and hardware output. Toolbar selects stereo, headphone, physical speaker or raw AmbiX output. A single output module is allowed per rack. |
| PASS / LPG | lpg | Passive LPG 1U | Triggered low-pass gate with linked amplitude and brightness decay. |
| PLAN / VECTOR | xy | Planar II / Tetrapad / Tete / FSR 1U | Drag the vector pad to control X/Y. Orbit blends in circular modulation; audio input is multiplied by X. |
| PLOG / LOGIC | logic | Plog | Boolean logic for gates or thresholded CV. |
| PLON / RESONATOR | pluck | Plonk | Karplus–Strong physical string with noise or external excitation. |
| POLAR / VCF | filter | Polaris / uVCF / SVF 1U | Resonant low-, band- and high-pass outputs with saturating drive. |
| PULSE / CLOCK | clock |  | Transport-synchronized master clock. STOP resets its phase. |
| QUAD / FUNCTION | functions | Quadrax / Qx | Four triggered attack/decay envelopes with optional cycling and end pulse. |
| QUAD / INVERTER | attenuverter | Quad Inverter | Bipolar attenuators with shared DC offset and sum. |
| QUAD / LFO | lfo | Quadrax (LFO functions) | Four phase-offset modulation signals with selectable waveform. |
| QUAD / VCA | vca | Quad VCA / Amps / uVCA / Dual VCA 1U | Four VCAs and a summed output. Unpatched CV is normalized to one; patching CV replaces that normalization. |
| QUADRATT / 1U | attenuverter | Quadratt 1U | Bipolar attenuators with shared DC offset and sum. |
| QX / END EXPANDER | functions | Qx | Four triggered attack/decay envelopes with optional cycling and end pulse. |
| RAIN / MULTITAP | delay | Rainmaker | Filtered stereo feedback delay. Changes to time produce tape-style pitch shifts. |
| RING / MULTIPLY | ringmod | Ringmod 1U | Four-quadrant multiplication / ring modulation. |
| RUB / THRU-ZERO FM | complex | Rubicon II | Two-operator phase modulation and wavefolding. Digital synthesis rather than a hardware firmware emulation. |
| S&H / SLEW | hold | Flurry (utilities) | Clocked sample and hold plus asymmetric continuous slew. |
| SCALES / EDO | quantizer | Scales | Quantize octave CV to every equal division from 7 through 120. A patched EDO CV changes the division count. The toolbar tuning updates this module. |
| SEA / DELAY | delay | Sealegs / Rainmaker / Multi-FX 1U | Filtered stereo feedback delay. Changes to time produce tape-style pitch shifts. |
| SHAPE / FM | complex | Shapeshifter / Rubicon II | Two-operator phase modulation and wavefolding. Digital synthesis rather than a hardware firmware emulation. |
| SHIFT / MEMORY | shifter | Shifty | Four-stage clocked analog shift register. |
| SPRING / COMB | spring | Springray II | Dispersive all-pass/comb reverb inspired by spring tanks. No physical tank interface is needed. |
| SQUASH / DYNAMICS | compressor | Jellysquasher | Compressor with optional external sidechain. |
| STEPP / 1U | gates | Steppy 1U | Four independent sixteen-step trigger patterns. Click cells to program each lane. |
| STEPP / GATE 4 | gates | Steppy / Steppy 1U / Gx | Four independent sixteen-step trigger patterns. Click cells to program each lane. |
| STEREO / DOWNMIX | stereofold |  | Equal-power stereo fold-down from the active virtual speaker ring. Preserves left/right distribution, not a full surrounding soundfield. |
| STEREO / I-O 1U | input | Stereo I/O 1U | Audio interface input. Enable input channels in AUDIO SETUP before POWER. Channel numbers begin at zero. |
| STEREO / LINE IN | input | Stereo Line In 1U / Line In 1U / XY I/O 1U | Audio interface input. Enable input channels in AUDIO SETUP before POWER. Channel numbers begin at zero. |
| STEREO / MIX 1U | mixer | Stereo Mixer 1U | Four-channel mono sum and stereo spread mix. |
| STOMP / I-O | input | Stomp / Pedal I/O 1U | Audio interface input. Enable input channels in AUDIO SETUP before POWER. Channel numbers begin at zero. |
| SVF / 1U | filter | SVF 1U | Resonant low-, band- and high-pass outputs with saturating drive. |
| SWELL / REVERB | reverb | Swells / Digiverb 1U | Stereo algorithmic room reverb using the stock FreeVerb network. |
| SWITCH / MULT | mult | Switched Mult 1U | One signal duplicated to four outputs. Digital outputs may also fan out directly. |
| TANG / DUAL ADSR | adsr | Tangrams | Two independent ADSR envelopes and an inverted output. |
| TETE / MOTION | xy | Tete | Drag the vector pad to control X/Y. Orbit blends in circular modulation; audio input is multiplied by X. |
| TETRA / TOUCH | xy | Tetrapad | Drag the vector pad to control X/Y. Orbit blends in circular modulation; audio input is multiplied by X. |
| TRI / ATTENUVERTER | attenuverter | Triplatt / Duatt / Quadratt / Att 1U / Quad Inverter | Bipolar attenuators with shared DC offset and sum. |
| UNITY / MIX | mixer | Unity Mixer | Four-channel mono sum and stereo spread mix. |
| VCO / 1U | vco | VCO 1U | Band-limited saw and pulse oscillator; sine, triangle and sub outputs. Pitch uses one octave per signal unit. |
| XFADE / MORPH | crossfade | Xfade 1U / Mutamix | Equal-power crossfade between two sources. |
| ZERO / SCOPE | scope | Zeroscope 1U | Live oscilloscope, peak meter and estimated frequency. Click SCOPE in the toolbar to view the selected signal. |

## Differences from hardware

- Digital variations such as AMPS, MICRO VCA and DUAL VCA use the four-channel VCA engine. All four channels are available. Mixers use a four-input sum and stereo-spread engine rather than reproducing each mixer's channel count or aux structure.
- METRO uses one eight-step pitch lane, gate enables and glide. STEPP offers four sixteen-step trigger lanes. They do not implement the original products' full sequence lengths, tracks, ratchets, probability, storage or expander protocols.
- GRAIN loads one file, downmixing by selecting its first channel, then provides playback and stereo granulation. It does not reproduce Multigrain's eight-sound scene system, live capture or firmware.
- SHAPE and RUB use phase modulation. PLON uses a plucked-string model. ATL and CASC are compact oscillator/filter/envelope/VCA voices. They are original synthesis engines.
- SWELL uses FreeVerb. SPRING uses a comb/all-pass network. RAIN adds six delay taps to SEA's stereo feedback delay. MULTI FX supplies the delay engine. These do not reproduce the products' full algorithms.
- TETRA, TETE and FSR use a mouse-controlled vector pad with automatic orbit. They do not record gestures, measure pressure or implement all hardware modes.
- QX uses the function generator's end pulse; GX uses the four gate lanes. Passive multis, switched multis, USB extension and Octalink references provide digital signal duplication, without physical hardware protocols.
- STOMP, MEMS and audio-input variations use the selected audio interface. They cannot provide physical impedance conversion, analog gain stages, microphone capsules, USB jacks or phantom power. MIDI variation modules share one MIDI-to-CV engine.
- Case sizes, power supplies, power entry, USB power, blank panels, physical connectors, cases, bags and accessories are represented by the virtual rack and its transport/interface controls. They are not signal-processing modules.
- Audio and modulation use 32-bit audio buses. Cable routing runs in dependency order; cycles require an explicit previous-block feedback boundary. Modules introduce the normal latency of their stock SuperCollider UGens.

See [SPATIAL-AUDIO.md](SPATIAL-AUDIO.md) for channel ordering, renderer behavior, export, normalization and limits.
