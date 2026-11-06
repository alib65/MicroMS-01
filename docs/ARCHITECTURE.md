# Architecture

The application consists entirely of `.scd` code running in SuperCollider's language interpreter and audio server. The Qt interface uses UserView/Pen for panel graphics, knobs, faders, jacks and Bézier cables. Native controls provide transport, dialogs, tuning and library selection.

`Catalog.scd` declares parameter ranges, typed ports, panel widths, descriptions and reference mappings. `DSP.scd` builds a SynthDef per catalog entry from 42 shared digital engines. `Engine.scd` owns module instances, private buses, patch connections, transport, JSON persistence, MIDI, server lifecycle, metering and recording. `Presets.scd` supplies playable patches. `Interface.scd` implements drawing and interaction.

Each output receives its own bus allocation. Every signal, including pitch, CV and gates, is audio-rate. Unpatched inputs read a reserved silent bus. Four-channel VCAs normalize an unpatched CV to one; a cable overrides that normalization. Types enforce matching channel widths for stereo, ring and AmbiX; all mono audio/CV/gate signals may be cross-patched.

The engine calculates a stable topological ordering after every cable change. Inputs receive source bus indices and nodes are reordered in one immediate OSC bundle. Feedback cycles are rejected unless they pass through FEEDBACK / DELAY; that module uses InFeedback to read a prior processing block and removes its incoming edge from the ordering dependency. Its gain is capped and its signal is DC-filtered and saturated. Sample-and-hold shifters use explicit one-sample boundaries between stages.

All real-time synthesis runs on a private server named microMS at localhost UDP 57131. The server has 8,192 audio buses, a 64-sample block and 256 MiB of real-time memory. Server output SynthDefs are compiled to the selected hardware output count. Device configuration can therefore change only while the engine is off. Closing/powering off the application synchronizes pending recording operations before quitting its own server.

Patches use JSON with no executable evaluation. Loading validates module types, parameter ranges, patterns, IDs, port compatibility, input fan-in and graph order before replacing the rack. SuperCollider 3.14 returns JSON numeric values as strings; the loader converts strict numeric literals explicitly. Patches store sample file paths rather than embedding files; move those files together with your patches. Missing samples fall back to the generated default texture. A maximum of 128 modules is accepted from a patch file. Hardware device choices are local to the running session and are not stored in a musical patch.

MIDI uses last-note priority per MIDI module, velocity, sustain, ±2-semitone bend and CC1. MIDI note pitch initially follows the source's 12-semitone numbering; route it through SCALES to quantize to the selected EDO. The MIDI channel selector accepts 1–16 or 0 for omni. The application registers and frees only its own named MIDI responders.

The top-level `~microMS` event exposes engine functions for use from the IDE. Examples:

```supercollider
~microMS[\edo] = 53;
~microMS[\syncGlobals].value;
~microMS[\add].value(\pluck);
~microMS[\save].value("~/Desktop/MyPatch.microms".standardizePath);
```
