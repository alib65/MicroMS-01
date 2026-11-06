(
var root=thisProcess.nowExecutingPath.dirname.dirname;
var a=(root:root,catalog:IdentityDictionary.new,defs:IdentityDictionary.new,hardware:2);
try {
    (root+/+"lib/Catalog.scd").load.value(a);
    (root+/+"lib/DSP.scd").load.value(a);
    a[\buildDefs].value;
    ("PASS: "++a[\defs].size++" SynthDefs built.").postln;
    a[\defs].values.do { |d| d.asBytes };
    "PASS: all SynthDefs serialize.".postln;
    0.exit
} { |err| err.reportError; 1.exit }
)
