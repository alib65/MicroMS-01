(
var root=thisProcess.nowExecutingPath.dirname.dirname,a;
a=(root:root.standardizePath,modules:List.new,cables:List.new,catalog:IdentityDictionary.new,nextID:1,
    edo:19,rootHz:130.81278265,channels:8,hardware:2,mode:1,volume:0.35,running:false,playing:false,
    server:Server(\presetExport,NetAddr("127.0.0.1",59997)));
["Catalog","DSP","Engine","Presets"].do { |name| (root+/+"lib"+/+(name++".scd")).load.value(a) };
a[\preset].value(\orbit); a[\save].value(root+/+"presets/Orbital-19.microms");
a[\preset].value(\glass); a[\save].value(root+/+"presets/Glass-Garden-31.microms");
a[\close].value; 0.exit
)
