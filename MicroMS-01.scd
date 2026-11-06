/* MicroMS-01 · Ali Balighi © 2026 · Alibalighi.com
   Open this file in SuperCollider and evaluate the whole document (Cmd+A, Cmd+Return).
   No Quarks or external UGen plugins required. */
(
var root = thisProcess.nowExecutingPath.dirname.standardizePath;
if(~microMS.notNil) { ~microMS[\close].value };
~microMS = (
    root: root, version: "1.0.0", modules: List.new, cables: List.new,
    catalog: IdentityDictionary.new, nextID: 1, edo: 19, rootHz: 130.81278265,
    channels: 8, hardware: 2, mode: 1, volume: 0.35, running: false,
    playing: false, selected: nil, dirty: false, meters: [0, 0],
    server: Server(\microMS, NetAddr("127.0.0.1", 57131)), samplePaths: IdentityDictionary.new
);
["Catalog", "DSP", "Engine", "Presets", "Interface"].do { |name|
    (root +/+ "lib" +/+ (name ++ ".scd")).load.value(~microMS)
};
~microMS[\preset].value(\orbit);
~microMS[\gui].value;
"MicroMS-01 ready. Press POWER, then PLAY. Press HELP for patching instructions.".postln;
)
