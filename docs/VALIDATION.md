# Validation

Validated on macOS with the installed SuperCollider **3.14.1**, on **2026-11-05**. No external Quarks or UGen plugins were loaded for these checks.

- All **81 SynthDefs** build and serialize; their **42 DSP families** instantiate in scsynth. Offline fixture renders produce finite audio/CV, with no CheckBadValues reports. Disabled external audio inputs are intentionally silent.
- The actual quantizer DSP was rendered at every integer EDO from **7 through 120**, with varying positive and negative octave CV. All **114 division settings** matched their expected quantized values within 0.000001 octave.
- Seven complete preset renders verified stereo downmix, headphone preview with **8/16/32** virtual speakers, a **16-channel physical-output configuration** rendered offline, **four-channel AmbiX**, and the **31 EDO** FM preset. Every output in the 16-channel render receives audio over a full orbit. The horizontal AmbiX Z channel is zero as expected. All samples are finite and the monitor's 0.94 limiter ceiling is respected.
- Engine checks verify compatible routing, replacing an input cable, source fan-out, rejecting mismatched widths, rejecting unbounded feedback, and accepting an explicit block-feedback boundary.
- JSON round-trip checks preserve module, cable, parameter, sequence, tuning and output settings. Invalid patch data leaves the current rack intact.
- Native Qt checks create the window, simulate a knob gesture and cable drag/disconnection, instantiate all 81 module panels, resize the window and capture the interface preview.
- Live CoreAudio checks boot the private server, run transport, switch presets, save/load patches, record a complete stereo WAV, and export a complete four-channel AmbiX WAV directly from the encoder using a two-output audio device. Recording file data and channel counts are checked after shutdown.
- Closing while the server boots is checked separately. The native oscilloscope is opened against the private server in a separate smoke check.

These checks verify code, routing, digital samples, files and the native interface. They do not establish perceptual equivalence to analog hardware or a real surround room. A physical 16/32-speaker installation, MIDI controllers, external microphone/instrument input, and Windows/Linux were not tested. No measured HRTF dataset or head tracker is included.

## Repeat the checks

On the tested Mac installation:

```sh
./tests/run.sh
```

The runner starts Qt windows and a muted live audio engine during its interface and recording checks. It writes temporary test WAVs to `tests/`, live test recordings to `recordings/`, and logs to `/tmp/microms-*.log`. The Python WAV checker uses only the standard library. The application itself does not require Python.

Additional focused lifecycle/interface checks:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D -l tests/runtime.yaml tests/boot-cancel.scd
/Applications/SuperCollider.app/Contents/MacOS/sclang -D -l tests/runtime.yaml tests/scope-smoke.scd
```

## Fifty-preset factory bank

The 50 added `.microms` files are validated with the production patch loader, then each is rendered for eight seconds using its saved tuning, sequence values, gate patterns, modulation, effects, spatial routing and output level. The grain sampler uses the same generated texture as the application. Tests check distinct patch contents and rendered audio, both stereo channels, finite samples, audible levels and the monitor limiter ceiling. No external samples, MIDI or live audio input are needed.

The native menu exposes all 50 factory entries alongside the original two presets and Empty rack. A GUI check loads the first and last entries. The loader converts dictionaries into new dictionaries during numeric conversion, preventing iteration from skipping fields as dictionaries resize.

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D -l tests/runtime.yaml tests/factory-bank.scd
python3 tests/check_factory_bank.py
/Applications/SuperCollider.app/Contents/MacOS/sclang -D -l tests/runtime.yaml tests/factory-menu.scd
```

Factory render files and their level report are written under `/tmp/microms-bank-renders/`; these checks leave the live audio server untouched.
