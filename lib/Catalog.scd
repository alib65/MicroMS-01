{
    |a|
    var add, param, port, alias;
    param = { |key, label, min=0, max=1, val=0.5, warp=\lin, unit="", choices=nil|
        (key:key, label:label, min:min, max:max, default:val, warp:warp, unit:unit, choices:choices)
    };
    port = { |key, label, type=\mono| (key:key, label:label, type:type, channels:(mono:1, cv:1, gate:1, stereo:2, ring:32, ambi:4)[type]) };
    add = { |id, name, family, category, width, params, ins, outs, desc, reference=""|
        a[\catalog][id] = (id:id, name:name, family:family, category:category, width:width,
            params:params, inputs:ins, outputs:outs, description:desc, reference:reference)
    };
    alias = { |id, name, source, reference, desc|
        var spec = a[\catalog][source].copy;
        spec[\id]=id; spec[\name]=name; spec[\reference]=reference;
        if(desc.notNil) { spec[\description]=desc };
        a[\catalog][id]=spec;
    };
    add.value(\vco, "DIX / VCO", \vco, \source, 174,
        [param.value(\octave,"OCTAVE",-3,4,0,\step),param.value(\fine,"FINE",-100,100,0,\lin,"ct"),param.value(\width,"PULSE",0.05,0.95,0.5),param.value(\fm,"FM DEPTH",0,8,0)],
        [port.value(\pitch,"1V/OCT",\cv),port.value(\fm,"FM"),port.value(\pwm,"PWM",\cv)],
        [port.value(\sine,"SINE"),port.value(\tri,"TRI"),port.value(\saw,"SAW"),port.value(\pulse,"PULSE"),port.value(\sub,"SUB")],
        "Band-limited saw and pulse oscillator; sine, triangle and sub outputs. Pitch uses one octave per signal unit.","Dixie II+ / VCO 1U");
    add.value(\complex,"SHAPE / FM",\complex,\source,208,
        [param.value(\octave,"OCTAVE",-3,4,0,\step),param.value(\ratio,"RATIO",0.125,16,2,\exp),param.value(\index,"INDEX",0,16,1.2),param.value(\shape,"FOLD",1,8,1)],
        [port.value(\pitch,"1V/OCT",\cv),port.value(\fm,"FM"),port.value(\mod,"INDEX CV",\cv)],
        [port.value(\out,"OUT"),port.value(\mod,"MOD"),port.value(\sub,"SUB")],"Two-operator phase modulation and wavefolding. Digital synthesis rather than a hardware firmware emulation.","Shapeshifter / Rubicon II");
    add.value(\pluck,"PLON / RESONATOR",\pluck,\source,208,
        [param.value(\decay,"DECAY",0.05,12,3,\exp,"s"),param.value(\damp,"DAMP",0,1,0.35),param.value(\excite,"EXCITE",0,1,0.5),param.value(\octave,"OCTAVE",-2,3,0,\step)],
        [port.value(\pitch,"1V/OCT",\cv),port.value(\gate,"TRIG",\gate),port.value(\in,"EXTERNAL")],
        [port.value(\out,"OUT")],"Karplus–Strong physical string with noise or external excitation.","Plonk");
    add.value(\noise,"FLUR / RANDOM",\noise,\source,174,
        [param.value(\rate,"RATE",0.02,40,3,\exp,"Hz"),param.value(\slew,"SLEW",0.001,4,0.1,\exp,"s")],
        [port.value(\clock,"CLOCK",\gate)],
        [port.value(\white,"WHITE"),port.value(\pink,"PINK"),port.value(\hold,"S&H",\cv),port.value(\smooth,"SMOOTH",\cv),port.value(\clock,"CLOCK",\gate)],"White/pink noise, clocked sample and hold, and smoothed randomness.","Flurry / Noise Tools 1U");
    add.value(\sampler,"GRAIN / SAMPLER",\sampler,\source,242,
        [param.value(\rate,"SPEED",-2,2,1),param.value(\position,"POSITION",0,1,0.35),param.value(\density,"DENSITY",1,80,18,\exp,"Hz"),param.value(\size,"GRAIN",0.01,1,0.12,\exp,"s"),param.value(\mix,"GRANULAR",0,1,1)],
        [port.value(\pitch,"1V/OCT",\cv),port.value(\pos,"POS CV",\cv),port.value(\gate,"TRIG",\gate)],
        [port.value(\out,"OUT"),port.value(\stereo,"STEREO",\stereo)],"Load an audio file using SAMPLE. Mono sample playback and stereo granular clouds. A generated texture is available before loading a file.","Multigrain");
    add.value(\voice,"ATL / VOICE",\voice,\source,276,
        [param.value(\octave,"OCTAVE",-3,3,0,\step),param.value(\cutoff,"CUTOFF",40,16000,1800,\exp,"Hz"),param.value(\res,"RESONANCE",0,0.95,0.25),param.value(\attack,"ATTACK",0.001,2,0.01,\exp,"s"),param.value(\release,"RELEASE",0.02,8,0.4,\exp,"s"),param.value(\env,"ENV AMT",0,6,2)],
        [port.value(\pitch,"1V/OCT",\cv),port.value(\gate,"GATE",\gate),port.value(\fm,"CUTOFF CV",\cv)],
        [port.value(\out,"OUT"),port.value(\osc,"RAW OSC")],"Complete dual-detuned oscillator, low-pass filter, envelope and VCA voice.","Atlantix / Cascadia");
    add.value(\clock,"PULSE / CLOCK",\clock,\control,174,
        [param.value(\bpm,"TEMPO",20,300,108,\lin,"BPM"),param.value(\division,"MULTIPLY",1,16,4,\step),param.value(\width,"GATE",0.05,0.95,0.45)],
        [port.value(\rate,"RATE CV",\cv)], [port.value(\clock,"CLOCK",\gate),port.value(\slow,"BEAT",\gate),port.value(\reset,"RESET",\gate)],"Transport-synchronized master clock. STOP resets its phase.");
    add.value(\sequencer,"METRO / SEQ 8",\sequencer,\control,310,
        [param.value(\swing,"GLIDE",0,0.5,0),param.value(\length,"LENGTH",1,8,8,\step)],
        [port.value(\clock,"CLOCK",\gate),port.value(\reset,"RESET",\gate)],
        [port.value(\pitch,"PITCH",\cv),port.value(\gate,"GATE",\gate),port.value(\step,"STEP",\cv)],"Eight editable pitch steps in EDO degrees. Drag the eight faders; right-click a step to toggle its gate.","Metropolix / Metropolix Solo");
    add.value(\gates,"STEPP / GATE 4",\gates,\control,242,
        [param.value(\length,"LENGTH",1,16,16,\step)],
        [port.value(\clock,"CLOCK",\gate),port.value(\reset,"RESET",\gate)],
        (1..4).collect { |n| port.value(("g"++n).asSymbol,"GATE "++n,\gate) },
        "Four independent sixteen-step trigger patterns. Click cells to program each lane.","Steppy / Steppy 1U / Gx");
    add.value(\quantizer,"SCALES / EDO",\quantizer,\control,208,
        [param.value(\edo,"DIVISIONS",7,120,19,\step,"EDO"),param.value(\transpose,"TRANSPOSE",-120,120,0,\step,"deg"),param.value(\amount,"EDO CV",0,113,0)],
        [port.value(\pitch,"PITCH IN",\cv),port.value(\mod,"EDO CV",\cv)],
        [port.value(\out,"QUANT",\cv),port.value(\change,"CHANGE",\gate)],"Quantize octave CV to every equal division from 7 through 120. A patched EDO CV changes the division count. The toolbar tuning updates this module.","Scales");
    add.value(\shifter,"SHIFT / MEMORY",\shifter,\control,174,
        [param.value(\slew,"GLIDE",0,1,0)],
        [port.value(\in,"CV IN",\cv),port.value(\gate,"CLOCK",\gate)],
        (1..4).collect { |n| port.value(("v"++n).asSymbol,"CV "++n,\cv) },"Four-stage clocked analog shift register.","Shifty");
    add.value(\lfo,"QUAD / LFO",\lfo,\modulation,208,
        [param.value(\rate,"RATE",0.005,40,0.12,\exp,"Hz"),param.value(\shape,"SHAPE",0,3,0,\step,"",["SINE","TRI","SAW","SQUARE"]),param.value(\depth,"DEPTH",0,1,0.7),param.value(\offset,"OFFSET",-1,1,0)],
        [port.value(\rate,"RATE CV",\cv)],
        (1..4).collect { |n| port.value(("v"++n).asSymbol,"LFO "++n,\cv) },"Four phase-offset modulation signals with selectable waveform.","Quadrax (LFO functions)");
    add.value(\functions,"QUAD / FUNCTION",\functions,\modulation,208,
        [param.value(\attack,"RISE",0.001,8,0.02,\exp,"s"),param.value(\decay,"FALL",0.005,12,0.3,\exp,"s"),param.value(\curve,"CURVE",-8,8,-4),param.value(\cycle,"CYCLE",0,1,0,\step,"",["OFF","ON"])],
        (1..4).collect { |n| port.value(("g"++n).asSymbol,"TRIG "++n,\gate) },
        (1..4).collect { |n| port.value(("v"++n).asSymbol,"ENV "++n,\cv) } ++ [port.value(\end,"END",\gate)],"Four triggered attack/decay envelopes with optional cycling and end pulse.","Quadrax / Qx");
    add.value(\adsr,"TANG / DUAL ADSR",\adsr,\modulation,208,
        [param.value(\attack,"ATTACK",0.001,8,0.015,\exp,"s"),param.value(\decay,"DECAY",0.005,8,0.22,\exp,"s"),param.value(\sustain,"SUSTAIN",0,1,0.6),param.value(\release,"RELEASE",0.005,12,0.5,\exp,"s")],
        [port.value(\g1,"GATE 1",\gate),port.value(\g2,"GATE 2",\gate)],
        [port.value(\v1,"ENV 1",\cv),port.value(\v2,"ENV 2",\cv),port.value(\inv,"INVERT",\cv)],"Two independent ADSR envelopes and an inverted output.","Tangrams");
    add.value(\xy,"PLAN / VECTOR",\xy,\modulation,208,
        [param.value(\x,"X",-1,1,0),param.value(\y,"Y",-1,1,0),param.value(\auto,"ORBIT",0,1,0),param.value(\rate,"RATE",0.005,5,0.1,\exp,"Hz")],
        [port.value(\in,"IN")],
        [port.value(\x,"X",\cv),port.value(\y,"Y",\cv),port.value(\mix,"VECTOR MIX")],"Drag the vector pad to control X/Y. Orbit blends in circular modulation; audio input is multiplied by X.","Planar II / Tetrapad / Tete / FSR 1U");
    add.value(\hold,"S&H / SLEW",\hold,\modulation,174,
        [param.value(\rise,"RISE",0.001,6,0.05,\exp,"s"),param.value(\fall,"FALL",0.001,6,0.1,\exp,"s")],
        [port.value(\in,"IN",\cv),port.value(\gate,"TRIG",\gate)],
        [port.value(\hold,"HOLD",\cv),port.value(\slew,"SLEW",\cv)],"Clocked sample and hold plus asymmetric continuous slew.","Flurry (utilities)");
    add.value(\filter,"POLAR / VCF",\filter,\filter,208,
        [param.value(\cutoff,"CUTOFF",20,19000,1600,\exp,"Hz"),param.value(\res,"RESONANCE",0,0.98,0.25),param.value(\drive,"DRIVE",1,8,1,\exp),param.value(\fm,"FM DEPTH",-5,5,2)],
        [port.value(\in,"IN"),port.value(\cv,"CUTOFF CV",\cv)],
        [port.value(\low,"LOW"),port.value(\band,"BAND"),port.value(\high,"HIGH")],"Resonant low-, band- and high-pass outputs with saturating drive.","Polaris / uVCF / SVF 1U");
    add.value(\dualfilter,"MORPH / DUAL VCF",\dualfilter,\filter,242,
        [param.value(\cutoff,"CUTOFF A",20,18000,1500,\exp,"Hz"),param.value(\cutoffB,"CUTOFF B",20,18000,3400,\exp,"Hz"),param.value(\res,"RESONANCE",0,0.98,0.45),param.value(\fm,"CV AMT",-5,5,2)],
        [port.value(\in,"IN A"),port.value(\inB,"IN B"),port.value(\cv,"CV",\cv)],
        [port.value(\a,"LOW A"),port.value(\b,"HIGH B"),port.value(\mix,"MIX")],"Independent resonant low/high filtering and a mixed output.","Morgasmatron");
    add.value(\lpg,"PASS / LPG",\lpg,\filter,174,
        [param.value(\decay,"DECAY",0.01,3,0.2,\exp,"s"),param.value(\tone,"TONE",80,16000,8000,\exp,"Hz")],
        [port.value(\in,"IN"),port.value(\gate,"TRIG",\gate)],
        [port.value(\out,"OUT")],"Triggered low-pass gate with linked amplitude and brightness decay.","Passive LPG 1U");
    add.value(\vca,"QUAD / VCA",\vca,\mixing,242,
        (1..4).collect { |n| param.value(("gain"++n).asSymbol,"LEVEL "++n,0,1,0.65) },
        (1..4).collect { |n| port.value(("in"++n).asSymbol,"IN "++n) } ++ (1..4).collect { |n| port.value(("cv"++n).asSymbol,"CV "++n,\cv) },
        (1..4).collect { |n| port.value(("v"++n).asSymbol,"OUT "++n) } ++ [port.value(\mix,"MIX")],"Four VCAs and a summed output. Unpatched CV is normalized to one; patching CV replaces that normalization.","Quad VCA / Amps / uVCA / Dual VCA 1U");
    add.value(\mixer,"MIX / FOUR",\mixer,\mixing,208,
        (1..4).collect { |n| param.value(("gain"++n).asSymbol,"LEVEL "++n,0,1,0.5) },
        (1..4).collect { |n| port.value(("in"++n).asSymbol,"IN "++n) },
        [port.value(\out,"MIX"),port.value(\stereo,"STEREO",\stereo)],"Four-channel mono sum and stereo spread mix.","Mixup / Unity Mixer / Stereo Mixer 1U / Aux Mix 1U / Jellymix");
    add.value(\attenuverter,"TRI / ATTENUVERTER",\attenuverter,\utility,208,
        (1..3).collect { |n| param.value(("gain"++n).asSymbol,"GAIN "++n,-1,1,1) } ++ [param.value(\offset,"OFFSET",-2,2,0)],
        (1..3).collect { |n| port.value(("in"++n).asSymbol,"IN "++n,\cv) },
        (1..3).collect { |n| port.value(("v"++n).asSymbol,"OUT "++n,\cv) } ++ [port.value(\mix,"SUM",\cv)],"Bipolar attenuators with shared DC offset and sum.","Triplatt / Duatt / Quadratt / Att 1U / Quad Inverter");
    add.value(\mult,"MULT / BUFFER",\mult,\utility,140,[],[port.value(\in,"IN",\cv)],
        (1..4).collect { |n| port.value(("v"++n).asSymbol,"OUT "++n,\cv) },"One signal duplicated to four outputs. Digital outputs may also fan out directly.","Buff Mult / Mult / Switched Mult / USB Extender / Octalink");
    add.value(\logic,"LOGIC / OR AND",\logic,\utility,174,[param.value(\threshold,"THRESHOLD",-1,1,0.1)],
        [port.value(\a,"A",\gate),port.value(\b,"B",\gate)],
        [port.value(\or,"OR",\gate),port.value(\and,"AND",\gate),port.value(\xor,"XOR",\gate),port.value(\not,"NOT A",\gate)],"Boolean logic for gates or thresholded CV.","OR / Plog");
    add.value(\divider,"DIV / CLOCK",\divider,\utility,174,[],[port.value(\clock,"CLOCK",\gate),port.value(\reset,"RESET",\gate)],
        [2,4,8,16].collect { |n| port.value(("d"++n).asSymbol,"/"++n,\gate) },"Resettable clock divider with four simultaneous outputs.","Gx (clock utilities)");
    add.value(\ringmod,"RING / MULTIPLY",\ringmod,\effect,174,[param.value(\gain,"GAIN",0,4,1)],
        [port.value(\a,"CARRIER"),port.value(\b,"MODULATOR")],[port.value(\out,"OUT")],"Four-quadrant multiplication / ring modulation.","Ringmod 1U");
    add.value(\crossfade,"XFADE / MORPH",\crossfade,\mixing,174,[param.value(\mix,"CROSSFADE",0,1,0.5)],
        [port.value(\a,"A"),port.value(\b,"B"),port.value(\cv,"FADE CV",\cv)],[port.value(\out,"OUT")],"Equal-power crossfade between two sources.","Xfade 1U / Mutamix");
    add.value(\folder,"BIF / FOLDER",\folder,\effect,174,
        [param.value(\drive,"FOLD",1,12,2,\exp),param.value(\bias,"BIAS",-1,1,0),param.value(\mix,"MIX",0,1,1)],
        [port.value(\in,"IN"),port.value(\cv,"FOLD CV",\cv)],[port.value(\out,"OUT")],"Symmetric wavefolding with DC bias and wet/dry mix.","Bifold");
    add.value(\delay,"SEA / DELAY",\delay,\effect,208,
        [param.value(\time,"TIME",0.005,4,0.375,\exp,"s"),param.value(\feedback,"FEEDBACK",0,0.94,0.4),param.value(\tone,"TONE",200,18000,6500,\exp,"Hz"),param.value(\mix,"MIX",0,1,0.35)],
        [port.value(\in,"IN"),port.value(\cv,"TIME CV",\cv)],
        [port.value(\out,"OUT"),port.value(\stereo,"STEREO",\stereo)],"Filtered stereo feedback delay. Changes to time produce tape-style pitch shifts.","Sealegs / Rainmaker / Multi-FX 1U");
    add.value(\reverb,"SWELL / REVERB",\reverb,\effect,208,
        [param.value(\room,"ROOM",0,1,0.85),param.value(\damp,"DAMP",0,1,0.4),param.value(\mix,"MIX",0,1,0.4)],
        [port.value(\in,"IN")],[port.value(\out,"OUT"),port.value(\stereo,"STEREO",\stereo)],"Stereo algorithmic room reverb using the stock FreeVerb network.","Swells / Digiverb 1U");
    add.value(\spring,"SPRING / COMB",\spring,\effect,174,
        [param.value(\decay,"DECAY",0.1,8,2,\exp,"s"),param.value(\tone,"TONE",200,12000,4000,\exp,"Hz"),param.value(\mix,"MIX",0,1,0.35)],
        [port.value(\in,"IN")],[port.value(\out,"OUT")],"Dispersive all-pass/comb reverb inspired by spring tanks. No physical tank interface is needed.","Springray II");
    add.value(\compressor,"SQUASH / DYNAMICS",\compressor,\effect,208,
        [param.value(\threshold,"THRESHOLD",0.01,1,0.3,\exp),param.value(\ratio,"RATIO",1,20,4),param.value(\attack,"ATTACK",0.001,0.2,0.01,\exp,"s"),param.value(\release,"RELEASE",0.02,2,0.15,\exp,"s")],
        [port.value(\in,"IN"),port.value(\side,"SIDECHAIN")],[port.value(\out,"OUT")],"Compressor with optional external sidechain.","Jellysquasher");
    add.value(\feedback,"FEEDBACK / DELAY",\feedback,\utility,174,
        [param.value(\gain,"RETURN",0,0.94,0.3),param.value(\time,"DELAY",0,1,0)],
        [port.value(\in,"RETURN")],[port.value(\out,"OUT")],"Explicit one-block feedback boundary. Patch cycles must pass through this module. Return is DC-filtered, saturated and gain-limited.");
    add.value(\input,"AUDIO / INPUT",\input,\interface,174,
        [param.value(\channel,"CHANNEL",0,31,0,\step),param.value(\gain,"GAIN",0,8,1)],[],
        [port.value(\out,"MONO"),port.value(\stereo,"STEREO",\stereo)],"Audio interface input. Enable input channels in AUDIO SETUP before POWER. Channel numbers begin at zero.","Audio I/O / MEMS Mic / Stomp / Line In / Stereo I/O / XY I/O");
    add.value(\midi,"MIDI / CV",\midi,\interface,174,[param.value(\channel,"MIDI CH",0,16,0,\step)],[],
        [port.value(\pitch,"1V/OCT",\cv),port.value(\gate,"GATE",\gate),port.value(\velocity,"VELOCITY",\cv),port.value(\mod,"MOD WHEEL",\cv)],"Connect all MIDI sources using MIDI CONNECT. Monophonic last-note priority, velocity, pitch bend, sustain and CC1. Channel zero means omni.","MIDI 1U / uMIDI / CVx");
    add.value(\scope,"ZERO / SCOPE",\scope,\interface,208,
        [param.value(\gain,"DISPLAY GAIN",0.1,10,1,\exp)],
        [port.value(\in,"IN")],[port.value(\out,"THRU")],"Live oscilloscope, peak meter and estimated frequency. Click SCOPE in the toolbar to view the selected signal.","Zeroscope 1U");
    add.value(\spatial,"ORBIT / MULTICHANNEL",\spatial,\spatial,276,
        [param.value(\azimuth,"AZIMUTH",-180,180,0,\lin,"deg"),param.value(\rate,"ROTATION",-2,2,0.08,\lin,"Hz"),param.value(\spread,"WIDTH",1,8,2),param.value(\depth,"CV DEPTH",0,180,180,\lin,"deg")],
        [port.value(\in,"IN"),port.value(\cv,"AZIMUTH CV",\cv),port.value(\speed,"SPEED CV",\cv)],
        [port.value(\ring,"RING 32",\ring)],"Constant-power horizontal speaker-ring panner for 4, 8, 16, 24 or 32 active channels. Angle zero is front, positive is left. Toolbar selects ring size.");
    add.value(\ambisonic,"FIELD / AMBI ENCODE",\ambisonic,\spatial,242,
        [param.value(\elevation,"ELEVATION",-90,90,0,\lin,"deg"),param.value(\rotate,"ROTATE",-180,180,0,\lin,"deg")],
        [port.value(\ring,"RING IN",\ring),port.value(\mono,"MONO IN"),port.value(\az,"AZIMUTH CV",\cv)],
        [port.value(\ambi,"ACN / SN3D",\ambi)],"Encode speaker feeds into first-order AmbiX (ACN W,Y,Z,X; SN3D). Mono input can be positioned in 3D with azimuth CV and elevation. Ring encoding cannot reconstruct a unique original soundfield.");
    add.value(\ambidecode,"FIELD / AMBI DECODE",\ambidecode,\spatial,242,
        [param.value(\yaw,"HEAD YAW",-180,180,0,\lin,"deg")],
        [port.value(\ambi,"ACN / SN3D",\ambi)],
        [port.value(\ring,"RING OUT",\ring),port.value(\stereo,"STEREO",\stereo)],"Basic first-order horizontal ring decoder with yaw rotation. Z is not reproduced by horizontal rings; use the separate FOA output to preserve height.");
    add.value(\binaural,"EAR / BINAURAL",\binaural,\spatial,242,
        [param.value(\yaw,"HEAD YAW",-180,180,0,\lin,"deg"),param.value(\room,"ROOM",0,0.35,0.08)],
        [port.value(\ring,"RING IN",\ring)],
        [port.value(\stereo,"HEADPHONES",\stereo)],"Analytic headphone rendering with interaural time differences and frequency-dependent head shadow. Approximates spatial cues; not a measured or personalized HRTF.");
    add.value(\stereofold,"STEREO / DOWNMIX",\stereofold,\spatial,208,
        [param.value(\width,"WIDTH",0,1,1)], [port.value(\ring,"RING IN",\ring)],
        [port.value(\stereo,"STEREO",\stereo)],"Equal-power stereo fold-down from the active virtual speaker ring. Preserves left/right distribution, not a full surrounding soundfield.");
    add.value(\monitor,"OUTS / MONITOR",\monitor,\interface,242,[],
        [port.value(\mono,"MONO"),port.value(\stereo,"STEREO",\stereo),port.value(\ring,"RING",\ring),port.value(\ambi,"ACN / SN3D",\ambi)],[],
        "Final limiter, metering and hardware output. Toolbar selects stereo, headphone, physical speaker or raw AmbiX output. A single output module is allowed per rack.","Outs / Headphones / Stereo Line Out / Line Out");
    // These are named, functional variations of the digital families above, not firmware clones.
    [
        [\rubicon,"RUB / THRU-ZERO FM",\complex,"Rubicon II"],
        [\atlx,"ATLX / OSC EXPANDER",\vco,"Atlx / Atlx 1U"],
        [\vco1u,"VCO / 1U",\vco,"VCO 1U"],
        [\mems,"MEMS / MIC IN",\input,"MEMS Mic / MEMS Mic 1U"],
        [\rainmaker,"RAIN / MULTITAP",\delay,"Rainmaker"],
        [\digiverb,"DIGI / REVERB 1U",\reverb,"Digiverb 1U"],
        [\multifx,"MULTI / FX 1U",\delay,"Multi-FX 1U (delay mode)"],
        [\uvcf,"MICRO / VCF",\filter,"uVCF"],
        [\svf,"SVF / 1U",\filter,"SVF 1U"],
        [\amps,"AMPS / VCA",\vca,"Amps"],
        [\uvca,"MICRO / VCA",\vca,"uVCA"],
        [\dualvca,"DUAL / VCA 1U",\vca,"Dual VCA 1U"],
        [\mixup,"MIXUP / SUM",\mixer,"Mixup"],
        [\jellymix,"JELLY / MIX",\mixer,"Jellymix"],
        [\unity,"UNITY / MIX",\mixer,"Unity Mixer"],
        [\auxmix,"AUX / MIX 1U",\mixer,"Aux Mix 1U"],
        [\stereomixer,"STEREO / MIX 1U",\mixer,"Stereo Mixer 1U"],
        [\mutamix,"MUTA / XFADE",\crossfade,"Mutamix"],
        [\att,"ATT / 1U",\attenuverter,"Att 1U"],
        [\duatt,"DUATT / 1U",\attenuverter,"Duatt 1U"],
        [\quadratt,"QUADRATT / 1U",\attenuverter,"Quadratt 1U"],
        [\inverter,"QUAD / INVERTER",\attenuverter,"Quad Inverter"],
        [\passivemult,"MULT / PASSIVE",\mult,"Mult / Mult 1U"],
        [\switchedmult,"SWITCH / MULT",\mult,"Switched Mult 1U"],
        [\octalink,"OCTA / LINK",\mult,"Octalink 1U / USB Extender"],
        [\plog,"PLOG / LOGIC",\logic,"Plog"],
        [\steppy1u,"STEPP / 1U",\gates,"Steppy 1U"],
        [\gx,"GX / GATE EXPANDER",\gates,"Gx"],
        [\qx,"QX / END EXPANDER",\functions,"Qx"],
        [\tetrapad,"TETRA / TOUCH",\xy,"Tetrapad"],
        [\tete,"TETE / MOTION",\xy,"Tete"],
        [\fsr,"FSR / TOUCH 1U",\xy,"FSR 1U"],
        [\noisetools,"NOISE / TOOLS 1U",\noise,"Noise Tools 1U"],
        [\stomp,"STOMP / I-O",\input,"Stomp / Pedal I/O 1U"],
        [\stereoin,"STEREO / LINE IN",\input,"Stereo Line In 1U / Line In 1U / XY I/O 1U"],
        [\stereoio,"STEREO / I-O 1U",\input,"Stereo I/O 1U"],
        [\cvx,"CVX / MIDI 1U",\midi,"CVx 1U / uMIDI Jacks 1U / MIDI Jacks 1U"],
        [\cascadia,"CASC / SYNTH VOICE",\voice,"Cascadia"],
        [\metrosolo,"METRO / SOLO",\sequencer,"Metropolix Solo"]
    ].do { |row| alias.valueArray(row) };
    a[\categories] = [\all,\source,\control,\modulation,\filter,\mixing,\effect,\utility,\spatial,\interface];
}
